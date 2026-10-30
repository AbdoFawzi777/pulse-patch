import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/drift/app_database.dart';
import 'package:app/data/repositories/session_repository.dart';
import 'package:app/domain/analytics/health_analytics_service.dart';
import 'package:app/domain/entities/pulse_sample.dart';
import 'package:app/domain/entities/session_record.dart';
import 'package:app/domain/entities/session_stats_record.dart';

void main() {
  late AppDatabase db;
  late SessionRepository sessionRepo;
  late HealthAnalyticsService analyticsService;

  setUp(() {
    db = AppDatabase.inMemory();
    sessionRepo = SessionRepository(db);
    analyticsService = HealthAnalyticsService(sessionRepo: sessionRepo, db: db);
  });

  tearDown(() {
    db.close();
  });

  group('HealthAnalyticsService Tests', () {
    test('Empty history returns insufficient data gracefully', () {
      final report = analyticsService.computeReport();

      expect(report.totalSessionsRecorded, equals(0));
      expect(report.heartRateSummary.measurementCount, equals(0));
      expect(report.heartRateSummary.isReliable, isFalse);
      expect(report.heartRateSummary.trend, equals(MetricTrendDirection.insufficientData));
      expect(report.spo2Summary.measurementCount, equals(0));
      expect(report.bpAnalytics.hasCuffData, isFalse);
      expect(report.bpAnalytics.hasEstimateData, isFalse);
    });

    test('Computes 7-day and 30-day averages and reliable baseline when sufficient data exists', () async {
      final now = DateTime(2026, 10, 30, 12, 0);

      // Add 4 sessions over the past 10 days
      for (int i = 0; i < 4; i++) {
        final sessId = 'test-sess-$i';
        final startedAt = now.subtract(Duration(days: i * 2));
        final session = SessionRecord(
          id: sessId,
          startedAt: startedAt,
          endedAt: startedAt.add(const Duration(minutes: 2)),
          type: SessionType.rest,
          qualitySummary: QualitySummary.good,
          appVersion: '2.0.0',
          source: SessionSource.pulsepatch,
        );

        final stats = SessionStatsRecord(
          sessionId: sessId,
          meanHr: 70.0 + (i * 2.0), // 70, 72, 74, 76 -> mean 73.0
          stdHr: 2.5,
          minHr: 65.0,
          maxHr: 80.0,
          startHr: 72.0,
          endHr: 68.0,
          validSampleCount: 120,
          totalDurationSeconds: 120,
          avgSpo2: 98.0,
        );

        final sample = PulseSample(
          sessionId: sessId,
          tMs: 0,
          bpm: 72.0,
          quality: 95,
          isValid: true,
          spo2: 98.0,
        );

        await sessionRepo.insertSession(
          session: session,
          samples: [sample],
          stats: stats,
        );
      }

      final report = analyticsService.computeReport(referenceTime: now);

      expect(report.totalSessionsRecorded, equals(4));
      expect(report.heartRateSummary.measurementCount, equals(4));
      expect(report.heartRateSummary.isReliable, isTrue); // >= 3 measurements
      expect(report.heartRateSummary.baselineAverage, closeTo(73.0, 0.1));
      expect(report.spo2Summary.baselineAverage, closeTo(98.0, 0.1));
    });

    test('Strictly segregates cuff reference readings from experimental model estimates', () {
      final now = DateTime(2026, 10, 30, 12, 0);

      // Insert user profile
      db.rawDb.execute(
        '''
        INSERT INTO user_profiles (id, full_name, age, gender, height_cm, weight_kg, created_at, updated_at)
        VALUES ('user-1', 'Test User', 40, 'male', 175.0, 75.0, 1000, 1000);
        ''',
      );

      // Insert a real cuff calibration reading
      db.rawDb.execute(
        '''
        INSERT INTO bp_calibrations (id, user_id, cuff_sbp, cuff_dbp, estimated_sbp, estimated_dbp, offset_sbp, offset_dbp, calibrated_at)
        VALUES ('calib-1', 'user-1', 125.0, 82.0, 120.0, 80.0, 5.0, 2.0, ${now.millisecondsSinceEpoch});
        ''',
      );

      // Insert an experimental AI estimate
      db.rawDb.execute(
        '''
        INSERT INTO sessions (id, started_at, type, quality_summary, app_version, source)
        VALUES ('sess-ai-1', ${now.millisecondsSinceEpoch}, 'rest', 'good', '2.0.0', 'simulator');
        ''',
      );
      db.rawDb.execute(
        '''
        INSERT INTO bp_estimates (id, session_id, sbp, dbp, map, category, category_ar, is_calibrated, confidence_score, created_at)
        VALUES ('est-1', 'sess-ai-1', 118.0, 78.0, 91.3, 'Optimal', 'مثالي', 1, 0.92, ${now.millisecondsSinceEpoch});
        ''',
      );

      final report = analyticsService.computeReport(referenceTime: now);

      expect(report.bpAnalytics.hasCuffData, isTrue);
      expect(report.bpAnalytics.cuffCount, equals(1));
      expect(report.bpAnalytics.latestCuffSbp, equals(125.0));
      expect(report.bpAnalytics.latestCuffDbp, equals(82.0));

      expect(report.bpAnalytics.hasEstimateData, isTrue);
      expect(report.bpAnalytics.experimentalEstimateCount, equals(1));
      expect(report.bpAnalytics.latestEstimateSbp, equals(118.0));
      expect(report.bpAnalytics.latestEstimateDbp, equals(78.0));
    });
  });
}
