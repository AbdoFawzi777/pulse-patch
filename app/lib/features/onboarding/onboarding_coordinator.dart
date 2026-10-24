import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/preferences_repository.dart';
import 'how_it_works_screen.dart';
import 'permissions_screen.dart';
import 'splash_screen.dart';
import 'user_preferences_screen.dart';
import 'welcome_screen.dart';

enum OnboardingStep {
  splash,
  welcome,
  howItWorks,
  preferences,
  permissions,
  completed,
}

class OnboardingCoordinator extends ConsumerStatefulWidget {
  const OnboardingCoordinator({super.key, required this.onCompleted});

  final VoidCallback onCompleted;

  @override
  ConsumerState<OnboardingCoordinator> createState() =>
      _OnboardingCoordinatorState();
}

class _OnboardingCoordinatorState extends ConsumerState<OnboardingCoordinator> {
  OnboardingStep _currentStep = OnboardingStep.splash;

  @override
  Widget build(BuildContext context) {
    switch (_currentStep) {
      case OnboardingStep.splash:
        return SplashScreen(
          onInitialized: (isDone) {
            if (isDone) {
              widget.onCompleted();
            } else {
              setState(() => _currentStep = OnboardingStep.welcome);
            }
          },
        );

      case OnboardingStep.welcome:
        return WelcomeScreen(
          onGetStarted: () =>
              setState(() => _currentStep = OnboardingStep.howItWorks),
        );

      case OnboardingStep.howItWorks:
        return HowItWorksScreen(
          onBack: () => setState(() => _currentStep = OnboardingStep.welcome),
          onContinue: () =>
              setState(() => _currentStep = OnboardingStep.preferences),
        );

      case OnboardingStep.preferences:
        return UserPreferencesScreen(
          onBack: () =>
              setState(() => _currentStep = OnboardingStep.howItWorks),
          onNext: () =>
              setState(() => _currentStep = OnboardingStep.permissions),
        );

      case OnboardingStep.permissions:
        return PermissionsScreen(
          onBack: () =>
              setState(() => _currentStep = OnboardingStep.preferences),
          onFinish: () {
            ref
                .read(preferencesRepositoryProvider)
                .setOnboardingCompleted(true);
            widget.onCompleted();
          },
        );

      case OnboardingStep.completed:
        return const SizedBox.shrink();
    }
  }
}
