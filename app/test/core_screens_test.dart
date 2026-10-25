import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/data/drift/app_database.dart';
import 'package:app/data/repositories/session_repository.dart';
import 'package:app/domain/entities/session_record.dart';
import 'package:app/domain/entities/session_stats_record.dart';
import 'package:app/domain/signal/session_recorder.dart';
import 'package:app/features/device/heart_rate_source.dart';
import 'package:app/features/device/simulated_heart_rate_source.dart';
import 'package:app/features/home/home_screen.dart';
import 'package:app/features/measurement/live_measurement_screen.dart';
import 'package:app/features/measurement/measurement_complete_screen.dart';
import 'package:app/features/measurement/measurement_preparation_screen.dart';

Widget _wrap(Widget child, {AppDatabase? db, HeartRateSource? source}) {
  final inMemDb = db ?? AppDatabase.inMemory();
  final simSource = source ?? SimulatedHeartRateSource();

  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(inMemDb),
      heartRateSourceProvider.overrideWithValue(simSource),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final fontLoader = FontLoader('Outfit');
    final fontLight = File('assets/fonts/Outfit-Light.ttf');
    if (fontLight.existsSync()) {
      fontLoader.addFont(
        Future.value(ByteData.view(fontLight.readAsBytesSync().buffer)),
      );
    }
    final fontReg = File('assets/fonts/Outfit-Regular.ttf');
    if (fontReg.existsSync()) {
      fontLoader.addFont(
        Future.value(ByteData.view(fontReg.readAsBytesSync().buffer)),
      );
    }
    final fontMed = File('assets/fonts/Outfit-Medium.ttf');
    if (fontMed.existsSync()) {
      fontLoader.addFont(
        Future.value(ByteData.view(fontMed.readAsBytesSync().buffer)),
      );
    }
    await fontLoader.load();
  });

  group('Phase 6 Core Screens Widget Tests', () {
    testWidgets('HomeScreen matches Home.png elements and triggers measure', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool measureTapped = false;
      await tester.pumpWidget(
        _wrap(HomeScreen(onStartMeasure: () => measureTapped = true)),
      );

      expect(find.text('Hi, there!'), findsOneWidget);
      expect(find.text('How are you today?'), findsOneWidget);
      expect(find.text('Sample data'), findsOneWidget);
      expect(find.text('Last session'), findsOneWidget);
      expect(find.text('AI Insights'), findsOneWidget);
      expect(find.text('Measure'), findsOneWidget);

      await tester.tap(find.text('Measure'));
      expect(measureTapped, isTrue);
    });

    testWidgets(
      'MeasurementPreparationScreen allows protocol and duration selection',
      (tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        SessionType? selectedType;
        Duration? selectedDuration;

        await tester.pumpWidget(
          _wrap(
            MeasurementPreparationScreen(
              onStart: (type, duration) {
                selectedType = type;
                selectedDuration = duration;
              },
              onBack: () {},
            ),
          ),
        );

        expect(find.text('Prepare Session'), findsOneWidget);
        expect(find.text('Rest'), findsOneWidget);
        expect(find.text('Post-Activity'), findsOneWidget);

        await tester.tap(find.text('Post-Activity'));
        await tester.tap(find.text('90s'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Start Recording'));
        expect(selectedType, SessionType.postActivity);
        expect(selectedDuration, const Duration(seconds: 90));
      },
    );

    testWidgets(
      'LiveMeasurementScreen displays hero number, trace, and timer',
      (tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final recorder = SessionRecorder(
          sessionId: 'live-test',
          targetDuration: const Duration(seconds: 60),
        );
        final sim = SimulatedHeartRateSource(baseBpm: 74.0);
        bool completed = false;

        await tester.pumpWidget(
          _wrap(
            LiveMeasurementScreen(
              recorder: recorder,
              source: sim,
              onComplete: (_) => completed = true,
              onBack: () {},
            ),
            source: sim,
          ),
        );

        expect(find.text('Measuring'), findsOneWidget);
        expect(find.text('Optical pulse trace · Signal: Good'), findsOneWidget);
        expect(find.text('Stop and save'), findsOneWidget);

        await tester.tap(find.text('Stop and save'));
        expect(recorder.state, SessionRecorderState.completed);
        expect(completed, isTrue);
      },
    );

    testWidgets('MeasurementCompleteScreen matches Heart Rate.png elements', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const stats = SessionStatsRecord(
        sessionId: 'complete-test',
        meanHr: 74.0,
        stdHr: 2.5,
        minHr: 58.0,
        maxHr: 96.0,
        startHr: 76.0,
        endHr: 72.0,
        pulseIntervalMs: 811.0,
        variabilityEstMs: 41.0,
        validSampleCount: 60,
        totalDurationSeconds: 60,
      );

      bool saved = false;

      await tester.pumpWidget(
        _wrap(
          MeasurementCompleteScreen(
            stats: stats,
            onSave: () => saved = true,
            onDiscard: () {},
            onViewInsights: () {},
            onBack: () {},
          ),
        ),
      );

      expect(find.text('Heart Rate Summary'), findsOneWidget);
      expect(find.text('74'), findsOneWidget);
      expect(find.text('58 min   96 max'), findsOneWidget);
      expect(find.text('Pulse interval'), findsOneWidget);
      expect(find.text('811 ms'), findsOneWidget);
      expect(find.text('Variability (est.)'), findsOneWidget);
      expect(find.text('41 ms'), findsOneWidget);
      expect(find.text('Save Session'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);

      await tester.tap(find.text('Save Session'));
      expect(saved, isTrue);
    });
  });
}
