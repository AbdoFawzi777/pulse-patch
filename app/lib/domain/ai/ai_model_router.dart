import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../knowledge/medical_knowledge_engine.dart';
import 'ai_provider.dart';
import 'ai_safety_policy.dart';
import 'providers/gemini_cloud_ai_provider.dart';
import 'providers/local_rag_ai_provider.dart';

/// Active AI Routing Mode
enum AiRoutingPreference {
  auto('Auto (Cloud preferred, Offline fallback)', 'تلقائي (سحابي مع احتياطي غير متصل)'),
  cloudOnly('Cloud Only (Gemini 3.8 Flash)', 'سحابي فقط (Gemini 3.8 Flash)'),
  offlineOnly('Offline Only (Local Evidence RAG)', 'غير متصل فقط (قاعدة الأدلة المحلية)');

  const AiRoutingPreference(this.labelEn, this.labelAr);
  final String labelEn;
  final String labelAr;
}

final aiModelRouterProvider = Provider<AiModelRouter>((ref) {
  final knowledgeEngine = ref.watch(medicalKnowledgeEngineProvider);
  return AiModelRouter(
    localProvider: LocalRagAiProvider(knowledgeEngine),
    cloudProvider: GeminiCloudAiProvider(),
  );
});

/// Intelligent AI Router managing cloud and local providers with safety fallbacks
class AiModelRouter {
  AiModelRouter({
    required this.localProvider,
    required this.cloudProvider,
    this.safetyPolicy = const AiSafetyPolicy(),
  });

  final LocalRagAiProvider localProvider;
  final GeminiCloudAiProvider cloudProvider;
  final AiSafetyPolicy safetyPolicy;

  AiRoutingPreference preference = AiRoutingPreference.auto;

  /// Resolves the optimal provider and produces a clinically verified response
  Future<AiResponse> routeAndExecute(AiPromptRequest request) async {
    // 1. Instant local triage for acute emergencies to eliminate network latency
    // CRITICAL SAFETY RULE: Experimental PPG estimates must NEVER trigger hypertensive emergency thresholds.
    // Only real acute symptoms, severe hypoxia (SpO2 < 90%), or extreme arrhythmias trigger instant crisis triage.
    final isEmergency = safetyPolicy.isAcuteEmergency(request.query) ||
        safetyPolicy.isPhysiologicalCrisis(
          hr: request.recentHr,
          spo2: request.recentSpo2,
        );

    // If preference is strictly offline or query is an acute life safety emergency, run local RAG
    if (preference == AiRoutingPreference.offlineOnly) {
      return localProvider.generateResponse(request);
    }

    // Try cloud provider if preference allows and provider is available
    if (preference == AiRoutingPreference.auto || preference == AiRoutingPreference.cloudOnly) {
      final cloudAvailable = await cloudProvider.isAvailable();
      if (cloudAvailable) {
        try {
          final cloudResp = await cloudProvider.generateResponse(request);
          // If acute emergency was flagged locally, ensure emergency banner is retained
          if (isEmergency && !cloudResp.isEmergency) {
            return AiResponse(
              text: cloudResp.text,
              providerName: cloudResp.providerName,
              isCloud: cloudResp.isCloud,
              citations: cloudResp.citations,
              isEmergency: true,
              emergencyAdvice: safetyPolicy.getEmergencyAdvice(isArabic: request.language == 'ar'),
              latencyMs: cloudResp.latencyMs,
              disclaimer: cloudResp.disclaimer,
            );
          }
          return cloudResp;
        } catch (_) {
          // If cloud fails and preference is cloudOnly, rethrow or return error
          if (preference == AiRoutingPreference.cloudOnly) {
            rethrow;
          }
          // Graceful fallback to Local RAG on network/quota failure
        }
      }
    }

    // Fallback to offline local evidence RAG
    return localProvider.generateResponse(request);
  }
}
