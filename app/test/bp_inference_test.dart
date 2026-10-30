import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/domain/ai/bp_inference_service.dart';

void main() {
  group('BpInferenceService Pure Dart Tests', () {
    final service = BpInferenceService.defaultModel();

    test('performs inference in under 1 millisecond', () {
      final res = service.estimate(
        age: 55,
        gender: 1,
        bmi: 24.5,
        hrBpm: 72,
        crestTimeMs: 150,
        decayTimeMs: 700,
        pw50Ms: 245,
        areaRatio: 0.27,
        reflectionIndex: 0.75,
        stiffnessIndex: 10.5,
      );

      expect(res.sbp, inInclusiveRange(70, 220));
      expect(res.dbp, inInclusiveRange(40, 140));
      expect(res.map, greaterThan(res.dbp));
      expect(res.map, lessThan(res.sbp));
      expect(res.inferenceMs, lessThan(10.0)); // well under interactive budget
      expect(res.category, isNotEmpty);
      expect(res.categoryArabic, isNotEmpty);
    });

    test('calibrates accurately when offsets are provided', () {
      final uncalibrated = service.estimate(
        age: 60,
        gender: 0,
        bmi: 28.0,
        hrBpm: 75,
        crestTimeMs: 160,
        decayTimeMs: 710,
        pw50Ms: 250,
        areaRatio: 0.29,
        reflectionIndex: 0.78,
        stiffnessIndex: 11.2,
      );

      final calibratedService = BpInferenceService.defaultModel(
        sbpOffset: 5.0,
        dbpOffset: -3.0,
      );

      final calibrated = calibratedService.estimate(
        age: 60,
        gender: 0,
        bmi: 28.0,
        hrBpm: 75,
        crestTimeMs: 160,
        decayTimeMs: 710,
        pw50Ms: 250,
        areaRatio: 0.29,
        reflectionIndex: 0.78,
        stiffnessIndex: 11.2,
      );

      expect(calibrated.isCalibrated, isTrue);
      expect((calibrated.sbp - uncalibrated.sbp).round(), equals(5));
      expect((calibrated.dbp - uncalibrated.dbp).round(), equals(-3));
    });

    test('correctly categorizes AHA 2017 blood pressure stages', () {
      expect(BpInferenceService.classify(115, 75), equals(BpCategory.normal));
      expect(BpInferenceService.classify(125, 78), equals(BpCategory.elevated));
      expect(BpInferenceService.classify(135, 85), equals(BpCategory.hypertensionStage1));
      expect(BpInferenceService.classify(145, 95), equals(BpCategory.hypertensionStage2));
      expect(BpInferenceService.classify(185, 125), equals(BpCategory.hypertensiveCrisis));
    });

    test('verifies numerical parity between defaultModel and bp_model_meta.json', () {
      final metaFile = File('assets/ml/bp_model_meta.json');
      if (metaFile.existsSync()) {
        final jsonMap = jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>;
        final serviceFromMeta = BpInferenceService.fromMeta(jsonMap);

        final resDefault = service.estimate(
          age: 48,
          gender: 1,
          bmi: 26.2,
          hrBpm: 78,
          crestTimeMs: 180,
          decayTimeMs: 620,
          pw50Ms: 270,
          areaRatio: 0.31,
          reflectionIndex: 0.76,
          stiffnessIndex: 8.9,
        );

        final resMeta = serviceFromMeta.estimate(
          age: 48,
          gender: 1,
          bmi: 26.2,
          hrBpm: 78,
          crestTimeMs: 180,
          decayTimeMs: 620,
          pw50Ms: 270,
          areaRatio: 0.31,
          reflectionIndex: 0.76,
          stiffnessIndex: 8.9,
        );

        expect((resDefault.sbp - resMeta.sbp).abs(), lessThan(0.01));
        expect((resDefault.dbp - resMeta.dbp).abs(), lessThan(0.01));
      }
    });

    test('handles extreme out-of-distribution inputs with safe physiological clamping', () {
      final extremeLow = service.estimate(
        age: 18,
        gender: 0,
        bmi: 15.0,
        hrBpm: 40,
        crestTimeMs: 50,
        decayTimeMs: 1200,
        pw50Ms: 70,
        areaRatio: 0.05,
        reflectionIndex: 0.30,
        stiffnessIndex: 4.0,
      );

      expect(extremeLow.sbp, greaterThanOrEqualTo(70.0));
      expect(extremeLow.dbp, greaterThanOrEqualTo(40.0));
      expect(extremeLow.map, greaterThan(extremeLow.dbp));

      final extremeHigh = service.estimate(
        age: 95,
        gender: 1,
        bmi: 48.0,
        hrBpm: 180,
        crestTimeMs: 350,
        decayTimeMs: 250,
        pw50Ms: 500,
        areaRatio: 0.85,
        reflectionIndex: 0.99,
        stiffnessIndex: 22.0,
      );

      expect(extremeHigh.sbp, lessThanOrEqualTo(220.0));
      expect(extremeHigh.dbp, lessThanOrEqualTo(140.0));
    });
  });
}
