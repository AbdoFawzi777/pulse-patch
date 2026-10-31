import 'dart:async';
import '../../knowledge/medical_knowledge_engine.dart';
import '../ai_provider.dart';
import '../ai_safety_policy.dart';

/// Offline Evidence RAG Provider utilizing local indexed clinical corpus
class LocalRagAiProvider implements AiProvider {
  LocalRagAiProvider(this._engine, {AiSafetyPolicy? safetyPolicy})
      : _safetyPolicy = safetyPolicy ?? const AiSafetyPolicy();

  final MedicalKnowledgeEngine _engine;
  final AiSafetyPolicy _safetyPolicy;

  @override
  String get name => 'Local Evidence RAG (Offline)';

  @override
  bool get isCloud => false;

  @override
  Future<bool> isAvailable() async => true; // Always available offline

  @override
  Future<AiResponse> generateResponse(AiPromptRequest request) async {
    final stopwatch = Stopwatch()..start();
    final isAr = request.language == 'ar';

    // 1. Safety Policy Interception
    final isEmergency = _safetyPolicy.isAcuteEmergency(request.query) ||
        _safetyPolicy.isPhysiologicalCrisis(
          sbp: request.estimatedSbp,
          dbp: request.estimatedDbp,
          hr: request.recentHr,
          spo2: request.recentSpo2,
        );

    final emergencyNotice = isEmergency ? _safetyPolicy.getEmergencyAdvice(isArabic: isAr) : null;

    // 2. Query Knowledge Engine
    final answer = await _engine.query(request.query);
    stopwatch.stop();

    final text = isAr ? answer.responseAr : answer.responseEn;
    final disclaimer = isAr ? AiSafetyPolicy.disclaimerAr : AiSafetyPolicy.disclaimerEn;

    return AiResponse(
      text: text,
      providerName: name,
      isCloud: false,
      citations: answer.citations,
      isEmergency: isEmergency,
      emergencyAdvice: emergencyNotice,
      latencyMs: stopwatch.elapsedMilliseconds,
      disclaimer: disclaimer,
    );
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
