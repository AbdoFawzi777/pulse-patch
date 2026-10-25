import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/data/drift/app_database.dart';
import 'package:app/data/repositories/preferences_repository.dart';
import 'package:app/data/repositories/reminder_repository.dart';
import 'package:app/data/repositories/session_repository.dart';
import 'package:app/domain/entities/reminder_record.dart';
import 'package:app/domain/notifications/notification_event.dart';
import 'package:app/domain/notifications/notification_service.dart';
import 'package:app/features/settings/about_screen.dart';
import 'package:app/features/settings/application_settings_screen.dart';
import 'package:app/features/settings/notifications_center_screen.dart';
import 'package:app/features/settings/privacy_data_management_screen.dart';
import 'package:app/features/settings/profile_preferences_screen.dart';
import 'package:app/features/settings/reminder_settings_screen.dart';

void main() {
  late SharedPreferences testPrefs;
  late AppDatabase inMemoryDb;
  late SessionRepository sessionRepo;
  late ReminderRepository reminderRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    testPrefs = await SharedPreferences.getInstance();
    inMemoryDb = AppDatabase.inMemory();
    sessionRepo = SessionRepository(inMemoryDb);
    reminderRepo = ReminderRepository(inMemoryDb);
  });

  group('Phase 10 - NotificationsCenterScreen Tests', () {
    testWidgets(
      'renders category chips and events, allows filtering and clearing',
      (tester) async {
        final container = ProviderContainer();
        final notifier = container.read(notificationServiceProvider.notifier);

        notifier.addEvent(NotificationEvent.deviceConnected('PulsePatch-C3'));
        notifier.addEvent(
          NotificationEvent.measurementCompleted('sess-1', 72, 60),
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: NotificationsCenterScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Notifications'), findsOneWidget);
        expect(find.text('Sensor Connected'), findsOneWidget);
        expect(find.text('Measurement Saved'), findsOneWidget);

        // Tap 'Device' category filter
        await tester.tap(find.text('Device'));
        await tester.pumpAndSettle();

        expect(find.text('Sensor Connected'), findsOneWidget);
        expect(find.text('Measurement Saved'), findsNothing);

        // Tap 'All' category filter
        await tester.tap(find.text('All'));
        await tester.pumpAndSettle();

        expect(find.text('Sensor Connected'), findsOneWidget);
        expect(find.text('Measurement Saved'), findsOneWidget);

        // Tap clear sweep icon
        await tester.tap(find.bySemanticsLabel('Clear All'));
        await tester.pumpAndSettle();

        expect(find.text('No Notifications'), findsOneWidget);
      },
    );
  });

  group('Phase 10 - ReminderSettingsScreen Tests', () {
    testWidgets('renders disclaimer and lists reminders', (tester) async {
      await reminderRepo.insertReminder(
        const ReminderRecord(
          id: 1,
          hour: 8,
          minute: 30,
          label: 'Morning Pulse',
          isEnabled: true,
          daysOfWeek: [1, 2, 3, 4, 5],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reminderRepositoryProvider.overrideWithValue(reminderRepo),
          ],
          child: const MaterialApp(home: ReminderSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reminder Settings'), findsOneWidget);
      expect(find.text('No Background Monitoring'), findsOneWidget);
      expect(find.text('08:30'), findsOneWidget);
      expect(find.text('Morning Pulse'), findsOneWidget);

      // Toggle switch
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      final updated = reminderRepo.getAllReminders();
      expect(updated.first.isEnabled, isFalse);
    });
  });

  group('Phase 10 - ProfilePreferencesScreen Tests', () {
    testWidgets('allows editing profile name and changing units', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final prefsRepo = PreferencesRepository(testPrefs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesRepositoryProvider.overrideWithValue(prefsRepo),
          ],
          child: const MaterialApp(home: ProfilePreferencesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profile & Preferences'), findsOneWidget);

      // Enter name
      await tester.enterText(find.byType(TextField), 'Samir');
      await tester.pumpAndSettle();

      // Change units to ms
      await tester.tap(find.text('Interval (ms)'));
      await tester.pumpAndSettle();

      // Tap save
      await tester.tap(find.text('Save Preferences'));
      await tester.pumpAndSettle();

      expect(prefsRepo.userName, equals('Samir'));
      expect(prefsRepo.useBpmUnits, isFalse);
    });
  });

  group('Phase 10 - ApplicationSettingsScreen Tests', () {
    testWidgets('toggles auto-reconnect and duration', (tester) async {
      final prefsRepo = PreferencesRepository(testPrefs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesRepositoryProvider.overrideWithValue(prefsRepo),
          ],
          child: const MaterialApp(home: ApplicationSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Hardware & Bluetooth'), findsOneWidget);
      expect(find.text('Auto-Reconnect'), findsOneWidget);

      // Change duration to 90s
      await tester.tap(find.text('90s'));
      await tester.pumpAndSettle();

      expect(prefsRepo.measurementDurationSeconds, equals(90));
    });
  });

  group('Phase 10 - PrivacyDataManagementScreen Tests', () {
    testWidgets('displays offline metrics and triggers confirmation dialog', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sessionRepositoryProvider.overrideWithValue(sessionRepo)],
          child: const MaterialApp(home: PrivacyDataManagementScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Privacy & Data'), findsOneWidget);
      expect(find.text('Zero Data Leaves This Phone'), findsOneWidget);
      expect(find.text('0 active (Offline)'), findsOneWidget);

      // Tap Erase All Data
      await tester.tap(find.text('Erase All Data'));
      await tester.pumpAndSettle();

      expect(find.text('Erase All Data?'), findsOneWidget);
      expect(find.text('Erase Everything'), findsOneWidget);

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Erase All Data?'), findsNothing);
    });
  });

  group('Phase 10 - AboutScreen Tests', () {
    testWidgets(
      'displays graduation project context, hardware specs, and disclaimer',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
        await tester.pumpAndSettle();

        expect(find.text('About'), findsOneWidget);
        expect(find.text('PulsePatch Lite'), findsOneWidget);
        expect(find.text('Academic Capstone Project'), findsOneWidget);
        expect(
          find.text('Espressif ESP32-C3 RISC-V (160 MHz)'),
          findsOneWidget,
        );
        expect(find.text('Maxim Integrated MAX30102 PPG'), findsOneWidget);
        expect(find.text('Non-Diagnostic Scope'), findsOneWidget);
        expect(
          find.textContaining(
            'educational prototype and does not provide medical diagnosis',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
