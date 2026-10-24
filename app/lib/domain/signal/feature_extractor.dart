import 'dart:math' as math;
import '../entities/pulse_sample.dart';
import '../entities/session_record.dart';
import '../entities/session_stats_record.dart';

class ExtractedFeatures {
  const ExtractedFeatures({
    required this.isAnalyzable,
    this.meanHr,
    this.stdHr,
    this.startHr,
    this.endHr,
    this.recoveryDrop,
    this.pulseIntervalMs,
    this.variabilityEstMs,
    required this.validSampleCount,
    required this.totalDurationSeconds,
  });

  final bool isAnalyzable;
  final double? meanHr;
  final double? stdHr;
  final double? startHr;
  final double? endHr;
  final double? recoveryDrop;
  final double? pulseIntervalMs;
  final double? variabilityEstMs;
  final int validSampleCount;
  final int totalDurationSeconds;

  SessionStatsRecord? toStatsRecord(String sessionId) {
    if (!isAnalyzable || meanHr == null || stdHr == null) {
      return null;
    }
    return SessionStatsRecord(
      sessionId: sessionId,
      meanHr: meanHr!,
      stdHr: stdHr!,
      minHr: meanHr!, // Fallback if min/max not tracked separately
      maxHr: meanHr!,
      startHr: startHr ?? meanHr!,
      endHr: endHr ?? meanHr!,
      recoveryDrop: recoveryDrop,
      pulseIntervalMs: pulseIntervalMs,
      variabilityEstMs: variabilityEstMs,
      validSampleCount: validSampleCount,
      totalDurationSeconds: totalDurationSeconds,
    );
  }
}

class BaselineComparison {
  const BaselineComparison({
    required this.hasBaseline,
    required this.baselineCount,
    this.baselineMeanHr,
    this.baselineStdHr,
    this.zScore,
    required this.summaryText,
  });

  final bool hasBaseline;
  final int baselineCount;
  final double? baselineMeanHr;
  final double? baselineStdHr;
  final double? zScore;
  final String summaryText;
}

class FeatureExtractor {
  static const int minValidSecondsForAnalysis = 30;
  static const int minRecoveryDurationSeconds = 70;
  static const int minBaselineSessions = 5;

  /// Extracts the 5 ML features and variability from raw pulse samples according to Section 6.
  static ExtractedFeatures extract({
    required List<PulseSample> samples,
    required SessionType type,
  }) {
    final validSamples = samples
        .where((s) => s.isValid && s.bpm != null)
        .toList();

    if (validSamples.isEmpty) {
      return const ExtractedFeatures(
        isAnalyzable: false,
        validSampleCount: 0,
        totalDurationSeconds: 0,
      );
    }

    final totalDuration = (samples.last.tMs - samples.first.tMs) ~/ 1000;

    if (validSamples.length < minValidSecondsForAnalysis) {
      return ExtractedFeatures(
        isAnalyzable: false,
        validSampleCount: validSamples.length,
        totalDurationSeconds: totalDuration,
      );
    }

    // 1. mean_hr
    final bpms = validSamples.map((s) => s.bpm!).toList();
    final meanHr = bpms.reduce((a, b) => a + b) / bpms.length;

    // 2. std_hr (sample standard deviation with N-1 degrees of freedom)
    final variance = bpms.length > 1
        ? bpms.map((x) => math.pow(x - meanHr, 2)).reduce((a, b) => a + b) /
              (bpms.length - 1)
        : 0.0;
    final stdHr = math.sqrt(variance);

    // 3. start_hr: median of valid BPM in first 10 seconds of valid data
    final firstTMs = validSamples.first.tMs;
    final startSamples = validSamples
        .where((s) => s.tMs <= firstTMs + 10000)
        .map((s) => s.bpm!)
        .toList();
    final startHr = _computeMedian(
      startSamples.isNotEmpty ? startSamples : [meanHr],
    );

    // 4. end_hr: median of valid BPM in last 10 seconds of valid data
    final lastTMs = validSamples.last.tMs;
    final endSamples = validSamples
        .where((s) => s.tMs >= lastTMs - 10000)
        .map((s) => s.bpm!)
        .toList();
    final endHr = _computeMedian(endSamples.isNotEmpty ? endSamples : [meanHr]);

    // 5. recovery_drop
    double? recoveryDrop;
    if (type == SessionType.postActivity) {
      // Must last at least 70 seconds
      if (totalDuration >= minRecoveryDurationSeconds) {
        // Window 55 to 65 seconds
        final windowSamples = validSamples
            .where(
              (s) => s.tMs >= firstTMs + 55000 && s.tMs <= firstTMs + 65000,
            )
            .map((s) => s.bpm!)
            .toList();

        if (windowSamples.length >= 3) {
          final window60Median = _computeMedian(windowSamples);
          recoveryDrop = startHr - window60Median;
        } else {
          recoveryDrop = null; // Insufficient data in recovery window
        }
      } else {
        recoveryDrop = null; // Session too short for recovery analysis
      }
    } else {
      // Rest session recovery drop is start_hr - end_hr
      recoveryDrop = startHr - endHr;
    }

    // 6. Pulse interval and variability estimate (SDSD of intervals)
    final intervals = bpms.map((b) => 60000.0 / b).toList();
    final pulseIntervalMs =
        intervals.reduce((a, b) => a + b) / intervals.length;

    double? variabilityEstMs;
    if (intervals.length > 2) {
      final diffs = <double>[];
      for (int i = 0; i < intervals.length - 1; i++) {
        diffs.add(intervals[i + 1] - intervals[i]);
      }
      final meanDiff = diffs.reduce((a, b) => a + b) / diffs.length;
      final diffVar =
          diffs.map((d) => math.pow(d - meanDiff, 2)).reduce((a, b) => a + b) /
          (diffs.length - 1);
      variabilityEstMs = math.sqrt(diffVar);
    }

    return ExtractedFeatures(
      isAnalyzable: true,
      meanHr: meanHr,
      stdHr: stdHr,
      startHr: startHr,
      endHr: endHr,
      recoveryDrop: recoveryDrop,
      pulseIntervalMs: pulseIntervalMs,
      variabilityEstMs: variabilityEstMs,
      validSampleCount: validSamples.length,
      totalDurationSeconds: totalDuration,
    );
  }

  /// Evaluates statistical z-score of a session against the user's prior baseline recordings.
  /// Strict requirement: at least 5 comparable sessions needed.
  static BaselineComparison compareBaseline({
    required double currentMeanHr,
    required List<SessionStatsRecord> priorStats,
  }) {
    if (priorStats.length < minBaselineSessions) {
      return BaselineComparison(
        hasBaseline: false,
        baselineCount: priorStats.length,
        summaryText:
            'Requires at least 5 baseline recordings (${priorStats.length}/$minBaselineSessions recorded).',
      );
    }

    final hrs = priorStats.map((s) => s.meanHr).toList();
    final baselineMean = hrs.reduce((a, b) => a + b) / hrs.length;

    final variance =
        hrs.map((x) => math.pow(x - baselineMean, 2)).reduce((a, b) => a + b) /
        (hrs.length - 1);
    final baselineStd = math.sqrt(variance);

    if (baselineStd == 0.0) {
      return BaselineComparison(
        hasBaseline: true,
        baselineCount: priorStats.length,
        baselineMeanHr: baselineMean,
        baselineStdHr: 0.0,
        zScore: 0.0,
        summaryText: 'Matches personal baseline exactly.',
      );
    }

    final z = (currentMeanHr - baselineMean) / baselineStd;
    final zAbs = z.abs();

    final String interpretation;
    if (zAbs <= 1.0) {
      interpretation = 'Typical for your personal baseline (within 1 SD).';
    } else if (zAbs <= 2.0) {
      interpretation =
          'Mild statistical deviation (${z > 0 ? "+" : ""}${z.toStringAsFixed(1)} SD from baseline).';
    } else {
      interpretation =
          'Noticeable statistical deviation (${z > 0 ? "+" : ""}${z.toStringAsFixed(1)} SD from baseline).';
    }

    return BaselineComparison(
      hasBaseline: true,
      baselineCount: priorStats.length,
      baselineMeanHr: baselineMean,
      baselineStdHr: baselineStd,
      zScore: z,
      summaryText: interpretation,
    );
  }

  static double _computeMedian(List<double> values) {
    if (values.isEmpty) return 0.0;
    final sorted = List<double>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length % 2 == 1) {
      return sorted[mid];
    } else {
      return (sorted[mid - 1] + sorted[mid]) / 2.0;
    }
  }
}
