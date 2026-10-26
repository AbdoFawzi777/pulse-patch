import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/drift/app_database.dart';
import 'package:app/data/repositories/session_repository.dart';
import 'package:app/domain/entities/ai_result_record.dart';
import 'package:app/domain/entities/session_record.dart';
import 'package:app/domain/entities/session_stats_record.dart';
import 'package:app/domain/ml/ai_inference_service.dart';
import 'package:app/domain/ml/ai_model_metadata.dart';
import 'package:app/features/insights/ai_insights_dashboard_screen.dart';
import 'package:app/features/insights/ai_model_info_screen.dart';
import 'package:app/features/insights/session_pattern_analysis_screen.dart';

void main() {
  group('Phase 9 AI Insights - Model Metadata & Inference Service', () {
    test('AiModelMetadata parses defaults and JSON correctly', () {
      final meta = AiModelMetadata.fromJson(const {});
      expect(meta.modelName, equals('PulsePatch AI Insights'));
      expect(
        meta.engine,
        equals('small neural network running locally in the app'),
      );
      expect(meta.features.length, equals(5));
      expect(meta.labels, contains('Typical pattern'));
      expect(meta.labels, contains('Different pattern'));
      expect(meta.nonDiagnosticDisclaimer, contains('educational prototype'));
    });

    test(
      'AiInferenceService rejects sessions under 30 valid seconds',
      () async {
        final service = AiInferenceService();
        await service.initialize();

        final state = await service.analyzeSession(
          sessionId: 'test-short',
          features: {
            'mean_hr': 72.0,
            'std_hr': 3.0,
            'start_hr': 74.0,
            'end_hr': 70.0,
            'recovery_drop': -4.0,
          },
          validSampleCount: 20, // less than 30s required
          sessionType: SessionType.rest,
        );

        expect(state.status, equals(AiInferenceStatus.insufficientData));
        expect(
          state.insufficientReason,
          contains('Requires at least 30 seconds'),
        );
      },
    );

    test(
      'AiInferenceService rejects post-activity without recovery drop',
      () async {
        final service = AiInferenceService();
        await service.initialize();

        final state = await service.analyzeSession(
          sessionId: 'test-no-drop',
          features: {
            'mean_hr': 85.0,
            'std_hr': 5.0,
            'start_hr': 90.0,
            'end_hr': 80.0,
            'recovery_drop': null, // missing required recovery drop
          },
          validSampleCount: 75,
          sessionType: SessionType.postActivity,
        );

        expect(state.status, equals(AiInferenceStatus.insufficientData));
        expect(
          state.insufficientReason,
          contains('Post-activity sessions require 70+ seconds'),
        );
      },
    );

    test(
      'AiInferenceService classifies typical resting session as Typical pattern',
      () async {
        final service = AiInferenceService();
        await service.initialize();

        final state = await service.analyzeSession(
          sessionId: 'test-typical',
          features: {
            'mean_hr': 74.0,
            'std_hr': 3.1,
            'start_hr': 78.0,
            'end_hr': 70.0,
            'recovery_drop': -8.0,
          },
          validSampleCount: 60,
          sessionType: SessionType.rest,
        );

        expect(state.status, equals(AiInferenceStatus.success));
        expect(state.result?.label, equals('Typical pattern'));
        expect(state.result?.explanation, contains('not a health rating'));
        // Verify non-diagnostic rule: no medical terms
        expect(state.result?.label.toLowerCase(), isNot(contains('normal')));
        expect(state.result?.label.toLowerCase(), isNot(contains('healthy')));
      },
    );

    test(
      'AiInferenceService classifies heavily deviated session as Different pattern',
      () async {
        final service = AiInferenceService();
        await service.initialize();

        final state = await service.analyzeSession(
          sessionId: 'test-different',
          features: {
            'mean_hr': 145.0, // High deviation
            'std_hr': 22.0, // High variance
            'start_hr': 150.0,
            'end_hr': 140.0,
            'recovery_drop': -10.0,
          },
          validSampleCount: 60,
          sessionType: SessionType.rest,
        );

        expect(state.status, equals(AiInferenceStatus.success));
        expect(state.result?.label, equals('Different pattern'));
        expect(state.result?.explanation, contains('not a health rating'));
        expect(state.result?.label.toLowerCase(), isNot(contains('abnormal')));
        expect(state.result?.label.toLowerCase(), isNot(contains('unhealthy')));
      },
    );

    test(
      'AiInferenceService classifies post-activity session with drop >= 12 BPM as Typical pattern',
      () async {
        final service = AiInferenceService();
        await service.initialize();

        final state = await service.analyzeSession(
          sessionId: 'test-post-typical',
          features: {
            'mean_hr': 105.0,
            'std_hr': 12.0,
            'start_hr': 128.0,
            'end_hr': 74.0,
            'recovery_drop': 46.0, // Large recovery drop >= 12 BPM
          },
          validSampleCount: 90,
          sessionType: SessionType.postActivity,
        );

        expect(state.status, equals(AiInferenceStatus.success));
        expect(state.result?.label, equals('Typical pattern'));
        expect(
          state.result?.explanation,
          contains('expected deceleration following activity'),
        );
      },
    );

    test(
      'AiInferenceService classifies post-activity session with drop < 12 BPM as Different pattern',
      () async {
        final service = AiInferenceService();
        await service.initialize();

        final state = await service.analyzeSession(
          sessionId: 'test-post-blunted',
          features: {
            'mean_hr': 74.0,
            'std_hr': 0.8,
            'start_hr': 75.0,
            'end_hr': 74.0,
            'recovery_drop': 0.0, // Blunted recovery drop < 12 BPM
          },
          validSampleCount: 90,
          sessionType: SessionType.postActivity,
        );

        expect(state.status, equals(AiInferenceStatus.success));
        expect(state.result?.label, equals('Different pattern'));
        expect(
          state.result?.explanation,
          contains('blunted (<12 BPM drop in 60s)'),
        );
      },
    );

    test(
      'AiInferenceService re-evaluates Session 1 recorded features as Typical pattern',
      () async {
        final service = AiInferenceService();
        await service.initialize();

        final state = await service.analyzeSession(
          sessionId: 'sess-1792996240842',
          features: {
            'mean_hr': 71.83076923076923,
            'std_hr': 1.305866938680378,
            'start_hr': 72.0,
            'end_hr': 73.0,
            'recovery_drop': -1.0,
          },
          validSampleCount: 65,
          sessionType: SessionType.rest,
        );

        expect(state.status, equals(AiInferenceStatus.success));
        expect(state.result?.label, equals('Typical pattern'));
        expect(state.result?.scaledFeatures['mean_hr'], closeTo(-0.771, 0.01));
        expect(state.result?.explanation, contains('Similar to your last'));
      },
    );
  });

  group('Phase 9 AI Insights - Screen Widget Tests', () {
    testWidgets(
      'SessionPatternAnalysisScreen renders AI Insights.png components',
      (tester) async {
        final inMemoryDb = AppDatabase.inMemory();
        final repo = SessionRepository(inMemoryDb);

        final sampleResult = AiInferenceResult(
          label: 'Typical pattern',
          explanation:
              'Similar to your last 5 rest sessions. A pattern label, not a health rating.',
          comparisonText: 'Recorded across 5 prior sessions.',
          features: {
            'mean_hr': 74.0,
            'std_hr': 3.1,
            'start_hr': 78.0,
            'end_hr': 70.0,
            'recovery_drop': -8.0,
          },
          scaledFeatures: {},
          modelVersion: '1.0.0',
          inferredAt: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [sessionRepositoryProvider.overrideWithValue(repo)],
            child: MaterialApp(
              home: SessionPatternAnalysisScreen(
                sessionId: 'sess-test-1',
                initialResult: sampleResult,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Top bar title
        expect(find.text('AI Insights'), findsOneWidget);

        // Model Result Card elements
        expect(find.text('Model result'), findsOneWidget);
        expect(find.text('Experimental'), findsOneWidget);
        expect(find.text('Typical pattern'), findsOneWidget);
        expect(
          find.textContaining('Similar to your last 5 rest sessions'),
          findsOneWidget,
        );

        // 5 Feature Cards
        expect(find.text('mean_hr'), findsOneWidget);
        expect(find.text('74 BPM'), findsOneWidget);
        expect(find.text('std_hr'), findsOneWidget);
        expect(find.text('3.1'), findsOneWidget);
        expect(find.text('start_hr'), findsOneWidget);
        expect(find.text('78 BPM'), findsOneWidget);
        expect(find.text('end_hr'), findsOneWidget);
        expect(find.text('70 BPM'), findsOneWidget);
        expect(find.text('recovery_drop'), findsOneWidget);
        expect(find.text('-8 BPM'), findsOneWidget);

        // Footer
        expect(
          find.textContaining('Runs on this phone · small neural network'),
          findsOneWidget,
        );
      },
    );

    testWidgets('AiInsightsDashboardScreen renders summary and lists sessions', (
      tester,
    ) async {
      final inMemoryDb = AppDatabase.inMemory();
      final repo = SessionRepository(inMemoryDb);

      // Seed 2 sessions
      repo.insertSession(
        session: SessionRecord(
          id: 'sess-dash-1',
          startedAt: DateTime.now().subtract(const Duration(hours: 1)),
          endedAt: DateTime.now().subtract(const Duration(minutes: 58)),
          type: SessionType.rest,
          qualitySummary: QualitySummary.good,
          appVersion: '1.0.0',
          source: SessionSource.pulsepatch,
        ),
        samples: [],
        stats: const SessionStatsRecord(
          sessionId: 'sess-dash-1',
          meanHr: 72.0,
          stdHr: 3.0,
          minHr: 68.0,
          maxHr: 76.0,
          startHr: 74.0,
          endHr: 70.0,
          recoveryDrop: -4.0,
          pulseIntervalMs: 833.0,
          variabilityEstMs: 35.0,
          validSampleCount: 60,
          totalDurationSeconds: 60,
        ),
        aiResult: AiResultRecord(
          sessionId: 'sess-dash-1',
          modelVersion: '1.0.0',
          label: 'Typical pattern',
          featuresJson: '{}',
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sessionRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: AiInsightsDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Header and model result card
      expect(find.text('AI Insights'), findsOneWidget);
      expect(find.text('Model result'), findsOneWidget);
      expect(find.text('Experimental'), findsOneWidget);
      expect(find.text('Typical pattern'), findsWidgets);
      expect(
        find.text(
          'Similar to your last 5 rest sessions. A pattern label, not a health rating.',
        ),
        findsOneWidget,
      );

      // Section header and values
      expect(find.text('Measured values used'), findsOneWidget);
    });

    testWidgets(
      'AiModelInfoScreen displays model architecture and technical panel',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(const MaterialApp(home: AiModelInfoScreen()));
        await tester.pumpAndSettle();

        // Top bar & Hero
        expect(find.text('AI Model Information'), findsOneWidget);
        expect(find.text('PulsePatch AI Insights'), findsOneWidget);
        expect(
          find.text('On-device Dart Background Isolate Engine'),
          findsOneWidget,
        );
        expect(find.text('100% Offline & Private'), findsOneWidget);

        // Technical panel toggle
        final panelFinder = find.text('Technical Evaluator Panel');
        expect(panelFinder, findsOneWidget);
        await tester.ensureVisible(panelFinder);
        await tester.pumpAndSettle();
        await tester.tap(panelFinder);
        await tester.pumpAndSettle();

        // Verify expanded technical details
        expect(find.text('MLP (5 -> 16 -> 8 -> 1)'), findsOneWidget);
        expect(find.text('[1, 5] (Float32)'), findsOneWidget);
      },
    );
  });
}
