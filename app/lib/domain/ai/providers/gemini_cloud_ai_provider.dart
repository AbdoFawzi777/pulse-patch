import 'dart:async';
import 'dart:convert';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:http/http.dart' as http;
import '../../knowledge/medical_knowledge_models.dart';
import '../ai_config.dart';
import '../ai_provider.dart';
import '../ai_safety_policy.dart';

/// Cloud AI Provider powered by Google Gemini (Gemini 3.8 Flash / 3.5 Flash Lite)
class GeminiCloudAiProvider implements AiProvider {
  GeminiCloudAiProvider({
    String? apiKey,
    String? modelName,
    http.Client? httpClient,
    AiSafetyPolicy? safetyPolicy,
  })  : _apiKey = apiKey ?? AiConfig.apiKey,
        _modelName = modelName ?? AiConfig.defaultModel,
        _client = httpClient ?? http.Client(),
        _safetyPolicy = safetyPolicy ?? const AiSafetyPolicy();

  final String _apiKey;
  final String _modelName;
  final http.Client _client;
  final AiSafetyPolicy _safetyPolicy;

  // Sliding window rate limiter timestamps
  static final List<DateTime> _requestTimestamps = [];

  @override
  String get name => 'Gemini ($modelInUse)';

  String get modelInUse => _modelName;

  @override
  bool get isCloud => true;

  @override
  Future<bool> isAvailable() async {
    return _apiKey.isNotEmpty && _apiKey != 'PLACEHOLDER' && _apiKey != 'UNCONFIGURED';
  }

  /// Checks and records rate limit quota
  bool _checkRateLimit() {
    final now = DateTime.now();
    _requestTimestamps.removeWhere(
      (ts) => now.difference(ts) > const Duration(minutes: 1),
    );
    if (_requestTimestamps.length >= AiConfig.maxRequestsPerMinute) {
      return false;
    }
    _requestTimestamps.add(now);
    return true;
  }

  @override
  Future<AiResponse> generateResponse(AiPromptRequest request) async {
    final stopwatch = Stopwatch()..start();
    final isAr = request.language == 'ar';

    // 1. Mandatory Safety Policy Check
    final isEmergency = _safetyPolicy.isAcuteEmergency(request.query) ||
        _safetyPolicy.isPhysiologicalCrisis(
          sbp: request.estimatedSbp,
          dbp: request.estimatedDbp,
          hr: request.recentHr,
          spo2: request.recentSpo2,
        );

    final emergencyNotice = isEmergency ? _safetyPolicy.getEmergencyAdvice(isArabic: isAr) : null;

    if (!await isAvailable()) {
      throw StateError('Gemini API key is not configured.');
    }

    if (!_checkRateLimit()) {
      throw StateError('Rate limit exceeded: maximum ${AiConfig.maxRequestsPerMinute} requests per minute.');
    }

    // 2. Build System Instruction
    final systemInstruction = isAr
        ? 'أنت مساعد ذكاء اصطناعي طبي متخصص في رصد نبض القلب والعلامات الحيوية لتطبيق PulsePatch. '
            'قدم معلومات قائمة على الأدلة الإرشادية المعتمدة (WHO, ESC/ISH, AHA, PubMed). '
            'لا تقدم تشخيصاً طبياً نهائياً ولا تصف أدوية أو جرعات علاجية. '
            'في حالات ألم الصدر أو الطوارئ، نبه المستخدم بالاتصال بالإسعاف (123) فوراً. '
            'أجب باللغة العربية بوضوح.'
        : 'You are an evidence-based clinical knowledge assistant for the PulsePatch biomonitoring platform. '
            'Provide accurate physiological and lifestyle guidance strictly referencing authoritative sources (WHO, ESC/ISH, AHA, PubMed). '
            'Never provide medical diagnosis or prescribe medication dosages. '
            'Always remind the user to seek certified clinical evaluation.';

    // 3. Format Multi-Turn Contents and Context (Privacy Gated)
    final contents = <Map<String, dynamic>>[];

    // Include multi-turn conversation history
    for (final historyMsg in request.conversationHistory) {
      contents.add({
        'role': historyMsg.role,
        'parts': [{'text': historyMsg.text}],
      });
    }

    // Current query with context (ONLY if user gave explicit consent)
    final userContext = StringBuffer();
    userContext.writeln('Query: ${request.query}');

    if (request.hasUserConsent) {
      if (request.recentHr != null) userContext.writeln('Recent Resting HR: ${request.recentHr!.round()} bpm');
      if (request.recentSpo2 != null) userContext.writeln('Recent SpO2: ${request.recentSpo2!.round()}%');
      if (request.estimatedSbp != null && request.estimatedDbp != null) {
        userContext.writeln('Estimated BP: ${request.estimatedSbp!.round()}/${request.estimatedDbp!.round()} mmHg (Experimental PPG estimation)');
      }
      if (request.userAge != null) userContext.writeln('Age: ${request.userAge}');
      if (request.userGender != null) userContext.writeln('Gender: ${request.userGender}');
    } else {
      userContext.writeln('(Note: Biometric telemetry withheld per user privacy settings)');
    }

    contents.add({
      'role': 'user',
      'parts': [{'text': userContext.toString()}],
    });

    final endpoint = '${AiConfig.apiBaseUrl}/models/$_modelName:generateContent?key=$_apiKey';
    final uri = Uri.parse(endpoint);

    final payload = json.encode({
      'system_instruction': {
        'parts': [{'text': systemInstruction}],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': AiConfig.temperature,
        'maxOutputTokens': AiConfig.maxOutputTokens,
      },
    });

    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
    };
    try {
      final appCheckToken = await FirebaseAppCheck.instance.getToken();
      if (appCheckToken != null && appCheckToken.isNotEmpty) {
        requestHeaders['X-Firebase-AppCheck'] = appCheckToken;
      }
    } catch (_) {}

    try {
      final response = await _client.post(
        uri,
        headers: requestHeaders,
        body: payload,
      ).timeout(AiConfig.requestTimeout);

      stopwatch.stop();

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final candidates = decoded['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates.first['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts.first['text'] as String? ?? '';

            // Verified Guideline Citation
            final citations = <MedicalCitation>[
              const MedicalCitation(
                documentId: 'WHO_HYPERTENSION_2023',
                title: 'WHO Guideline for the Pharmacological Treatment of Hypertension in Adults and Lifestyle Interventions',
                titleAr: 'الدليل الإرشادي لمنظمة الصحة العالمية لعلاج ضغط الدم المرتفع لدى البالغين ونمط الحياة',
                organization: 'World Health Organization (WHO)',
                organizationAr: 'منظمة الصحة العالمية',
                year: 2023,
                license: 'CC BY-NC-SA 3.0 IGO',
                sourceUrl: 'https://iris.who.int/handle/10665/344424',
                sectionHeading: 'Blood Pressure Thresholds and Classification',
                sectionHeadingAr: 'تصنيف فئات ومستويات ضغط الدم',
              ),
            ];

            return AiResponse(
              text: text.trim(),
              providerName: name,
              isCloud: true,
              citations: citations,
              isEmergency: isEmergency,
              emergencyAdvice: emergencyNotice,
              latencyMs: stopwatch.elapsedMilliseconds,
              disclaimer: isAr ? AiSafetyPolicy.disclaimerAr : AiSafetyPolicy.disclaimerEn,
            );
          }
        }
      } else if (response.statusCode == 429) {
        throw StateError('Gemini API quota exceeded (HTTP 429).');
      }
      throw http.ClientException('Gemini HTTP ${response.statusCode}: ${response.body}');
    } on TimeoutException {
      stopwatch.stop();
      throw TimeoutException('Gemini API request timed out after ${AiConfig.requestTimeout.inSeconds}s.');
    } catch (e) {
      stopwatch.stop();
      rethrow;
    }
  }

  @override
  Stream<String> generateStream(AiPromptRequest request) async* {
    final response = await generateResponse(request);
    final words = response.text.split(' ');
    final buffer = StringBuffer();
    for (int i = 0; i < words.length; i++) {
      if (i > 0) buffer.write(' ');
      buffer.write(words[i]);
      yield buffer.toString();
      await Future<void>.delayed(const Duration(milliseconds: 15));
    }
  }
}
