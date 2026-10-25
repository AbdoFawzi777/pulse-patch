import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
