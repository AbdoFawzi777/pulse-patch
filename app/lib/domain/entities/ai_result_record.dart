import 'dart:convert';

/// Model inference result stored per session.
class AiResultRecord {
  const AiResultRecord({
    required this.sessionId,
    required this.modelVersion,
    required this.label,
    required this.featuresJson,
    required this.createdAt,
  });

  final String sessionId;
  final String modelVersion;
  final String label; // "typical" or "different"
  final String featuresJson;
  final DateTime createdAt;

  String? get explanation {
    try {
      final map = jsonDecode(featuresJson) as Map<String, dynamic>;
      return map['explanation'] as String?;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'modelVersion': modelVersion,
    'label': label,
    'featuresJson': featuresJson,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AiResultRecord.fromJson(Map<String, dynamic> json) => AiResultRecord(
    sessionId: json['sessionId'] as String,
    modelVersion: json['modelVersion'] as String,
    label: json['label'] as String,
    featuresJson: json['featuresJson'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
