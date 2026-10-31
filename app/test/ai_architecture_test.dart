import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:app/domain/ai/ai_config.dart';
import 'package:app/domain/ai/ai_provider.dart';
import 'package:app/domain/ai/ai_safety_policy.dart';
import 'package:app/domain/ai/ai_citation_validator.dart';
import 'package:app/domain/ai/ai_model_router.dart';
import 'package:app/domain/ai/providers/local_rag_ai_provider.dart';
import 'package:app/domain/ai/providers/gemini_cloud_ai_provider.dart';
import 'package:app/domain/knowledge/medical_knowledge_engine.dart';
import 'package:app/domain/knowledge/medical_knowledge_models.dart';

void main() {
  group('PulsePatch Next Generation — Advanced AI Architecture Tests', () {
    late MedicalKnowledgeEngine engine;
    late AiSafetyPolicy safetyPolicy;
    late AiCitationValidator citationValidator;

    setUp(() async {
      engine = MedicalKnowledgeEngine();
      await engine.initialize();
      safetyPolicy = const AiSafetyPolicy();
      citationValidator = const AiCitationValidator();
    });

    test('AiConfig defaults to active Gemini 3.8 Flash and supports 3.5 Flash Lite fallback', () {
      expect(AiConfig.defaultModel, equals('gemini-3.8-flash'));
      expect(AiConfig.fallbackModel, equals('gemini-3.5-flash-lite'));
      expect(AiConfig.displayName, contains('3.8 Flash'));
      expect(AiConfig.maxRequestsPerMinute, equals(15));
      expect(AiConfig.requestTimeout, equals(const Duration(seconds: 10)));
    });

    test('AiSafetyPolicy detects acute life-safety emergency symptoms accurately', () {
      expect(safetyPolicy.isAcuteEmergency('I have crushing chest pain'), isTrue);
      expect(safetyPolicy.isAcuteEmergency('عندي ألم شديد في الصدر وضيق تنفس'), isTrue);
      expect(safetyPolicy.isAcuteEmergency('What is a normal heart rate?'), isFalse);
    });

    test('AiSafetyPolicy identifies ESC/ISH 2023 Hypertensive Crisis thresholds', () {
      // Normotensive
      expect(safetyPolicy.isPhysiologicalCrisis(sbp: 120, dbp: 80), isFalse);
      // Hypertensive Crisis: SBP >= 180 mmHg
      expect(safetyPolicy.isPhysiologicalCrisis(sbp: 185, dbp: 95), isTrue);
      // Hypertensive Crisis: DBP >= 120 mmHg
      expect(safetyPolicy.isPhysiologicalCrisis(sbp: 160, dbp: 125), isTrue);
      // Severe Hypoxia: SpO2 < 90%
      expect(safetyPolicy.isPhysiologicalCrisis(spo2: 88.0), isTrue);
      // Extreme Tachycardia: HR > 150 bpm
      expect(safetyPolicy.isPhysiologicalCrisis(hr: 165.0), isTrue);
    });

    test('AiSafetyPolicy distinguishes Hypertensive Emergency from Severe Asymptomatic Hypertension', () {
      // Severe BP elevation (185/100) WITH acute symptoms -> Emergency (Call 123)
      final isEmergency = safetyPolicy.isHypertensiveEmergency(
        cuffSbp: 185,
        cuffDbp: 100,
        hasAcuteSymptoms: true,
      );
      expect(isEmergency, isTrue);

      // Severe BP elevation (185/100) WITHOUT acute symptoms -> Asymptomatic (Repeat measurement protocol)
      final isAsymptomaticSevere = safetyPolicy.isSevereAsymptomaticHypertension(
        cuffSbp: 185,
        cuffDbp: 100,
        hasAcuteSymptoms: false,
      );
      expect(isAsymptomaticSevere, isTrue);

      // Verify repeat measurement advice gives 5-minute rest and certified cuff instructions
      final repeatAdviceEn = safetyPolicy.getSevereHypertensionAdvice(isArabic: false);
      expect(repeatAdviceEn, contains('5 minutes'));
      expect(repeatAdviceEn, contains('arm cuff'));
      expect(repeatAdviceEn, contains('ESC/ESH 2023'));

      final repeatAdviceAr = safetyPolicy.getSevereHypertensionAdvice(isArabic: true);
      expect(repeatAdviceAr, contains('5 دقائق'));
      expect(repeatAdviceAr, contains('الكفة'));
    });

    test('AiSafetyPolicy formats Egyptian Ambulance 123 emergency guidance in EN and AR', () {
      final adviceEn = safetyPolicy.getEmergencyAdvice(isArabic: false);
      expect(adviceEn, contains('123'));
      expect(adviceEn, contains('EMERGENCY'));

      final adviceAr = safetyPolicy.getEmergencyAdvice(isArabic: true);
      expect(adviceAr, contains('123'));
      expect(adviceAr, contains('طوارئ'));
    });

    test('AiCitationValidator strictly verifies real indexed corpus citations and rejects hallucinations', () {
      const validCitation = MedicalCitation(
        documentId: 'WHO_HYPERTENSION_2023',
        title: 'WHO Guideline for the Pharmacological Treatment of Hypertension in Adults',
        titleAr: 'الدليل الإرشادي لمنظمة الصحة العالمية',
        organization: 'World Health Organization (WHO)',
        organizationAr: 'منظمة الصحة العالمية',
        year: 2023,
        license: 'CC BY-NC-SA 3.0 IGO',
        sourceUrl: 'https://iris.who.int/handle/10665/344424',
        sectionHeading: 'Blood Pressure Thresholds and Classification',
        sectionHeadingAr: 'تصنيف فئات ومستويات ضغط الدم',
      );

      final validResult = citationValidator.validateCitation(validCitation);
      expect(validResult.isValid, isTrue);
      expect(citationValidator.hasAuthoritativeCitations([validCitation]), isTrue);

      // Hallucinated Document ID
      const fakeDocCitation = MedicalCitation(
        documentId: 'WHO_MIRACLE_CURE_2025',
        title: 'Miracle Cure for Hypertension',
        titleAr: 'علاج خارق',
        organization: 'World Health Organization (WHO)',
        organizationAr: 'منظمة الصحة العالمية',
        year: 2025,
        license: 'CC BY',
        sourceUrl: 'https://iris.who.int/fake',
        sectionHeading: 'Fake Section',
        sectionHeadingAr: 'قسم وهمي',
      );
      final fakeDocResult = citationValidator.validateCitation(fakeDocCitation);
      expect(fakeDocResult.isValid, isFalse);
      expect(fakeDocResult.failureReason, contains('Hallucinated or unverified document ID'));

      // Hallucinated futuristic publication year (> 2026)
      const futureCitation = MedicalCitation(
        documentId: 'WHO_HYPERTENSION_2023',
        title: 'WHO Hypertension Guideline',
        titleAr: 'دليل منظمة الصحة العالمية',
        organization: 'World Health Organization (WHO)',
        organizationAr: 'منظمة الصحة العالمية',
        year: 2035, // Future year
        license: 'CC BY',
        sourceUrl: 'https://who.int/future',
        sectionHeading: 'Blood Pressure Thresholds and Classification',
        sectionHeadingAr: 'تصنيف',
      );
      final futureResult = citationValidator.validateCitation(futureCitation);
      expect(futureResult.isValid, isFalse);
      expect(futureResult.failureReason, contains('Future/hallucinated publication year'));

      // Untrusted external domain
      const untrustedDomainCitation = MedicalCitation(
        documentId: 'WHO_HYPERTENSION_2023',
        title: 'WHO Hypertension Guideline',
        titleAr: 'دليل منظمة الصحة العالمية',
        organization: 'World Health Organization (WHO)',
        organizationAr: 'منظمة الصحة العالمية',
        year: 2023,
        license: 'CC BY',
        sourceUrl: 'https://suspicious-medical-blog.com/guidelines',
        sectionHeading: 'Blood Pressure Thresholds and Classification',
        sectionHeadingAr: 'تصنيف',
      );
      final untrustedResult = citationValidator.validateCitation(untrustedDomainCitation);
      expect(untrustedResult.isValid, isFalse);
      expect(untrustedResult.failureReason, contains('Untrusted or hallucinated domain'));
    });

    test('AiCitationValidator enforces distinction between PPG blood pressure and cuff measurements', () {
      const compliantExplanation = 'Wearable PPG blood pressure estimation detects microvascular pulse volume and produces research approximations. It requires periodic cuff sphygmomanometer calibration and cannot replace clinical arm cuffs.';
      expect(AiCitationValidator.isPpgBpDiscussion(compliantExplanation), isTrue);
      expect(AiCitationValidator.verifyPpgBpSeparation(compliantExplanation), isTrue);

      const nonCompliantExplanation = 'Your PPG sensor reading is 140/90 mmHg which proves you have stage 2 hypertension and should start medication.';
      expect(AiCitationValidator.isPpgBpDiscussion(nonCompliantExplanation), isTrue);
      expect(AiCitationValidator.verifyPpgBpSeparation(nonCompliantExplanation), isFalse);
    });

    test('HealthContext privacy gate withholds vitals from external cloud when consent is absent', () {
      const requestWithoutConsent = AiPromptRequest(
        query: 'What do my recent readings mean?',
        language: 'en',
        recentHr: 72.0,
        recentSpo2: 98.0,
        estimatedSbp: 120.0,
        estimatedDbp: 80.0,
        hasUserConsent: false,
      );

      // Context map intended for external cloud MUST NOT contain health vitals without consent
      final cloudContext = requestWithoutConsent.toContextMap(isExternalCloud: true);
      expect(cloudContext.containsKey('recent_hr'), isFalse);
      expect(cloudContext.containsKey('recent_spo2'), isFalse);
      expect(cloudContext.containsKey('estimated_sbp'), isFalse);
      expect(cloudContext['telemetry_sharing_status'], equals('withheld_by_user_privacy_policy'));

      // Context map intended for local on-device RAG retains vitals safely
      final localContext = requestWithoutConsent.toContextMap(isExternalCloud: false);
      expect(localContext['recent_hr'], equals(72.0));
      expect(localContext['recent_spo2'], equals(98.0));

      // With explicit consent, cloud context receives authorized vitals
      const requestWithConsent = AiPromptRequest(
        query: 'What do my recent readings mean?',
        language: 'en',
        recentHr: 72.0,
        recentSpo2: 98.0,
        estimatedSbp: 120.0,
        estimatedDbp: 80.0,
        hasUserConsent: true,
      );
      final consentedCloudContext = requestWithConsent.toContextMap(isExternalCloud: true);
      expect(consentedCloudContext['recent_hr'], equals(72.0));
      expect(consentedCloudContext['recent_spo2'], equals(98.0));
      expect(consentedCloudContext['telemetry_sharing_status'], equals('consented_by_user'));
    });

    test('Multi-turn conversation history serializes correctly for Gemini 3.8', () {
      const message1 = AiChatMessage(role: 'user', text: 'What is normal resting heart rate?');
      const message2 = AiChatMessage(role: 'model', text: 'Normal adult resting heart rate is 60-100 BPM.');
      const message3 = AiChatMessage(role: 'user', text: 'What if mine is 105?');

      const request = AiPromptRequest(
        query: 'What if mine is 105?',
        language: 'en',
        conversationHistory: [message1, message2, message3],
      );

      expect(request.conversationHistory.length, equals(3));
      final historyMap = request.conversationHistory.map((m) => m.toJson()).toList();
      expect(historyMap[0]['role'], equals('user'));
      expect(historyMap[1]['role'], equals('model'));
      expect(historyMap[2]['parts'][0]['text'], equals('What if mine is 105?'));
    });

    test('GeminiCloudAiProvider correctly detects HTTP 429 and router falls back to Local RAG', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'error': {
              'code': 429,
              'message': 'Resource has been exhausted (e.g. check quota).',
              'status': 'RESOURCE_EXHAUSTED',
            }
          }),
          429,
        );
      });

      final cloudProvider = GeminiCloudAiProvider(
        apiKey: 'test-api-key',
        httpClient: mockClient,
      );

      // Direct provider invocation throws StateError
      expect(
        () => cloudProvider.generateResponse(
          const AiPromptRequest(query: 'Hello doctor', language: 'en'),
        ),
        throwsA(isA<StateError>()),
      );

      // Router catches the 429 and degrades smoothly to local evidence RAG
      final router = AiModelRouter(
        localProvider: LocalRagAiProvider(engine),
        cloudProvider: cloudProvider,
      );

      final routedResponse = await router.routeAndExecute(
        const AiPromptRequest(
          query: 'What is a normal heart rate?',
          language: 'en',
        ),
      );

      expect(routedResponse.isCloud, isFalse);
      expect(routedResponse.providerName, contains('Local Evidence RAG'));
      expect(routedResponse.citations, isNotEmpty);
    });

    test('LocalRagAiProvider produces structured responses with verified citations', () async {
      final localProvider = LocalRagAiProvider(engine);
      expect(localProvider.isCloud, isFalse);
      expect(await localProvider.isAvailable(), isTrue);

      const request = AiPromptRequest(
        query: 'What is a normal resting heart rate?',
        language: 'en',
      );

      final response = await localProvider.generateResponse(request);
      expect(response.providerName, contains('Local Evidence RAG'));
      expect(response.citations, isNotEmpty);
      expect(response.text, isNotEmpty);
      expect(response.isEmergency, isFalse);
    });

    test('GeminiCloudAiProvider correctly identifies missing API key and degrades gracefully', () async {
      final cloudProvider = GeminiCloudAiProvider(apiKey: '');
      expect(cloudProvider.isCloud, isTrue);
      expect(await cloudProvider.isAvailable(), isFalse);
    });

    test('AiModelRouter intelligently routes to local provider when offline or emergency', () async {
      final localProvider = LocalRagAiProvider(engine);
      final cloudProvider = GeminiCloudAiProvider(apiKey: '');
      final router = AiModelRouter(
        localProvider: localProvider,
        cloudProvider: cloudProvider,
      );

      // In Auto mode without cloud key, it routes to local cleanly
      final response = await router.routeAndExecute(
        const AiPromptRequest(
          query: 'What does SpO2 measure?',
          language: 'en',
        ),
      );

      expect(response.isCloud, isFalse);
      expect(response.citations, isNotEmpty);
    });
  });
}
