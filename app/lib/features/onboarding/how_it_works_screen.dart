import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/pill_button.dart';

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({
    super.key,
    required this.onContinue,
    required this.onBack,
  });

  final VoidCallback onContinue;
  final VoidCallback onBack;

  static const List<
      ({String step, String title, String description, IconData icon})>
  _steps = [
    (
      step: '1',
      title: 'Place patch on fingertip',
      description:
          'Place the MAX30102 optical sensor firmly against your fingertip pad. Ensure comfortable contact without pressing too hard.',
      icon: Icons.touch_app_rounded,
    ),
    (
      step: '2',
      title: 'Keep hand still & relaxed',
      description:
          'Optical PPG sensors are sensitive to motion artifacts. Rest your hand comfortably on a flat surface during recording.',
      icon: Icons.airline_seat_recline_normal_rounded,
    ),
    (
      step: '3',
      title: 'Optical LED detects pulse',
      description:
          'Infrared and red LEDs illuminate capillary blood vessels, measuring micro-variations in blood volume with every heartbeat.',
      icon: Icons.lightbulb_outline_rounded,
    ),
    (
      step: '4',
      title: 'View live telemetry',
      description:
          'Watch the smooth optical pulse waveform and quality-gated live BPM stream directly over Bluetooth Low Energy.',
      icon: Icons.monitor_heart_outlined,
    ),
    (
      step: '5',
      title: 'Explore local AI patterns',
      description:
          'After recordings of at least 30 seconds, view recovery drops and compare sessions against your personal statistical baseline.',
      icon: Icons.auto_awesome_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DesignCanvasScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleIconButton(
                type: CircleIconType.back,
                semanticLabel: 'Back',
                onPressed: onBack,
              ),
              const Text(
                'How It Works',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 22.0,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textPrimary,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 56.0),
            ],
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Five essential steps for accurate optical pulse recordings.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.0,
              fontWeight: FontWeight.w300,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16.0),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: _steps.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 12.0),
              itemBuilder: (context, index) {
                final item = _steps[index];
                return MetricCard(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32.0,
                        height: 32.0,
                        decoration: const BoxDecoration(
                          color: AppColors.cardBgNavy,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          item.step,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                            color: AppColors.accentCyan,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16.0,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              item.description,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.0,
                                fontWeight: FontWeight.w300,
                                color: AppColors.textMuted,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16.0),
          PillButton(
            label: 'Continue',
            style: PillButtonStyle.white,
            width: double.infinity,
            height: 48.0,
            onPressed: onContinue,
          ),
          const SizedBox(height: 10.0),
        ],
      ),
    );
  }
}
