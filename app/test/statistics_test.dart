import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/data/drift/app_database.dart';
import 'package:app/data/repositories/session_repository.dart';
import 'package:app/domain/entities/pulse_sample.dart';
import 'package:app/domain/entities/session_record.dart';
import 'package:app/domain/entities/session_stats_record.dart';
import 'package:app/domain/signal/feature_extractor.dart';
import 'package:app/features/reports/recovery_analysis_screen.dart';

Widget _wrap(Widget child, {AppDatabase? db}) {
  final inMemDb = db ?? AppDatabase.inMemory();
  return ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(inMemDb)],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Phase 8 Statistics & Recovery Analysis Tests', () {
    test(
      'Golden test vectors from test_vectors.json pass Dart FeatureExtractor',
      () {
        final file = File('test/test_vectors.json');
        expect(file.existsSync(), isTrue);

        final jsonList = jsonDecode(file.readAsStringSync()) as List<dynamic>;

        for (final vec in jsonList) {
          final name = vec['name'] as String;
          final protocolStr = vec['protocol'] as String;
          final type = protocolStr == 'post_activity'
              ? SessionType.postActivity
              : SessionType.rest;

          final rawSamples = vec['samples'] as List<dynamic>;
          final samples = rawSamples.map((s) {
            final tSec = s['t_sec'] as int;
            final bpm = (s['bpm'] as num).toDouble();
            final quality = s['quality'] as int;
            final isValid = s['is_valid'] as bool;
            return PulseSample(
              sessionId: name,
              tMs: tSec * 1000,
              bpm: bpm,
              quality: quality,
              isValid: isValid,
            );
          }).toList();

          final expected = vec['expected'] as Map<String, dynamic>;
          final expectedAnalyzable = expected['is_analyzable'] as bool;

          final features = FeatureExtractor.extract(
            samples: samples,
            type: type,
          );

          expect(
            features.isAnalyzable,
            expectedAnalyzable,
            reason: 'Failed on $name',
          );

          if (expectedAnalyzable) {
            final expMean = (expected['mean_hr'] as num).toDouble();
            final expStd = (expected['std_hr'] as num).toDouble();
            final expStart = (expected['start_hr'] as num).toDouble();
            final expEnd = (expected['end_hr'] as num).toDouble();
            final expDrop = (expected['recovery_drop'] as num).toDouble();

            expect(
              features.meanHr,
              closeTo(expMean, 1e-4),
              reason: '$name mean_hr',
            );
            expect(
              features.stdHr,
              closeTo(expStd, 1e-4),
              reason: '$name std_hr',
            );
            expect(
              features.startHr,
              closeTo(expStart, 1e-4),
              reason: '$name start_hr',
            );
            expect(
              features.endHr,
              closeTo(expEnd, 1e-4),
              reason: '$name end_hr',
            );
            expect(
              features.recoveryDrop,
              closeTo(expDrop, 1e-4),
              reason: '$name recovery_drop',
            );
          }
        }
      },
    );

    test('Recovery drop requires >= 70s duration for postActivity', () {
      // 60-second postActivity session (under 70s)
      final samples60 = List.generate(
        60,
        (i) => PulseSample(
          sessionId: 'short-post',
          tMs: i * 1000,
          bpm: 110.0 - (i * 0.5),
          quality: 90,
          isValid: true,
        ),
      );

      final features60 = FeatureExtractor.extract(
        samples: samples60,
        type: SessionType.postActivity,
      );

      expect(features60.isAnalyzable, isTrue);
      expect(
        features60.recoveryDrop,
        isNull,
      ); // Marked Insufficient for recovery analysis

      // 75-second postActivity session (>= 70s)
      final samples75 = List.generate(
        75,
        (i) => PulseSample(
          sessionId: 'valid-post',
          tMs: i * 1000,
          bpm: i < 10 ? 120.0 : (i >= 55 && i <= 65 ? 90.0 : 100.0),
          quality: 90,
          isValid: true,
        ),
      );

      final features75 = FeatureExtractor.extract(
        samples: samples75,
        type: SessionType.postActivity,
      );

      expect(features75.isAnalyzable, isTrue);
      expect(features75.recoveryDrop, isNotNull);
      expect(features75.recoveryDrop, closeTo(30.0, 1e-4));
    });

    test('Personal baseline comparison enforces >= 5 sessions guardrail', () {
      // 4 sessions: insufficient for baseline
      final fourStats = List.generate(
        4,
        (i) => SessionStatsRecord(
          sessionId: 'prior-$i',
          meanHr: 70.0 + (i * 2.0),
          stdHr: 2.0,
          minHr: 65.0,
          maxHr: 78.0,
          startHr: 72.0,
          endHr: 70.0,
          validSampleCount: 60,
          totalDurationSeconds: 60,
        ),
      );

      final comp4 = FeatureExtractor.compareBaseline(
        currentMeanHr: 75.0,
        priorStats: fourStats,
      );
      expect(comp4.hasBaseline, isFalse);
      expect(comp4.baselineCount, 4);
      expect(
        comp4.summaryText,
        contains('Requires at least 5 baseline recordings'),
      );

      // 5 sessions: unlocks baseline comparison
      final fiveStats = [
        ...fourStats,
        const SessionStatsRecord(
          sessionId: 'prior-4',
          meanHr: 78.0,
          stdHr: 2.0,
          minHr: 65.0,
          maxHr: 80.0,
          startHr: 72.0,
          endHr: 70.0,
          validSampleCount: 60,
          totalDurationSeconds: 60,
        ),
      ];

      // Mean of [70, 72, 74, 76, 78] is 74.0, std is ~3.162
      final comp5 = FeatureExtractor.compareBaseline(
        currentMeanHr: 74.0,
        priorStats: fiveStats,
      );
      expect(comp5.hasBaseline, isTrue);
      expect(comp5.baselineCount, 5);
      expect(comp5.zScore, closeTo(0.0, 1e-4));
      expect(comp5.summaryText, contains('Typical for your personal baseline'));
    });

    testWidgets(
      'RecoveryAnalysisScreen displays recovery drop and baseline statistics',
      (tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final db = AppDatabase.inMemory();
        final repo = SessionRepository(db);

        // Seed 5 prior post-activity sessions to satisfy baseline requirement
        for (int i = 0; i < 5; i++) {
          await repo.insertSession(
            session: SessionRecord(
              id: 'prior-$i',
              startedAt: DateTime.now().subtract(Duration(days: i + 1)),
              endedAt: DateTime.now().subtract(
                Duration(days: i + 1, minutes: -2),
              ),
              type: SessionType.postActivity,
              qualitySummary: QualitySummary.good,
              appVersion: '1.0.0',
              source: SessionSource.simulator,
            ),
            samples: const [],
            stats: SessionStatsRecord(
              sessionId: 'prior-$i',
              meanHr: 80.0 + (i * 2.0),
              stdHr: 3.0,
              minHr: 70.0,
              maxHr: 100.0,
              startHr: 95.0,
              endHr: 78.0,
              validSampleCount: 90,
              totalDurationSeconds: 90,
            ),
          );
        }

        const currentStats = SessionStatsRecord(
          sessionId: 'current-rec',
          meanHr: 84.0,
          stdHr: 3.2,
          minHr: 70.0,
          maxHr: 105.0,
          startHr: 102.0,
          endHr: 78.0,
          recoveryDrop: 24.0,
          validSampleCount: 80,
          totalDurationSeconds: 80,
        );

        final session = SessionRecord(
          id: 'current-rec',
          startedAt: DateTime.now().subtract(const Duration(hours: 1)),
          endedAt: DateTime.now().subtract(
            const Duration(minutes: 58, seconds: 40),
          ),
          type: SessionType.postActivity,
          qualitySummary: QualitySummary.good,
          appVersion: '1.0.0',
          source: SessionSource.simulator,
        );

        await tester.pumpWidget(
          _wrap(
            RecoveryAnalysisScreen(
              session: session,
              stats: currentStats,
              onBack: () {},
            ),
            db: db,
          ),
        );

        expect(find.text('Recovery Analysis'), findsOneWidget);
        expect(find.text('Post-Activity Recovery Drop'), findsOneWidget);
        expect(find.text('-24'), findsOneWidget);
        expect(find.text('BPM in 60s'), findsOneWidget);
        expect(find.text('Personal Baseline Statistics'), findsOneWidget);
        expect(find.text('Statistical z-score'), findsOneWidget);
        expect(
          find.textContaining('Typical for your personal baseline'),
          findsOneWidget,
        );
        expect(
          find.textContaining('educational research prototype'),
          findsOneWidget,
        );

        db.close();
      },
    );
  });
}
