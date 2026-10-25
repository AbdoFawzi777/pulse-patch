import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/data/repositories/preferences_repository.dart';
import 'package:app/features/onboarding/how_it_works_screen.dart';
import 'package:app/features/onboarding/permissions_screen.dart';
import 'package:app/features/onboarding/splash_screen.dart';
import 'package:app/features/onboarding/user_preferences_screen.dart';
import 'package:app/features/onboarding/welcome_screen.dart';
import 'package:app/shared/widgets/app_icon_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final fontLoader = FontLoader('Outfit');
    final fontLight = File('assets/fonts/Outfit-Light.ttf');
    if (fontLight.existsSync()) {
      fontLoader.addFont(Future.value(ByteData.view(fontLight.readAsBytesSync().buffer)));
    }
    final fontReg = File('assets/fonts/Outfit-Regular.ttf');
    if (fontReg.existsSync()) {
      fontLoader.addFont(Future.value(ByteData.view(fontReg.readAsBytesSync().buffer)));
    }
    final fontMed = File('assets/fonts/Outfit-Medium.ttf');
    if (fontMed.existsSync()) {
      fontLoader.addFont(Future.value(ByteData.view(fontMed.readAsBytesSync().buffer)));
    }
    await fontLoader.load();
  });

  late SharedPreferences prefs;
  late PreferencesRepository prefsRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    prefsRepo = PreferencesRepository(prefs);
  });

  group('Phase 2 Onboarding & Preferences Unit Tests', () {
    test(
      'PreferencesRepository reads and writes defaults accurately',
      () async {
        expect(prefsRepo.isOnboardingCompleted, isFalse);
        expect(prefsRepo.userName, isEmpty);
        expect(prefsRepo.useBpmUnits, isTrue);

        await prefsRepo.setOnboardingCompleted(true);
        await prefsRepo.setUserName('Alex');
        await prefsRepo.setUseBpmUnits(false);

        expect(prefsRepo.isOnboardingCompleted, isTrue);
        expect(prefsRepo.userName, 'Alex');
        expect(prefsRepo.useBpmUnits, isFalse);
      },
    );
  });

  group('Phase 2 Onboarding Widget Tests', () {
    testWidgets('SplashScreen renders title and animated emblem', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(
            themeMode: ThemeMode.dark,
            home: SplashScreen(autoNavigate: false),
          ),
        ),
      );

      expect(find.text('PulsePatch Lite'), findsOneWidget);
      expect(find.text('Educational Pulse Biomonitoring'), findsOneWidget);
      expect(find.byType(AppIconWidget), findsOneWidget);
    });

    testWidgets('WelcomeScreen renders value propositions and fires callback', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool started = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: WelcomeScreen(onGetStarted: () => started = true),
        ),
      );

      expect(find.text('PulsePatch Lite'), findsOneWidget);
      expect(find.text('Educational Tool Only'), findsOneWidget);
      expect(find.byType(AppIconWidget), findsOneWidget);

      await tester.tap(find.text('Get Started'));
      expect(started, isTrue);
    });

    testWidgets('HowItWorksScreen displays steps with fingertip instructions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool continued = false;
      bool backed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: HowItWorksScreen(
            onContinue: () => continued = true,
            onBack: () => backed = true,
          ),
        ),
      );

      expect(find.text('How It Works'), findsOneWidget);
      expect(find.text('Place patch on fingertip'), findsOneWidget);
      expect(find.text('Keep hand still & relaxed'), findsOneWidget);
      expect(find.text('Optical LED detects pulse'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      expect(continued, isTrue);

      await tester.tap(find.bySemanticsLabel('Back'));
      expect(backed, isTrue);
    });

    testWidgets('UserPreferencesScreen saves name and selected unit', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool nextTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: UserPreferencesScreen(
              onNext: () => nextTapped = true,
              onBack: () {},
            ),
          ),
        ),
      );

      expect(find.text('Personalize'), findsOneWidget);
      expect(find.text('BPM'), findsOneWidget);
      expect(find.text('ms (Interval)'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'TestVolunteer');
      await tester.tap(find.text('ms (Interval)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save & Continue'));
      await tester.pumpAndSettle();

      expect(nextTapped, isTrue);
      expect(prefsRepo.userName, 'TestVolunteer');
      expect(prefsRepo.useBpmUnits, isFalse);
    });

    testWidgets(
      'PermissionsScreen renders explanation cards and handles finish',
      (tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        bool finished = false;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: PermissionsScreen(
                onFinish: () => finished = true,
                onBack: () {},
              ),
            ),
          ),
        );

        expect(find.text('Permissions'), findsOneWidget);
        expect(find.text('Bluetooth Low Energy'), findsOneWidget);
        expect(find.text('Notifications'), findsOneWidget);

        await tester.tap(find.text('Complete Setup'));
        await tester.pumpAndSettle();

        expect(finished, isTrue);
        expect(prefsRepo.isOnboardingCompleted, isTrue);
      },
    );
  });
}
