import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/data/drift/app_database.dart';
import 'package:app/data/repositories/preferences_repository.dart';
import 'package:app/data/repositories/session_repository.dart';
import 'package:app/domain/entities/ai_result_record.dart';
import 'package:app/domain/entities/session_record.dart';
import 'package:app/domain/entities/session_stats_record.dart';
import 'package:app/domain/signal/session_recorder.dart';
import 'package:app/features/device/connect_device_screen.dart';
import 'package:app/features/device/device_troubleshooting_screen.dart';
import 'package:app/features/device/heart_rate_source.dart';
import 'package:app/features/device/simulated_heart_rate_source.dart';
import 'package:app/features/device/standard_ble_heart_rate_source.dart';
import 'package:app/features/history/heart_rate_detail_screen.dart';
import 'package:app/features/history/measurement_history_screen.dart';
import 'package:app/features/history/session_details_screen.dart';
import 'package:app/features/home/home_screen.dart';
import 'package:app/features/insights/ai_insights_dashboard_screen.dart';
import 'package:app/features/insights/ai_model_info_screen.dart';
import 'package:app/features/insights/session_pattern_analysis_screen.dart';
import 'package:app/features/measurement/live_measurement_screen.dart';
import 'package:app/features/measurement/measurement_complete_screen.dart';
import 'package:app/features/measurement/measurement_preparation_screen.dart';
import 'package:app/features/onboarding/how_it_works_screen.dart';
import 'package:app/features/onboarding/permissions_screen.dart';
import 'package:app/features/onboarding/splash_screen.dart';
import 'package:app/features/onboarding/user_preferences_screen.dart';
import 'package:app/features/onboarding/welcome_screen.dart';
import 'package:app/features/reports/historical_trends_screen.dart';
import 'package:app/features/reports/recovery_analysis_screen.dart';
import 'package:app/features/reports/reports_screen.dart';
import 'package:app/features/settings/about_screen.dart';
import 'package:app/features/settings/application_settings_screen.dart';
import 'package:app/features/settings/notifications_center_screen.dart';
import 'package:app/features/settings/privacy_data_management_screen.dart';
import 'package:app/features/settings/profile_preferences_screen.dart';
import 'package:app/features/settings/reminder_settings_screen.dart';
import 'package:app/shared/widgets/app_icon_widget.dart';

Widget _buildScreenHarness({
  required Widget child,
  required Size size,
  required double textScale,
  required AppDatabase db,
  HeartRateSource? source,
  required SharedPreferences prefs,
}) {
  final simSource = source ?? SimulatedHeartRateSource();

  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      heartRateSourceProvider.overrideWithValue(simSource),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
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
  late AppDatabase sharedDb;

  final sampleSession = SessionRecord(
    id: 'test-session',
    startedAt: DateTime(2026, 10, 26, 14, 0),
    endedAt: DateTime(2026, 10, 26, 14, 1, 30),
    type: SessionType.postActivity,
    qualitySummary: QualitySummary.good,
    appVersion: '1.0.0',
    source: SessionSource.standardBle,
  );

  const sampleStats = SessionStatsRecord(
    sessionId: 'test-session',
    meanHr: 76.4,
    stdHr: 3.5,
    minHr: 73.0,
    maxHr: 85.0,
    startHr: 84.0,
    endHr: 74.0,
    recoveryDrop: 9.0,
    pulseIntervalMs: 785.0,
    variabilityEstMs: 4.6,
    validSampleCount: 95,
    totalDurationSeconds: 90,
  );

  final sampleAiResult = AiResultRecord(
    sessionId: 'test-session',
    modelVersion: '1.0.0',
    label: 'Different pattern',
    featuresJson: '{"recovery_drop": 9.0, "mean_hr": 76.4}',
    createdAt: DateTime(2026, 10, 26, 14, 1, 31),
  );

  const sampleDevice = DiscoveredBleDevice(
    id: 'AA:BB:CC:DD:EE:FF',
    name: 'PulsePatch-SimHR',
    rssi: -58,
    advertisedServices: ['0000180d-0000-1000-8000-00805f9b34fb'],
  );

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

    sharedDb = AppDatabase.inMemory();
    final repo = SessionRepository(sharedDb);
    await repo.insertSession(
      session: sampleSession,
      samples: const [],
      stats: sampleStats,
      aiResult: sampleAiResult,
    );
  });

  const testResolutions = [
    Size(360.0, 800.0), // Real physical target (HONOR NIC-LX2)
    Size(390.0, 844.0), // Baseline Artboard
    Size(411.0, 891.0), // Large target phone
  ];

  const testScales = [1.0, 1.3];

  final testSurfaces = <({String name, Widget Function(HeartRateSource simSource) builder})>[
    (name: 'SplashScreen', builder: (_) => const SplashScreen(autoNavigate: false)),
    (name: 'WelcomeScreen', builder: (_) => WelcomeScreen(onGetStarted: () {})),
    (name: 'HowItWorksScreen', builder: (_) => HowItWorksScreen(onContinue: () {}, onBack: () {})),
    (name: 'UserPreferencesScreen', builder: (_) => UserPreferencesScreen(onNext: () {}, onBack: () {})),
    (name: 'PermissionsScreen', builder: (_) => PermissionsScreen(onFinish: () {}, onBack: () {})),
    (name: 'HomeScreen', builder: (_) => HomeScreen(onStartMeasure: () {})),
    (name: 'ConnectDeviceScreen', builder: (_) => const ConnectDeviceScreen()),
    (name: 'DeviceTroubleshootingScreen', builder: (_) => const DeviceTroubleshootingScreen()),
    (name: 'MeasurementPreparationScreen', builder: (_) => MeasurementPreparationScreen(onStart: (t, d) {}, onBack: () {})),
    (
      name: 'LiveMeasurementScreen (Sim)',
      builder: (source) => LiveMeasurementScreen(
        recorder: SessionRecorder(sessionId: 'ov-test', targetDuration: const Duration(seconds: 60)),
        source: source,
        onComplete: (_) {},
        onBack: () {},
      ),
    ),
    (
      name: 'LiveMeasurementScreen (BLE)',
      builder: (_) => LiveMeasurementScreen(
        recorder: SessionRecorder(sessionId: 'ov-ble', targetDuration: const Duration(seconds: 60)),
        source: StandardBleHeartRateSource(),
        onComplete: (_) {},
        onBack: () {},
      ),
    ),
    (
      name: 'MeasurementCompleteScreen',
      builder: (_) => MeasurementCompleteScreen(
        stats: sampleStats,
        onSave: () {},
        onDiscard: () {},
        onViewInsights: () {},
        onBack: () {},
      ),
    ),
    (name: 'HeartRateDetailScreen', builder: (_) => const HeartRateDetailScreen()),
    (name: 'AiInsightsDashboardScreen', builder: (_) => const AiInsightsDashboardScreen()),
    (name: 'SessionPatternAnalysisScreen', builder: (_) => const SessionPatternAnalysisScreen(sessionId: 'test-session')),
    (name: 'RecoveryAnalysisScreen', builder: (_) => RecoveryAnalysisScreen(session: sampleSession, stats: sampleStats, onBack: () {})),
    (name: 'HistoricalTrendsScreen', builder: (_) => HistoricalTrendsScreen(onBack: () {})),
    (name: 'AiModelInfoScreen', builder: (_) => const AiModelInfoScreen()),
    (name: 'MeasurementHistoryScreen', builder: (_) => MeasurementHistoryScreen(onBack: () {}, onSelectSession: (_) {})),
    (name: 'SessionDetailsScreen', builder: (_) => SessionDetailsScreen(session: sampleSession, onBack: () {})),
    (name: 'ReportsScreen', builder: (_) => ReportsScreen(onBack: () {})),
    (name: 'ProfilePreferencesScreen', builder: (_) => const ProfilePreferencesScreen()),
    (name: 'ApplicationSettingsScreen', builder: (_) => const ApplicationSettingsScreen()),
    (name: 'NotificationsCenterScreen', builder: (_) => const NotificationsCenterScreen()),
    (name: 'ReminderSettingsScreen', builder: (_) => const ReminderSettingsScreen()),
    (name: 'PrivacyDataManagementScreen', builder: (_) => const PrivacyDataManagementScreen()),
    (name: 'AboutScreen', builder: (_) => const AboutScreen()),
    (name: 'AppIconWidget', builder: (_) => const Center(child: AppIconWidget(size: 360.0, clipToSquircle: true))),
    (name: 'DeviceDetailBottomSheet', builder: (_) => const DeviceDetailBottomSheet(device: sampleDevice)),
  ];

  for (final surface in testSurfaces) {
    for (final size in testResolutions) {
      for (final scale in testScales) {
        final label = '${surface.name} at ${size.width.toInt()}x${size.height.toInt()} scale $scale';

        testWidgets(label, (tester) async {
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

          final sim = SimulatedHeartRateSource(baseBpm: 74.0);

          await tester.pumpWidget(
            _buildScreenHarness(
              child: surface.builder(sim),
              size: size,
              textScale: scale,
              db: sharedDb,
              source: sim,
              prefs: testPrefs,
            ),
          );
          await tester.pump(const Duration(milliseconds: 700));
          if (surface.name != 'SplashScreen') {
            await tester.pumpAndSettle();
          }

          expect(
            overflows,
            isEmpty,
            reason: 'Layout overflow on $label: $overflows',
          );
        });
      }
    }
  }
}
