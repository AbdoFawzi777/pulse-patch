/// Centralized AI Configuration and Governance for PulsePatch Next Generation
class AiConfig {
  const AiConfig._();

  /// Primary Cloud AI Model identifier.
  /// Replaces retired Gemini 1.5 models.
  /// Configurable at compile-time via `--dart-define=GEMINI_MODEL=...`
  static const String defaultModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.8-flash',
  );

  /// Secondary lightweight fallback model when primary is throttled
  static const String fallbackModel = String.fromEnvironment(
    'GEMINI_FALLBACK_MODEL',
    defaultValue: 'gemini-3.5-flash-lite',
  );

  /// API Key from environment or build flags
  static const String apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Base API Endpoint
  static const String apiBaseUrl = String.fromEnvironment(
    'GEMINI_API_ENDPOINT',
    defaultValue: 'https://generativelanguage.googleapis.com/v1beta',
  );

  /// Dynamic Model Display Name
  static String get displayName {
    if (defaultModel.contains('3.8')) return 'Gemini 3.8 Flash (Cloud)';
    if (defaultModel.contains('3.5')) return 'Gemini 3.5 Flash Lite (Cloud)';
    return 'Google Gemini Cloud ($defaultModel)';
  }

  /// Request timeout threshold
  static const Duration requestTimeout = Duration(seconds: 10);

  /// Rate limiting: maximum requests allowed per minute on client
  static const int maxRequestsPerMinute = 15;

  /// Default token generation limit
  static const int maxOutputTokens = 800;

  /// Temperature setting for deterministic evidence-based clinical guidance
  static const double temperature = 0.2;
}
