import '../knowledge/medical_knowledge_models.dart';

/// Single message in a multi-turn conversation
class AiChatMessage {
  const AiChatMessage({
    required this.role, // 'user' or 'model'
    required this.text,
  });

  final String role;
  final String text;

  Map<String, dynamic> toJson() => {
    'role': role,
    'parts': [{'text': text}],
  };
}

/// Clinical request prompt containing the user query, multi-turn history, and consent-gated vitals
class AiPromptRequest {
  const AiPromptRequest({
    required this.query,
    this.language = 'en',
    this.recentHr,
    this.recentSpo2,
    this.estimatedSbp,
    this.estimatedDbp,
    this.userAge,
    this.userGender,
    this.historySnippet,
    this.conversationHistory = const [],
    this.hasUserConsent = false,
  });

  final String query;
  final String language; // 'en' or 'ar'
  final double? recentHr;
  final double? recentSpo2;
  final double? estimatedSbp;
  final double? estimatedDbp;
  final int? userAge;
  final String? userGender;
  final String? historySnippet;
  final List<AiChatMessage> conversationHistory;
  final bool hasUserConsent;

  /// Sanitized context map enforcing explicit consent before cloud transmission
  Map<String, dynamic> toContextMap({bool isExternalCloud = false}) {
    // If sent to external cloud and user has not consented, transmit strictly the query text
    if (isExternalCloud && !hasUserConsent) {
      return {
        'query': query,
        'language': language,
        'privacy_notice': 'Health telemetry omitted (consent not granted)',
        'telemetry_sharing_status': 'withheld_by_user_privacy_policy',
      };
    }

    return {
      'query': query,
      'language': language,
      'telemetry_sharing_status': 'consented_by_user',
      if (recentHr != null) 'recent_hr': recentHr,
      if (recentSpo2 != null) 'recent_spo2': recentSpo2,
      if (estimatedSbp != null) 'estimated_sbp': estimatedSbp,
      if (estimatedDbp != null) 'estimated_dbp': estimatedDbp,
      if (userAge != null) 'user_age': userAge,
      if (userGender != null) 'user_gender': userGender,
    };
  }
}

/// Structured AI response with medical safety flags and authoritative citations
class AiResponse {
  const AiResponse({
    required this.text,
    required this.providerName,
    required this.isCloud,
    this.citations = const [],
    this.isEmergency = false,
    this.emergencyAdvice,
    this.latencyMs = 0,
    this.disclaimer = 'PulsePatch provides educational biomonitoring insights only and is not a substitute for clinical medical diagnosis.',
  });

  final String text;
  final String providerName; // e.g. "Gemini 3.8 Flash (Cloud)", "Local Evidence RAG (Offline)"
  final bool isCloud;
  final List<MedicalCitation> citations;
  final bool isEmergency;
  final String? emergencyAdvice;
  final int latencyMs;
  final String disclaimer;
}

/// Abstract provider interface enabling vendor-agnostic AI integration
abstract class AiProvider {
  String get name;
  bool get isCloud;
  Future<bool> isAvailable();

  Future<AiResponse> generateResponse(AiPromptRequest request);
  Stream<String> generateStream(AiPromptRequest request);
}
