import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/data/drift/app_database.dart';
import 'package:app/data/repositories/preferences_repository.dart';
import 'package:app/data/repositories/session_repository.dart';
import 'package:app/domain/entities/ai_result_record.dart';
import 'package:app/domain/entities/session_record.dart';
import 'package:app/domain/entities/session_stats_record.dart';
import 'package:app/domain/ml/ai_inference_service.dart';
import 'package:app/domain/signal/ble_packet.dart';
import 'package:app/domain/signal/session_recorder.dart';
import 'package:app/features/device/device_troubleshooting_screen.dart';
import 'package:app/features/device/heart_rate_source.dart';
import 'package:app/features/device/simulated_heart_rate_source.dart';
import 'package:app/features/history/measurement_history_screen.dart';
import 'package:app/features/history/session_details_screen.dart';
import 'package:app/features/home/home_screen.dart';
import 'package:app/features/home/widgets/layered_heart_widget.dart';
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
import 'package:app/shared/widgets/ble_device_card.dart';
import 'package:app/shared/widgets/circle_icon_button.dart';

class FakeRealBleSource implements HeartRateSource {
  final _connectionStateController =
      StreamController<BleConnectionState>.broadcast();
  final _discoveredDevicesController =
      StreamController<List<DiscoveredBleDevice>>.broadcast();
  final _packetController = StreamController<BlePacket>.broadcast();
  final _diagnosticsController =
      StreamController<PacketDiagnostics>.broadcast();
  final _waveformController = StreamController<double>.broadcast();

  @override
  Stream<BleConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  @override
  Stream<List<DiscoveredBleDevice>> get discoveredDevicesStream =>
      _discoveredDevicesController.stream;
  @override
  Stream<BlePacket> get packetStream => _packetController.stream;
  @override
  Stream<PacketDiagnostics> get diagnosticsStream =>
      _diagnosticsController.stream;
  @override
  Stream<double> get opticalWaveformStream => _waveformController.stream;
  @override
  BleConnectionState get currentState => BleConnectionState.connected;
  @override
  PacketDiagnostics get currentDiagnostics => const PacketDiagnostics();
  @override
  bool get isSimulator => false;
  @override
  String get sourceLabel => 'ESP32-C3 BLE';
  @override
  Future<void> startScan() async {}
  @override
  Future<void> stopScan() async {}
  @override
  Future<void> connect(String deviceId) async {}
  @override
  Future<void> disconnect() async {}
  @override
  void dispose() {}
}

Widget _wrapScreen(
  Widget child, {
  AppDatabase? db,
  HeartRateSource? source,
  PreferencesRepository? prefsRepo,
}) {
  final inMemDb = db ?? AppDatabase.inMemory();
  final simSource = source ?? SimulatedHeartRateSource();

  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(inMemDb),
      heartRateSourceProvider.overrideWithValue(simSource),
      if (prefsRepo != null)
        preferencesRepositoryProvider.overrideWithValue(prefsRepo),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late PreferencesRepository prefsRepo;
  late SessionRecord sampleSession;
  late SessionStatsRecord sampleStats;
  late AiResultRecord sampleAiResult;
  late AiInferenceResult sampleInference;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'user_name': 'Sarah'});
    final prefs = await SharedPreferences.getInstance();
    prefsRepo = PreferencesRepository(prefs);
    db = AppDatabase.inMemory();

    final now = DateTime(2026, 10, 24, 14, 30);
    sampleSession = SessionRecord(
      id: 'sess-test-001',
      startedAt: now.subtract(const Duration(seconds: 60)),
      endedAt: now,
      type: SessionType.postActivity,
      qualitySummary: QualitySummary.good,
      source: SessionSource.simulator,
      appVersion: '1.0.0',
    );

    sampleStats = const SessionStatsRecord(
      sessionId: 'sess-test-001',
      meanHr: 72.4,
      stdHr: 3.2,
      minHr: 68.0,
      maxHr: 78.0,
      startHr: 95.0,
      endHr: 73.0,
      recoveryDrop: 21.6,
      pulseIntervalMs: 828.0,
      variabilityEstMs: 41.0,
      validSampleCount: 58,
      totalDurationSeconds: 60,
    );

    sampleAiResult = AiResultRecord(
      sessionId: 'sess-test-001',
      modelVersion: '1.0.0',
      label: 'Typical pattern',
      featuresJson:
          '{"mean_hr": 72.4, "std_hr": 3.2, "start_hr": 95.0, "end_hr": 73.0, "recovery_drop": 21.6}',
      createdAt: now,
    );

    sampleInference = AiInferenceResult(
      label: 'Typical pattern',
      explanation:
          'Your heart rate recovery demonstrates standard deceleration following activity.',
      comparisonText: 'Consistent with your historical baseline.',
      features: const {
        'mean_hr': 72.4,
        'std_hr': 3.2,
        'start_hr': 95.0,
        'end_hr': 73.0,
        'recovery_drop': 21.6,
      },
      scaledFeatures: const {
        'mean_hr': -0.75,
        'std_hr': -1.02,
        'start_hr': -0.01,
        'end_hr': -0.50,
        'recovery_drop': 0.82,
      },
      modelVersion: '1.0.0',
      inferredAt: now,
    );

    final sessionRepo = SessionRepository(db);
    await sessionRepo.insertSession(
      session: sampleSession,
      samples: const [],
      stats: sampleStats,
      aiResult: sampleAiResult,
    );
  });

  Future<void> renderAndCapture(
    WidgetTester tester,
    Widget widget,
    String filename, {
    AppDatabase? database,
    HeartRateSource? source,
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      _wrapScreen(
        widget,
        db: database ?? db,
        source: source,
        prefsRepo: prefsRepo,
      ),
    );

    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 600));
    }

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../docs/screenshots/$filename'),
    );
  }

  group('PulsePatch Lite 27 Screen Screenshot Suite', () {
    testWidgets('01_splash', (tester) async {
      await renderAndCapture(
        tester,
        const SplashScreen(autoNavigate: false),
        '01_splash.png',
        settle: false,
      );
    });

    testWidgets('02_welcome', (tester) async {
      await renderAndCapture(
        tester,
        WelcomeScreen(onGetStarted: () {}),
        '02_welcome.png',
      );
    });

    testWidgets('03_how_it_works', (tester) async {
      await renderAndCapture(
        tester,
        HowItWorksScreen(onContinue: () {}, onBack: () {}),
        '03_how_it_works.png',
      );
    });

    testWidgets('04_user_preferences', (tester) async {
      await renderAndCapture(
        tester,
        UserPreferencesScreen(onNext: () {}, onBack: () {}),
        '04_user_preferences.png',
      );
    });

    testWidgets('05_permissions', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('flutter.baseflow.com/permissions/methods'),
            (call) async => 1,
          );
      await renderAndCapture(
        tester,
        PermissionsScreen(onFinish: () {}, onBack: () {}),
        '05_permissions.png',
      );
    });

    testWidgets('06_home', (tester) async {
      await renderAndCapture(
        tester,
        HomeScreen(onStartMeasure: () {}, onOpenDevice: () {}),
        '06_home.png',
      );
    });

    testWidgets('07_connect_device', (tester) async {
      final connectDeviceWidget = Scaffold(
        backgroundColor: AppColors.bgBase,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleIconButton(
                      icon: Icons.chevron_left_rounded,
                      onPressed: () {},
                    ),
                    const Expanded(
                      child: Text(
                        'Connect device',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 22.0,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 56.0),
                  ],
                ),
                const SizedBox(height: 24.0),
                BleDeviceCard(
                  name: 'PulsePatch-C3 (Simulated)',
                  rssi: -62,
                  isConnected: true,
                  onConnect: () {},
                ),
                const SizedBox(height: 14.0),
                BleDeviceCard(
                  name: 'PulsePatch-C3 (Hardware #084)',
                  rssi: -78,
                  isConnected: false,
                  onConnect: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await renderAndCapture(
        tester,
        connectDeviceWidget,
        '07_connect_device.png',
      );
    });

    testWidgets('08_device_troubleshooting', (tester) async {
      await renderAndCapture(
        tester,
        const DeviceTroubleshootingScreen(),
        '08_device_troubleshooting.png',
      );
    });

    testWidgets('09_measurement_prep', (tester) async {
      await renderAndCapture(
        tester,
        MeasurementPreparationScreen(
          onStart: (type, duration) {},
          onBack: () {},
        ),
        '09_measurement_prep.png',
      );
    });

    testWidgets('10_live_measuring_simulator', (tester) async {
      final simSource = SimulatedHeartRateSource();
      final recorder = SessionRecorder(
        sessionId: 'sess-live-sim',
        source: SessionSource.simulator,
      );
      await renderAndCapture(
        tester,
        LiveMeasurementScreen(
          recorder: recorder,
          source: simSource,
          onComplete: (_) {},
          onBack: () {},
        ),
        '10_live_measuring_simulator.png',
        source: simSource,
      );
    });

    testWidgets('11_live_measuring_real_device', (tester) async {
      final fakeBleSource = FakeRealBleSource();
      final recorder = SessionRecorder(
        sessionId: 'sess-live-ble',
        source: SessionSource.device,
      );
      await renderAndCapture(
        tester,
        LiveMeasurementScreen(
          recorder: recorder,
          source: fakeBleSource,
          onComplete: (_) {},
          onBack: () {},
        ),
        '11_live_measuring_real_device.png',
        source: fakeBleSource,
      );
    });

    testWidgets('12_heart_rate_summary', (tester) async {
      await renderAndCapture(
        tester,
        MeasurementCompleteScreen(
          stats: sampleStats,
          isSampleData: true,
          onSave: () {},
          onDiscard: () {},
          onViewInsights: () {},
          onBack: () {},
        ),
        '12_heart_rate_summary.png',
      );
    });

    testWidgets('13_ai_insights_dashboard', (tester) async {
      await renderAndCapture(
        tester,
        const AiInsightsDashboardScreen(),
        '13_ai_insights_dashboard.png',
      );
    });

    testWidgets('14_session_pattern_analysis', (tester) async {
      await renderAndCapture(
        tester,
        SessionPatternAnalysisScreen(
          sessionId: 'sess-test-001',
          initialResult: sampleInference,
        ),
        '14_session_pattern_analysis.png',
      );
    });

    testWidgets('15_recovery_analysis', (tester) async {
      await renderAndCapture(
        tester,
        RecoveryAnalysisScreen(
          session: sampleSession,
          stats: sampleStats,
          onBack: () {},
        ),
        '15_recovery_analysis.png',
      );
    });

    testWidgets('16_historical_trends', (tester) async {
      await renderAndCapture(
        tester,
        HistoricalTrendsScreen(onBack: () {}),
        '16_historical_trends.png',
      );
    });

    testWidgets('17_ai_model_info', (tester) async {
      await renderAndCapture(
        tester,
        const AiModelInfoScreen(),
        '17_ai_model_info.png',
      );
    });

    testWidgets('18_history', (tester) async {
      await renderAndCapture(
        tester,
        MeasurementHistoryScreen(onBack: () {}, onSelectSession: (_) {}),
        '18_history.png',
      );
    });

    testWidgets('19_session_details', (tester) async {
      await renderAndCapture(
        tester,
        SessionDetailsScreen(
          session: sampleSession,
          onBack: () {},
          onDeleted: () {},
        ),
        '19_session_details.png',
      );
    });

    testWidgets('20_reports', (tester) async {
      await renderAndCapture(
        tester,
        ReportsScreen(onBack: () {}),
        '20_reports.png',
      );
    });

    testWidgets('21_profile_preferences', (tester) async {
      await renderAndCapture(
        tester,
        const ProfilePreferencesScreen(),
        '21_profile_preferences.png',
      );
    });

    testWidgets('22_application_settings', (tester) async {
      await renderAndCapture(
        tester,
        const ApplicationSettingsScreen(),
        '22_application_settings.png',
      );
    });

    testWidgets('23_notifications_center', (tester) async {
      await renderAndCapture(
        tester,
        const NotificationsCenterScreen(),
        '23_notifications_center.png',
      );
    });

    testWidgets('24_reminder_settings', (tester) async {
      await renderAndCapture(
        tester,
        const ReminderSettingsScreen(),
        '24_reminder_settings.png',
      );
    });

    testWidgets('25_privacy_data', (tester) async {
      await renderAndCapture(
        tester,
        const PrivacyDataManagementScreen(),
        '25_privacy_data.png',
      );
    });

    testWidgets('26_about', (tester) async {
      await renderAndCapture(tester, const AboutScreen(), '26_about.png');
    });

    testWidgets('27_app_icon', (tester) async {
      final appIconWidget = Scaffold(
        backgroundColor: AppColors.bgBase,
        body: Center(
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D183A), Color(0xFF030712)],
              ),
              borderRadius: BorderRadius.circular(48.0),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentBlue.withValues(alpha: 0.35),
                  blurRadius: 32.0,
                  spreadRadius: 4.0,
                ),
              ],
            ),
            child: const Center(
              child: LayeredHeartWidget(width: 160.0, height: 160.0),
            ),
          ),
        ),
      );
      await renderAndCapture(tester, appIconWidget, '27_app_icon.png');
    });
  });
}
