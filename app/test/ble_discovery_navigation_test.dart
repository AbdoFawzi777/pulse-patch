import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/data/drift/app_database.dart';
import 'package:app/data/repositories/preferences_repository.dart';
import 'package:app/data/repositories/session_repository.dart';
import 'package:app/features/home/home_screen.dart';
import 'package:app/features/history/measurement_history_screen.dart';
import 'package:app/features/device/connect_device_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences testPrefs;
  late AppDatabase inMemDb;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    testPrefs = await SharedPreferences.getInstance();
    inMemDb = AppDatabase.inMemory();
  });

  tearDown(() {
    inMemDb.close();
  });

  group('BLE Discovery Navigation Tests', () {
    testWidgets(
        'HomeScreen renders prominent device connection card and triggers onOpenDevice',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool opened = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(inMemDb),
            sharedPreferencesProvider.overrideWithValue(testPrefs),
          ],
          child: MaterialApp(
            home: HomeScreen(
              onStartMeasure: () {},
              onOpenDevice: () => opened = true,
              showBottomNav: false,
            ),
          ),
        ),
      );

      final cardFinder = find.byKey(const Key('home_device_connection_card'));
      expect(cardFinder, findsOneWidget);
      expect(find.text('Connect PulsePatch Device'), findsOneWidget);

      await tester.tap(cardFinder);
      await tester.pump();
      expect(opened, isTrue);
    });

    testWidgets(
        'MeasurementHistoryScreen renders prominent connection banner when disconnected',
        (tester) async {
      bool opened = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(inMemDb),
            sharedPreferencesProvider.overrideWithValue(testPrefs),
          ],
          child: MaterialApp(
            home: MeasurementHistoryScreen(
              onBack: () {},
              onOpenDevice: () => opened = true,
              showBottomNav: false,
            ),
          ),
        ),
      );

      final cardFinder = find.byKey(const Key('monitoring_connect_device_card'));
      expect(cardFinder, findsOneWidget);
      expect(find.text('PulsePatch Sensor Not Connected'), findsOneWidget);

      await tester.tap(find.text('Connect'));
      await tester.pump();
      expect(opened, isTrue);
    });

    testWidgets(
        'ConnectDeviceScreen renders prominent BLE scan toggle button and scanner header',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(inMemDb),
            sharedPreferencesProvider.overrideWithValue(testPrefs),
          ],
          child: const MaterialApp(
            home: ConnectDeviceScreen(
              showBottomNav: false,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('ble_scan_toggle_button')), findsOneWidget);
      expect(find.text('Start BLE Scan'), findsOneWidget);
      expect(find.text('Connect device'), findsOneWidget);
    });
  });
}
