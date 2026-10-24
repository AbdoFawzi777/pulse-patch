import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/data/repositories/preferences_repository.dart';
import 'package:app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'is_onboarding_completed': true});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('App launches with themed shell smoke test', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const PulsePatchApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PulsePatch Lite'), findsOneWidget);
    expect(find.text('Hi, there!'), findsOneWidget);
  });

  testWidgets('Themed shell renders correctly in Arabic RTL locale', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
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
