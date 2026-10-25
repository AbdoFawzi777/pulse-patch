import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/preferences_repository.dart';
import '../../shared/widgets/app_icon_widget.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key, this.onInitialized, this.autoNavigate = true});

  final void Function(bool isOnboardingCompleted)? onInitialized;
  final bool autoNavigate;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _pulseAnimation;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    if (widget.autoNavigate) {
      _navTimer = Timer(const Duration(milliseconds: 1600), () {
        if (!mounted) return;
        final prefsRepo = ref.read(preferencesRepositoryProvider);
        final isDone = prefsRepo.isOnboardingCompleted;
        widget.onInitialized?.call(isDone);
      });
    }
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesignCanvasScaffold(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: const AppIconWidget(
                size: 110.0,
                borderRadius: 24.0,
                clipToSquircle: true,
              ),
            ),
            const SizedBox(height: 24.0),
            const Text(
              'PulsePatch Lite',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 32.0,
                fontWeight: FontWeight.w300,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6.0),
            const Text(
              'Educational Pulse Biomonitoring',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.0,
                fontWeight: FontWeight.w300,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
