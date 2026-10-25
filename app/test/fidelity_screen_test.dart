import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/data/drift/app_database.dart';
import 'package:app/data/repositories/session_repository.dart';
import 'package:app/domain/entities/ai_result_record.dart';
import 'package:app/domain/entities/session_record.dart';
import 'package:app/domain/entities/session_stats_record.dart';
import 'package:app/domain/signal/ble_packet.dart';
import 'package:app/domain/signal/session_recorder.dart';
import 'package:app/shared/widgets/app_icon_widget.dart';
import 'package:app/features/device/connect_device_screen.dart';
import 'package:app/features/device/heart_rate_source.dart';
import 'package:app/features/device/simulated_heart_rate_source.dart';
import 'package:app/features/history/heart_rate_detail_screen.dart';
import 'package:app/features/history/measurement_history_screen.dart';
import 'package:app/features/home/home_screen.dart';
import 'package:app/features/insights/ai_insights_dashboard_screen.dart';
import 'package:app/features/measurement/live_measurement_screen.dart';

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

  testWidgets('Render Home Screen for Design Fidelity', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final inMemDb = AppDatabase.inMemory();
    final sessionRepo = SessionRepository(inMemDb);

    // Provide Monday 18:05 session to match design text exactly
    final now = DateTime(2026, 10, 19, 18, 5); // Monday 18:05
    await sessionRepo.insertSession(
      session: SessionRecord(
        id: 'sess-design-home',
        startedAt: now,
        endedAt: now.add(const Duration(seconds: 60)),
        type: SessionType.postActivity,
        qualitySummary: QualitySummary.good,
        source: SessionSource.simulator,
        appVersion: '1.0.0',
      ),
      samples: const [],
      stats: const SessionStatsRecord(
        sessionId: 'sess-design-home',
        meanHr: 74.0,
        stdHr: 3.1,
        minHr: 68.0,
        maxHr: 82.0,
        startHr: 90.0,
        endHr: 72.0,
        recoveryDrop: 18.0,
        pulseIntervalMs: 811.0,
        variabilityEstMs: 41.0,
        validSampleCount: 60,
        totalDurationSeconds: 60,
      ),
      aiResult: AiResultRecord(
        sessionId: 'sess-design-home',
        modelVersion: '1.0.0',
        label: 'Typical pattern',
        featuresJson: '{}',
        createdAt: now,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(inMemDb),
          heartRateSourceProvider.overrideWithValue(SimulatedHeartRateSource()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: HomeScreen(
            onStartMeasure: () {},
            currentNavIndex: 0,
            showBottomNav: true,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../docs/screenshots/Home_app.png'),
    );
  });

  testWidgets('Render Measuring Screen for Design Fidelity', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final recorder = SessionRecorder(
      sessionId: 'sess-design-measuring',
      sessionType: SessionType.postActivity,
      targetDuration: const Duration(seconds: 60),
      source: SessionSource.simulator,
    );
    recorder.start();

    // Pump a few samples with 74 BPM
    recorder.processPacket(
      BlePacket(
        protocolVersion: 1,
        contactDetected: true,
        motionSuspected: false,
        rawBpm: 74.0,
        quality: 90,
        deviceTimestampMs: 9000,
        sequenceNumber: 9,
        receivedAt: DateTime.now(),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: LiveMeasurementScreen(
          recorder: recorder,
          source: SimulatedHeartRateSource(),
          onComplete: (_) {},
          onBack: () {},
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../docs/screenshots/Measuring_app.png'),
    );
  });

  testWidgets('Render Heart Rate Screen for Design Fidelity', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final inMemDb = AppDatabase.inMemory();
    final sessionRepo = SessionRepository(inMemDb);

    final now = DateTime(2026, 10, 19, 18, 5);
    final session = SessionRecord(
      id: 'sess-design-hr',
      startedAt: now,
      endedAt: now.add(const Duration(seconds: 60)),
      type: SessionType.postActivity,
      qualitySummary: QualitySummary.good,
      source: SessionSource.simulator,
      appVersion: '1.0.0',
    );

    await sessionRepo.insertSession(
      session: session,
      samples: const [],
      stats: const SessionStatsRecord(
        sessionId: 'sess-design-hr',
        meanHr: 74.0,
        stdHr: 3.1,
        minHr: 58.0,
        maxHr: 96.0,
        startHr: 90.0,
        endHr: 72.0,
        recoveryDrop: 18.0,
        pulseIntervalMs: 811.0,
        variabilityEstMs: 41.0,
        validSampleCount: 60,
        totalDurationSeconds: 60,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HeartRateDetailScreen(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../docs/screenshots/Heart Rate_app.png'),
    );
  });

  testWidgets('Render AI Insights Screen for Design Fidelity', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final inMemDb = AppDatabase.inMemory();
    final sessionRepo = SessionRepository(inMemDb);

    final now = DateTime(2026, 10, 19, 18, 5);
    final session = SessionRecord(
      id: 'sess-design-insights',
      startedAt: now,
      endedAt: now.add(const Duration(seconds: 60)),
      type: SessionType.postActivity,
      qualitySummary: QualitySummary.good,
      source: SessionSource.simulator,
      appVersion: '1.0.0',
    );

    await sessionRepo.insertSession(
      session: session,
      samples: const [],
      stats: const SessionStatsRecord(
        sessionId: 'sess-design-insights',
        meanHr: 74.0,
        stdHr: 3.1,
        minHr: 58.0,
        maxHr: 96.0,
        startHr: 78.0,
        endHr: 70.0,
        recoveryDrop: -8.0,
        pulseIntervalMs: 811.0,
        variabilityEstMs: 41.0,
        validSampleCount: 60,
        totalDurationSeconds: 60,
      ),
      aiResult: AiResultRecord(
        sessionId: 'sess-design-insights',
        modelVersion: '1.0.0',
        label: 'Typical pattern',
        featuresJson: '{}',
        createdAt: now,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(inMemDb)],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const AiInsightsDashboardScreen(
            currentNavIndex: 2,
            showBottomNav: true,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../docs/screenshots/AI Insights_app.png'),
    );
  });

  testWidgets('Render Connect Device Screen for Design Fidelity', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heartRateSourceProvider.overrideWithValue(SimulatedHeartRateSource()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const ConnectDeviceScreen(
            currentNavIndex: 3,
            showBottomNav: true,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../docs/screenshots/Connect device_app.png'),
    );
  });

  testWidgets('Render History Screen for Design Fidelity', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final inMemDb = AppDatabase.inMemory();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(inMemDb),
          heartRateSourceProvider.overrideWithValue(SimulatedHeartRateSource()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: MeasurementHistoryScreen(
            onBack: () {},
            currentNavIndex: 1,
            showBottomNav: true,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../docs/screenshots/History_app.png'),
    );
  });

  testWidgets('Render App Icon for Design Fidelity', (tester) async {
    tester.view.physicalSize = const Size(360, 360);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF04030C),
          body: Center(child: AppIconWidget(size: 360.0, clipToSquircle: true)),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../docs/screenshots/App icon_app.png'),
    );
  });
}
