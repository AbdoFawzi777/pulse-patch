/// Statistical analysis features extracted from valid samples of a session.
class SessionStatsRecord {
  const SessionStatsRecord({
    required this.sessionId,
    required this.meanHr,
    required this.stdHr,
    required this.minHr,
    required this.maxHr,
    required this.startHr,
    required this.endHr,
    this.recoveryDrop,
    this.pulseIntervalMs,
    this.variabilityEstMs,
    required this.validSampleCount,
    required this.totalDurationSeconds,
  });

  final String sessionId;
  final double meanHr;
  final double stdHr;
  final double minHr;
  final double maxHr;
  final double startHr;
  final double endHr;
  final double? recoveryDrop;
  final double? pulseIntervalMs;
  final double? variabilityEstMs;
  final int validSampleCount;
  final int totalDurationSeconds;

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'meanHr': meanHr,
    'stdHr': stdHr,
    'minHr': minHr,
    'maxHr': maxHr,
    'startHr': startHr,
    'endHr': endHr,
    'recoveryDrop': recoveryDrop,
    'pulseIntervalMs': pulseIntervalMs,
    'variabilityEstMs': variabilityEstMs,
    'validSampleCount': validSampleCount,
    'totalDurationSeconds': totalDurationSeconds,
  };

  factory SessionStatsRecord.fromJson(Map<String, dynamic> json) =>
      SessionStatsRecord(
        sessionId: json['sessionId'] as String,
        meanHr: (json['meanHr'] as num).toDouble(),
        stdHr: (json['stdHr'] as num).toDouble(),
        minHr: (json['minHr'] as num).toDouble(),
        maxHr: (json['maxHr'] as num).toDouble(),
        startHr: (json['startHr'] as num).toDouble(),
        endHr: (json['endHr'] as num).toDouble(),
        recoveryDrop: (json['recoveryDrop'] as num?)?.toDouble(),
        pulseIntervalMs: (json['pulseIntervalMs'] as num?)?.toDouble(),
        variabilityEstMs: (json['variabilityEstMs'] as num?)?.toDouble(),
        validSampleCount: json['validSampleCount'] as int,
        totalDurationSeconds: json['totalDurationSeconds'] as int,
      );
}
