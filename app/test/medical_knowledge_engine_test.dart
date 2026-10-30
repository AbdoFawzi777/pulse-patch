// test/medical_knowledge_engine_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:app/domain/knowledge/medical_knowledge_engine.dart';

void main() {
  group('MedicalKnowledgeEngine (System A - RAG)', () {
    late MedicalKnowledgeEngine engine;

    setUp(() {
      engine = MedicalKnowledgeEngine();
    });

    test('initializes and loads corpus successfully', () async {
      await engine.initialize();
      expect(engine.isInitialized, isTrue);
    });

    test('retrieves resting heart rate evidence for English query', () async {
      await engine.initialize();
      final answer = await engine.query('What is a normal resting heart rate?');

      expect(answer.citations, isNotEmpty);
      expect(answer.citations.first.organization, contains('American Heart Association'));
      expect(answer.responseEn, contains('60'));
      expect(answer.responseEn, contains('100'));
      expect(answer.isEmergency, isFalse);
    });

    test('retrieves resting heart rate evidence for Arabic query', () async {
      await engine.initialize();
      final answer = await engine.query('ما هو معدل نبض القلب الطبيعي في وضع الراحة؟');

      expect(answer.citations, isNotEmpty);
      expect(answer.responseAr, contains('60'));
      expect(answer.responseAr, contains('100'));
      expect(answer.isEmergency, isFalse);
    });

    test('retrieves blood oxygen (SpO2) hypoxemia evidence', () async {
      await engine.initialize();
      final answer = await engine.query('What does SpO2 below 90% mean?');

      expect(answer.citations, isNotEmpty);
      expect(answer.citations.first.organization, contains('World Health Organization'));
      expect(answer.responseEn, contains('95%'));
      expect(answer.responseEn, contains('90%'));
    });

    test('retrieves blood pressure classification evidence', () async {
      await engine.initialize();
      final answer = await engine.query('WHO blood pressure classification thresholds');

      expect(answer.citations, isNotEmpty);
      expect(answer.responseEn, contains('120'));
      expect(answer.responseEn, contains('140'));
      expect(answer.citations.first.sourceUrl, isNotEmpty);
    });

    test('retrieves PPG vs cuff distinction without hallucination', () async {
      await engine.initialize();
      final answer = await engine.query('difference between ppg estimates and arm cuff readings');

      expect(answer.citations, isNotEmpty);
      expect(answer.responseEn, contains('PPG'));
      expect(answer.responseEn.toLowerCase(), contains('cuff'));
    });

    test('detects acute emergency symptom triggers in English', () async {
      await engine.initialize();
      final answer = await engine.query('I have severe crushing chest pain and shortness of breath');

      expect(answer.isEmergency, isTrue);
      expect(answer.emergencyNoticeEn, isNotNull);
      expect(answer.emergencyNoticeEn, contains('123'));
    });

    test('detects acute emergency symptom triggers in Arabic', () async {
      await engine.initialize();
      final answer = await engine.query('أشعر بألم شديد في الصدر وضيق تنفس حاد');

      expect(answer.isEmergency, isTrue);
      expect(answer.emergencyNoticeAr, isNotNull);
      expect(answer.emergencyNoticeAr, contains('123'));
    });

    test('returns transparent no-evidence fallback on out-of-domain queries', () async {
      await engine.initialize();
      final answer = await engine.query('quantum computing algorithms in astrophysics');

      expect(answer.citations, isEmpty);
      expect(answer.responseEn, contains('No authoritative evidence'));
      expect(answer.responseAr, contains('لم يتم العثور على أدلة موثوقة'));
    });
  });
}
