import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/errors/global_error_boundary.dart';
import 'core/l10n/app_localizations.dart';
import 'core/l10n/locale_provider.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'data/drift/app_database.dart';
import 'data/repositories/preferences_repository.dart';
import 'data/repositories/session_repository.dart';
import 'features/home/app_shell.dart';
import 'features/onboarding/onboarding_coordinator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final appDb = await AppDatabase.onDisk();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(appDb),
      ],
      child: const PulsePatchApp(),
    ),
  );
}

class PulsePatchApp extends ConsumerWidget {
  const PulsePatchApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'PulsePatch Lite',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('ar', '')],
      locale: ref.watch(localeProvider),
      builder: (context, widget) {
        return GlobalErrorBoundary(child: widget ?? const SizedBox.shrink());
      },
      home: const AppEntryGate(),
    );
  }
}

class AppEntryGate extends ConsumerStatefulWidget {
  const AppEntryGate({super.key});

  @override
  ConsumerState<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends ConsumerState<AppEntryGate> {
  bool _showHome = false;

  @override
  void initState() {
    super.initState();
    final prefsRepo = ref.read(preferencesRepositoryProvider);
    _showHome = prefsRepo.isOnboardingCompleted;
  }

  @override
  Widget build(BuildContext context) {
    if (_showHome) {
      return const AppShell();
    }

    return OnboardingCoordinator(
      onCompleted: () => setState(() => _showHome = true),
    );
  }
}

class ThemedShellScreen extends StatelessWidget {
  const ThemedShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = l10n?.appTitle ?? 'PulsePatch Lite';

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: AppColors.bgBase)),
          Positioned(
            top: -100,
            left: -100,
            width: 350,
            height: 350,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.bgGlowTopLeft.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            width: 350,
            height: 350,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.bgGlowBottomRight.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n?.greeting ?? 'Hi, there!',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
