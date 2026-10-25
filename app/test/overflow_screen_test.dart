import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/data/repositories/preferences_repository.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/data/drift/app_database.dart';
import 'package:app/data/repositories/session_repository.dart';
import 'package:app/domain/entities/session_stats_record.dart';
import 'package:app/domain/signal/session_recorder.dart';
import 'package:app/features/device/connect_device_screen.dart';
import 'package:app/features/device/heart_rate_source.dart';
import 'package:app/features/device/simulated_heart_rate_source.dart';
import 'package:app/features/history/measurement_history_screen.dart';
import 'package:app/features/home/home_screen.dart';
import 'package:app/features/insights/ai_insights_dashboard_screen.dart';
import 'package:app/features/measurement/live_measurement_screen.dart';
import 'package:app/features/measurement/measurement_complete_screen.dart';
import 'package:app/features/measurement/measurement_preparation_screen.dart';
import 'package:app/features/settings/application_settings_screen.dart';

Widget _buildScreenHarness({
  required Widget child,
  required Size size,
  required double textScale,
  AppDatabase? db,
  HeartRateSource? source,
  SharedPreferences? prefs,
}) {
  final inMemDb = db ?? AppDatabase.inMemory();
  final simSource = source ?? SimulatedHeartRateSource();

  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(inMemDb),
      heartRateSourceProvider.overrideWithValue(simSource),
      if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: const EdgeInsets.only(top: 39.0, bottom: 22.0),
          textScaler: TextScaler.linear(textScale),
        ),
        child: SizedBox(width: size.width, height: size.height, child: child),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences testPrefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    testPrefs = await SharedPreferences.getInstance();

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

  const testResolutions = [
    Size(360.0, 800.0), // Real phone (HONOR NIC-LX2)
    Size(390.0, 844.0), // Baseline Artboard
    Size(411.0, 891.0), // Large phone
  ];

  const testScales = [1.0, 1.3];

  const sampleStats = SessionStatsRecord(
    sessionId: 'test-session',
    meanHr: 72.0,
    stdHr: 2.5,
    minHr: 65.0,
    maxHr: 84.0,
    startHr: 70.0,
    endHr: 72.0,
    pulseIntervalMs: 833.0,
    variabilityEstMs: 42.0,
    validSampleCount: 60,
    totalDurationSeconds: 60,
  );

  for (final size in testResolutions) {
    for (final scale in testScales) {
      final label = '${size.width.toInt()}x${size.height.toInt()} scale $scale';

      testWidgets('ConnectDeviceScreen does not overflow at $label', (
        tester,
      ) async {
        final overflows = <String>[];
        final prevOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.toString().contains('overflowed') ||
              details.toString().contains('RenderFlex')) {
            overflows.add(details.exceptionAsString());
          }
          prevOnError?.call(details);
        };

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          FlutterError.onError = prevOnError;
        });

        await tester.pumpWidget(
          _buildScreenHarness(
            child: const ConnectDeviceScreen(),
            size: size,
            textScale: scale,
            prefs: testPrefs,
          ),
        );
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();

        expect(
          overflows,
          isEmpty,
          reason:
              'Layout overflow on ConnectDeviceScreen at $label: $overflows',
        );
      });

      testWidgets('HomeScreen does not overflow at $label', (tester) async {
        final overflows = <String>[];
        final prevOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.toString().contains('overflowed') ||
              details.toString().contains('RenderFlex')) {
            overflows.add(details.exceptionAsString());
          }
          prevOnError?.call(details);
        };

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          FlutterError.onError = prevOnError;
        });

        await tester.pumpWidget(
          _buildScreenHarness(
            child: HomeScreen(onStartMeasure: () {}),
            size: size,
            textScale: scale,
            prefs: testPrefs,
          ),
        );
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();

        expect(
          overflows,
          isEmpty,
          reason: 'Layout overflow on HomeScreen at $label: $overflows',
        );
      });

      testWidgets('MeasurementPreparationScreen does not overflow at $label', (
        tester,
      ) async {
        final overflows = <String>[];
        final prevOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.toString().contains('overflowed') ||
              details.toString().contains('RenderFlex')) {
            overflows.add(details.exceptionAsString());
          }
          prevOnError?.call(details);
        };

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          FlutterError.onError = prevOnError;
        });

        await tester.pumpWidget(
          _buildScreenHarness(
            child: MeasurementPreparationScreen(
              onStart: (type, duration) {},
              onBack: () {},
            ),
            size: size,
            textScale: scale,
            prefs: testPrefs,
          ),
        );
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();

        expect(
          overflows,
          isEmpty,
          reason:
              'Layout overflow on MeasurementPreparationScreen at $label: $overflows',
        );
      });

      testWidgets('LiveMeasurementScreen does not overflow at $label', (
        tester,
      ) async {
        final overflows = <String>[];
        final prevOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.toString().contains('overflowed') ||
              details.toString().contains('RenderFlex')) {
            overflows.add(details.exceptionAsString());
          }
          prevOnError?.call(details);
        };

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          FlutterError.onError = prevOnError;
        });

        final recorder = SessionRecorder(
          sessionId: 'ov-test',
          targetDuration: const Duration(seconds: 60),
        );
        final sim = SimulatedHeartRateSource(baseBpm: 74.0);

        await tester.pumpWidget(
          _buildScreenHarness(
            child: LiveMeasurementScreen(
              recorder: recorder,
              source: sim,
              onComplete: (_) {},
              onBack: () {},
            ),
            source: sim,
            size: size,
            textScale: scale,
            prefs: testPrefs,
          ),
        );
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();

        expect(
          overflows,
          isEmpty,
          reason:
              'Layout overflow on LiveMeasurementScreen at $label: $overflows',
        );
      });

      testWidgets('MeasurementCompleteScreen does not overflow at $label', (
        tester,
      ) async {
        final overflows = <String>[];
        final prevOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.toString().contains('overflowed') ||
              details.toString().contains('RenderFlex')) {
            overflows.add(details.exceptionAsString());
          }
          prevOnError?.call(details);
        };

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          FlutterError.onError = prevOnError;
        });

        await tester.pumpWidget(
          _buildScreenHarness(
            child: MeasurementCompleteScreen(
              stats: sampleStats,
              onSave: () {},
              onDiscard: () {},
              onViewInsights: () {},
              onBack: () {},
            ),
            size: size,
            textScale: scale,
            prefs: testPrefs,
          ),
        );
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();

        expect(
          overflows,
          isEmpty,
          reason:
              'Layout overflow on MeasurementCompleteScreen at $label: $overflows',
        );
      });

      testWidgets('AiInsightsDashboardScreen does not overflow at $label', (
        tester,
      ) async {
        final overflows = <String>[];
        final prevOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.toString().contains('overflowed') ||
              details.toString().contains('RenderFlex')) {
            overflows.add(details.exceptionAsString());
          }
          prevOnError?.call(details);
        };

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          FlutterError.onError = prevOnError;
        });

        await tester.pumpWidget(
          _buildScreenHarness(
            child: const AiInsightsDashboardScreen(),
            size: size,
            textScale: scale,
            prefs: testPrefs,
          ),
        );
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();

        expect(
          overflows,
          isEmpty,
          reason:
              'Layout overflow on AiInsightsDashboardScreen at $label: $overflows',
        );
      });

      testWidgets('MeasurementHistoryScreen does not overflow at $label', (
        tester,
      ) async {
        final overflows = <String>[];
        final prevOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.toString().contains('overflowed') ||
              details.toString().contains('RenderFlex')) {
            overflows.add(details.exceptionAsString());
          }
          prevOnError?.call(details);
        };

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          FlutterError.onError = prevOnError;
        });

        await tester.pumpWidget(
          _buildScreenHarness(
            child: MeasurementHistoryScreen(
              onBack: () {},
              onSelectSession: (_) {},
            ),
            size: size,
            textScale: scale,
            prefs: testPrefs,
          ),
        );
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();

        expect(
          overflows,
          isEmpty,
          reason:
              'Layout overflow on MeasurementHistoryScreen at $label: $overflows',
        );
      });

      testWidgets('ApplicationSettingsScreen does not overflow at $label', (
        tester,
      ) async {
        final overflows = <String>[];
        final prevOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.toString().contains('overflowed') ||
              details.toString().contains('RenderFlex')) {
            overflows.add(details.exceptionAsString());
          }
          prevOnError?.call(details);
        };

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          FlutterError.onError = prevOnError;
        });

        await tester.pumpWidget(
          _buildScreenHarness(
            child: const ApplicationSettingsScreen(),
            size: size,
            textScale: scale,
            prefs: testPrefs,
          ),
        );
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();

        expect(
          overflows,
          isEmpty,
          reason:
              'Layout overflow on ApplicationSettingsScreen at $label: $overflows',
        );
      });
    }
  }
}
