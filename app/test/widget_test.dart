import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/data/drift/app_database.dart';
import 'package:app/data/repositories/preferences_repository.dart';
import 'package:app/data/repositories/session_repository.dart';
import 'package:app/features/device/heart_rate_source.dart';
import 'package:app/features/device/simulated_heart_rate_source.dart';
import 'package:app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late AppDatabase db;
  late SimulatedHeartRateSource sim;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'is_onboarding_completed': true});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.inMemory();
    sim = SimulatedHeartRateSource();
  });

  tearDown(() {
    db.close();
    sim.dispose();
  });

  testWidgets('App launches with themed shell smoke test', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          heartRateSourceProvider.overrideWithValue(sim),
        ],
        child: const PulsePatchApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hi, there!'), findsOneWidget);
    expect(find.text('How are you today?'), findsOneWidget);
  });

  testWidgets('Themed shell renders correctly in Arabic RTL locale', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          heartRateSourceProvider.overrideWithValue(sim),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          home: ThemedShellScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ThemedShellScreen), findsOneWidget);
  });
}
