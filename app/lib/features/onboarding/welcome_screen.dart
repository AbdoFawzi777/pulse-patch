import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_icon_widget.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/pill_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return DesignCanvasScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16.0),
          // App Emblem
          const Align(
            alignment: Alignment.centerLeft,
            child: AppIconWidget(size: 64.0, borderRadius: 16.0),
          ),

          const SizedBox(height: 24.0),

          // Titles
          const Text(
            'PulsePatch Lite',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 32.0,
              fontWeight: FontWeight.w300,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6.0),
          const Text(
            'Real-time optical pulse rate tracking & on-device pattern classification',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.0,
              fontWeight: FontWeight.w300,
              color: AppColors.textMuted,
              height: 1.3,
            ),
          ),

          const Spacer(),

          // Educational Card
          MetricCard(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      color: AppColors.accentCyan,
                      size: 22.0,
                    ),
                    SizedBox(width: 10.0),
                    Expanded(
                      child: Text(
                        'Educational Tool Only',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                const Text(
                  'PulsePatch Lite is an open-source educational biomonitoring application designed for physiological learning. It is not a medical device and provides no medical diagnosis.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.0,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24.0),

          // Primary CTA
          PillButton(
            label: 'Get Started',
            style: PillButtonStyle.white,
            width: double.infinity,
            height: 48.0,
            onPressed: onGetStarted,
          ),

          const SizedBox(height: 12.0),
        ],
      ),
    );
  }
}
