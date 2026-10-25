/// Telemetry sample recorded from the sensor or simulator.
class PulseSample {
  const PulseSample({
    this.id,
    required this.sessionId,
    required this.tMs,
    this.bpm,
    required this.quality,
    required this.isValid,
    this.spo2,
  });

  final int? id;
  final String sessionId;
  final int tMs;
  final double? bpm;
  final int quality;
  final bool isValid;
  final double? spo2;

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'tMs': tMs,
    'bpm': bpm,
    'quality': quality,
    'isValid': isValid,
    'spo2': spo2,
  };

  factory PulseSample.fromJson(Map<String, dynamic> json) => PulseSample(
    id: json['id'] as int?,
    sessionId: json['sessionId'] as String,
    tMs: json['tMs'] as int,
    bpm: (json['bpm'] as num?)?.toDouble(),
    quality: json['quality'] as int,
    isValid: json['isValid'] as bool,
    spo2: (json['spo2'] as num?)?.toDouble(),
  );
}
