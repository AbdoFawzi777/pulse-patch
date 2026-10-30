import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/drift/app_database.dart';
import '../../data/repositories/session_repository.dart';
import '../entities/session_record.dart';
import '../entities/session_stats_record.dart';

enum MetricTrendDirection {
  rising,
  stable,
  falling,
  insufficientData,
}

class MetricSummary {
  const MetricSummary({
    required this.currentAverage,
    required this.baselineAverage,
    required this.sevenDayAverage,
    required this.thirtyDayAverage,
    required this.measurementCount,
    required this.trend,
    required this.unit,
    required this.isReliable,
    required this.insufficientDataReason,
  });

  final double? currentAverage;
  final double? baselineAverage;
  final double? sevenDayAverage;
  final double? thirtyDayAverage;
  final int measurementCount;
  final MetricTrendDirection trend;
  final String unit;
  final bool isReliable;
  final String? insufficientDataReason;
}

class DailyTrendPoint {
  const DailyTrendPoint({
    required this.date,
    required this.label,
    required this.value,
    this.secondaryValue,
    required this.count,
  });

  final DateTime date;
  final String label;
  final double? value;
  final double? secondaryValue;
  final int count;
}

class BloodPressureAnalytics {
  const BloodPressureAnalytics({
    required this.cuffCount,
    required this.latestCuffSbp,
    required this.latestCuffDbp,
    required this.sevenDayCuffSbp,
    required this.sevenDayCuffDbp,
    required this.thirtyDayCuffSbp,
    required this.thirtyDayCuffDbp,
    required this.cuffTrend,
    required this.experimentalEstimateCount,
    required this.latestEstimateSbp,
    required this.latestEstimateDbp,
    required this.sevenDayEstimateSbp,
    required this.sevenDayEstimateDbp,
    required this.hasCuffData,
    required this.hasEstimateData,
  });

  final int cuffCount;
  final double? latestCuffSbp;
  final double? latestCuffDbp;
  final double? sevenDayCuffSbp;
  final double? sevenDayCuffDbp;
  final double? thirtyDayCuffSbp;
  final double? thirtyDayCuffDbp;
  final MetricTrendDirection cuffTrend;

  // Experimental model estimates are strictly segregated
  final int experimentalEstimateCount;
  final double? latestEstimateSbp;
  final double? latestEstimateDbp;
  final double? sevenDayEstimateSbp;
  final double? sevenDayEstimateDbp;

  final bool hasCuffData;
  final bool hasEstimateData;
}

class LongitudinalHealthReport {
  const LongitudinalHealthReport({
    required this.heartRateSummary,
    required this.spo2Summary,
    required this.bpAnalytics,
    required this.heartRateDailyPoints,
    required this.spo2DailyPoints,
    required this.totalSessionsRecorded,
  });

  final MetricSummary heartRateSummary;
  final MetricSummary spo2Summary;
  final BloodPressureAnalytics bpAnalytics;
  final List<DailyTrendPoint> heartRateDailyPoints;
  final List<DailyTrendPoint> spo2DailyPoints;
  final int totalSessionsRecorded;
}

final healthAnalyticsServiceProvider = Provider<HealthAnalyticsService>((ref) {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final db = ref.watch(appDatabaseProvider);
  return HealthAnalyticsService(sessionRepo: sessionRepo, db: db);
});

class HealthAnalyticsService {
  HealthAnalyticsService({required this.sessionRepo, required this.db});

  final SessionRepository sessionRepo;
  final AppDatabase db;

  static const int minMeasurementsForBaseline = 3;

  LongitudinalHealthReport computeReport({DateTime? referenceTime}) {
    final now = referenceTime ?? DateTime.now();
    final allSessions = sessionRepo.getAllSessions();

    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // 1. Gather all session stats
    final List<({SessionRecord session, SessionStatsRecord stats})> validSessionStats = [];
    for (final s in allSessions) {
      final st = sessionRepo.getStatsForSession(s.id);
      if (st != null && st.validSampleCount > 10) {
        validSessionStats.add((session: s, stats: st));
      }
    }

    // --- HEART RATE ANALYTICS ---
    final allHrs = validSessionStats.map((item) => item.stats.meanHr).toList();
    final sevenDayHrs = validSessionStats
        .where((item) => item.session.startedAt.isAfter(sevenDaysAgo))
        .map((item) => item.stats.meanHr)
        .toList();
    final thirtyDayHrs = validSessionStats
        .where((item) => item.session.startedAt.isAfter(thirtyDaysAgo))
        .map((item) => item.stats.meanHr)
        .toList();

    final hrSummary = _buildMetricSummary(
      allValues: allHrs,
      sevenDayValues: sevenDayHrs,
      thirtyDayValues: thirtyDayHrs,
      unit: 'BPM',
      metricName: 'Heart Rate',
    );

    // --- SPO2 ANALYTICS ---
    final allSpo2 = validSessionStats
        .map((item) => item.stats.avgSpo2)
        .whereType<double>()
        .where((v) => v >= 70.0 && v <= 100.0)
        .toList();
    final sevenDaySpo2 = validSessionStats
        .where((item) => item.session.startedAt.isAfter(sevenDaysAgo))
        .map((item) => item.stats.avgSpo2)
        .whereType<double>()
        .where((v) => v >= 70.0 && v <= 100.0)
        .toList();
    final thirtyDaySpo2 = validSessionStats
        .where((item) => item.session.startedAt.isAfter(thirtyDaysAgo))
        .map((item) => item.stats.avgSpo2)
        .whereType<double>()
        .where((v) => v >= 70.0 && v <= 100.0)
        .toList();

    final spo2Summary = _buildMetricSummary(
      allValues: allSpo2,
      sevenDayValues: sevenDaySpo2,
      thirtyDayValues: thirtyDaySpo2,
      unit: '%',
      metricName: 'Blood Oxygen',
    );

    // --- BLOOD PRESSURE ANALYTICS (CUFF & ESTIMATES) ---
    final bpAnalytics = _computeBpAnalytics(now: now);

    // --- 7-DAY DAILY TREND POINTS ---
    final hrDailyPoints = _computeDailyPoints(
      now: now,
      days: 7,
      getValue: (st) => st.meanHr,
      validSessionStats: validSessionStats,
    );

    final spo2DailyPoints = _computeDailyPoints(
      now: now,
      days: 7,
      getValue: (st) => st.avgSpo2,
      validSessionStats: validSessionStats,
    );

    return LongitudinalHealthReport(
      heartRateSummary: hrSummary,
      spo2Summary: spo2Summary,
      bpAnalytics: bpAnalytics,
      heartRateDailyPoints: hrDailyPoints,
      spo2DailyPoints: spo2DailyPoints,
      totalSessionsRecorded: validSessionStats.length,
    );
  }

  MetricSummary _buildMetricSummary({
    required List<double> allValues,
    required List<double> sevenDayValues,
    required List<double> thirtyDayValues,
    required String unit,
    required String metricName,
  }) {
    if (allValues.isEmpty) {
      return MetricSummary(
        currentAverage: null,
        baselineAverage: null,
        sevenDayAverage: null,
        thirtyDayAverage: null,
        measurementCount: 0,
        trend: MetricTrendDirection.insufficientData,
        unit: unit,
        isReliable: false,
        insufficientDataReason: 'No recorded $metricName data available.',
      );
    }

    final isReliable = allValues.length >= minMeasurementsForBaseline;
    final allMean = _mean(allValues);
    final sevenDayMean = sevenDayValues.isNotEmpty ? _mean(sevenDayValues) : null;
    final thirtyDayMean = thirtyDayValues.isNotEmpty ? _mean(thirtyDayValues) : null;

    MetricTrendDirection trend = MetricTrendDirection.stable;
    if (sevenDayMean != null && thirtyDayMean != null) {
      final diff = sevenDayMean - thirtyDayMean;
      final threshold = unit == '%' ? 1.0 : 3.0; // 1% for SpO2, 3 BPM for HR
      if (diff > threshold) {
        trend = MetricTrendDirection.rising;
      } else if (diff < -threshold) {
        trend = MetricTrendDirection.falling;
      } else {
        trend = MetricTrendDirection.stable;
      }
    } else {
      trend = MetricTrendDirection.insufficientData;
    }

    return MetricSummary(
      currentAverage: allValues.last,
      baselineAverage: isReliable ? allMean : null,
      sevenDayAverage: sevenDayMean,
      thirtyDayAverage: thirtyDayMean,
      measurementCount: allValues.length,
      trend: trend,
      unit: unit,
      isReliable: isReliable,
      insufficientDataReason: isReliable
          ? null
          : 'Requires at least $minMeasurementsForBaseline measurements for a reliable baseline (${allValues.length}/$minMeasurementsForBaseline recorded).',
    );
  }

  BloodPressureAnalytics _computeBpAnalytics({required DateTime now}) {
    final sevenDaysAgo = now.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    final thirtyDaysAgo = now.subtract(const Duration(days: 30)).millisecondsSinceEpoch;

    // 1. Cuff Reference Calibrations
    final cuffRows = db.rawDb.select(
      'SELECT cuff_sbp, cuff_dbp, calibrated_at FROM bp_calibrations ORDER BY calibrated_at DESC;',
    );

    final allCuffSbp = cuffRows.map((r) => (r['cuff_sbp'] as num).toDouble()).toList();
    final allCuffDbp = cuffRows.map((r) => (r['cuff_dbp'] as num).toDouble()).toList();

    final sevenDayCuff = cuffRows.where((r) => (r['calibrated_at'] as int) >= sevenDaysAgo).toList();
    final thirtyDayCuff = cuffRows.where((r) => (r['calibrated_at'] as int) >= thirtyDaysAgo).toList();

    final sevenDayCuffSbp = sevenDayCuff.isNotEmpty ? _mean(sevenDayCuff.map((r) => (r['cuff_sbp'] as num).toDouble()).toList()) : null;
    final sevenDayCuffDbp = sevenDayCuff.isNotEmpty ? _mean(sevenDayCuff.map((r) => (r['cuff_dbp'] as num).toDouble()).toList()) : null;

    final thirtyDayCuffSbp = thirtyDayCuff.isNotEmpty ? _mean(thirtyDayCuff.map((r) => (r['cuff_sbp'] as num).toDouble()).toList()) : null;
    final thirtyDayCuffDbp = thirtyDayCuff.isNotEmpty ? _mean(thirtyDayCuff.map((r) => (r['cuff_dbp'] as num).toDouble()).toList()) : null;

    MetricTrendDirection cuffTrend = MetricTrendDirection.stable;
    if (sevenDayCuffSbp != null && thirtyDayCuffSbp != null) {
      final diff = sevenDayCuffSbp - thirtyDayCuffSbp;
      if (diff > 5.0) {
        cuffTrend = MetricTrendDirection.rising;
      } else if (diff < -5.0) {
        cuffTrend = MetricTrendDirection.falling;
      }
    } else {
      cuffTrend = MetricTrendDirection.insufficientData;
    }

    // 2. Experimental Model Estimates (STRICTLY SEGREGATED)
    final estRows = db.rawDb.select(
      'SELECT sbp, dbp, created_at FROM bp_estimates ORDER BY created_at DESC;',
    );

    final allEstSbp = estRows.map((r) => (r['sbp'] as num).toDouble()).toList();
    final allEstDbp = estRows.map((r) => (r['dbp'] as num).toDouble()).toList();

    final sevenDayEst = estRows.where((r) => (r['created_at'] as int) >= sevenDaysAgo).toList();
    final sevenDayEstSbp = sevenDayEst.isNotEmpty ? _mean(sevenDayEst.map((r) => (r['sbp'] as num).toDouble()).toList()) : null;
    final sevenDayEstDbp = sevenDayEst.isNotEmpty ? _mean(sevenDayEst.map((r) => (r['dbp'] as num).toDouble()).toList()) : null;

    return BloodPressureAnalytics(
      cuffCount: cuffRows.length,
      latestCuffSbp: allCuffSbp.isNotEmpty ? allCuffSbp.first : null,
      latestCuffDbp: allCuffDbp.isNotEmpty ? allCuffDbp.first : null,
      sevenDayCuffSbp: sevenDayCuffSbp,
      sevenDayCuffDbp: sevenDayCuffDbp,
      thirtyDayCuffSbp: thirtyDayCuffSbp,
      thirtyDayCuffDbp: thirtyDayCuffDbp,
      cuffTrend: cuffTrend,
      experimentalEstimateCount: estRows.length,
      latestEstimateSbp: allEstSbp.isNotEmpty ? allEstSbp.first : null,
      latestEstimateDbp: allEstDbp.isNotEmpty ? allEstDbp.first : null,
      sevenDayEstimateSbp: sevenDayEstSbp,
      sevenDayEstimateDbp: sevenDayEstDbp,
      hasCuffData: cuffRows.isNotEmpty,
      hasEstimateData: estRows.isNotEmpty,
    );
  }

  List<DailyTrendPoint> _computeDailyPoints({
    required DateTime now,
    required int days,
    required double? Function(SessionStatsRecord st) getValue,
    required List<({SessionRecord session, SessionStatsRecord stats})> validSessionStats,
  }) {
    final points = <DailyTrendPoint>[];
    for (int i = days - 1; i >= 0; i--) {
      final targetDate = now.subtract(Duration(days: i));
      final dayMatches = validSessionStats.where((item) {
        final d = item.session.startedAt;
        return d.year == targetDate.year &&
            d.month == targetDate.month &&
            d.day == targetDate.day;
      }).toList();

      final vals = dayMatches
          .map((item) => getValue(item.stats))
          .whereType<double>()
          .toList();

      final label = _weekdayShort(targetDate.weekday);
      if (vals.isNotEmpty) {
        points.add(DailyTrendPoint(
          date: targetDate,
          label: label,
          value: _mean(vals),
          count: vals.length,
        ));
      } else {
        points.add(DailyTrendPoint(
          date: targetDate,
          label: label,
          value: null,
          count: 0,
        ));
      }
    }
    return points;
  }

  static double _mean(List<double> numbers) {
    if (numbers.isEmpty) return 0.0;
    return numbers.reduce((a, b) => a + b) / numbers.length;
  }

  static String _weekdayShort(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }
}
