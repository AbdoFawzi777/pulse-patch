import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/preferences_repository.dart';

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

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
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
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        children: [
          // Background corner glows
          Positioned(
            top: -120,
            left: -120,
            width: 360,
            height: 360,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.bgGlowTopLeft.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -120,
            width: 360,
            height: 360,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.bgGlowBottomRight.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 100.0,
                    height: 100.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.accentMagenta, AppColors.accentBlue],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentMagenta.withValues(alpha: 0.4),
                          blurRadius: 28.0,
                          spreadRadius: 4.0,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 52.0,
                    ),
                  ),
                ),
                const SizedBox(height: 28.0),
                const Text(
                  'PulsePatch Lite',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 32.0,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'v1.0.0 · Educational Prototype',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
