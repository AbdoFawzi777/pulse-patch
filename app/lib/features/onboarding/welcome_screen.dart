import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/pill_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        children: [
          // Background corner glows
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32.0),
                  // App Emblem
                  Container(
                    width: 56.0,
                    height: 56.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.accentMagenta, AppColors.accentBlue],
                      ),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 28.0,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  const Text(
                    'Welcome to\nPulsePatch Lite',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 32.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  const Text(
                    'An educational, offline-first biomonitoring platform powered by ESP32-C3 optical pulse telemetry.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.0,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32.0),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: const [
                        _FeatureItem(
                          icon: Icons.bluetooth_searching_rounded,
                          title: 'Offline Telemetry',
                          description:
                              'Pairs seamlessly over BLE with the MAX30102 sensor patch. Zero cloud accounts required.',
                        ),
                        SizedBox(height: 14.0),
                        _FeatureItem(
                          icon: Icons.show_chart_rounded,
                          title: 'Truthful Optical Trace',
                          description:
                              'Renders smooth optical photoplethysmogram waveforms with quality-gated metrics. Truthful optical pulse data.',
                        ),
                        SizedBox(height: 14.0),
                        _FeatureItem(
                          icon: Icons.psychology_outlined,
                          title: 'On-Device AI Patterns',
                          description:
                              'A small neural network runs 100% locally on your phone to categorize session patterns.',
                        ),
                      ],
                    ),
                  ),
                  PillButton(
                    label: 'Get Started',
                    style: PillButtonStyle.white,
                    width: double.infinity,
                    height: 52.0,
                    onPressed: onGetStarted,
                  ),
                  const SizedBox(height: 24.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return MetricCard(
      padding: const EdgeInsets.all(18.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44.0,
            height: 44.0,
            decoration: BoxDecoration(
              color: const Color(0xFF131D44),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(icon, color: AppColors.accentCyan, size: 22.0),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.35,
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
