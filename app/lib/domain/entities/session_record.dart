enum SessionType {
  rest,
  postActivity;

  static SessionType fromString(String val) {
    if (val == 'postActivity') return SessionType.postActivity;
    return SessionType.rest;
  }
}

enum QualitySummary {
  good,
  fair,
  weak;

  static QualitySummary fromString(String val) {
    switch (val) {
      case 'good':
        return QualitySummary.good;
      case 'fair':
        return QualitySummary.fair;
      case 'weak':
      default:
        return QualitySummary.weak;
    }
  }
}

enum SessionSource {
  device,
  simulator;

  static SessionSource fromString(String val) {
    if (val == 'simulator') return SessionSource.simulator;
    return SessionSource.device;
  }
}

/// Core domain entity for a recorded heart rate session.
class SessionRecord {
  const SessionRecord({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.type,
    required this.qualitySummary,
    required this.appVersion,
    required this.source,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final SessionType type;
  final QualitySummary qualitySummary;
  final String appVersion;
  final SessionSource source;

  int get durationSeconds {
    if (endedAt == null) return 0;
    return endedAt!.difference(startedAt).inSeconds;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'type': type.name,
    'qualitySummary': qualitySummary.name,
    'appVersion': appVersion,
    'source': source.name,
  };

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
    id: json['id'] as String,
    startedAt: DateTime.parse(json['startedAt'] as String),
    endedAt: json['endedAt'] != null
        ? DateTime.parse(json['endedAt'] as String)
        : null,
    type: SessionType.fromString(json['type'] as String),
    qualitySummary: QualitySummary.fromString(json['qualitySummary'] as String),
    appVersion: json['appVersion'] as String,
    source: SessionSource.fromString(json['source'] as String),
  );
}
