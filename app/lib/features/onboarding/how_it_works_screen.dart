import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/circle_icon_button.dart';
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
    ({String step, String title, String description, IconData icon})
  >
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
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        children: [
          // Background corner glow
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12.0),
                  CircleIconButton(
                    icon: Icons.chevron_left_rounded,
                    semanticLabel: 'Back',
                    onPressed: onBack,
                  ),
                  const SizedBox(height: 20.0),
                  const Text(
                    'How It Works',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 28.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  const Text(
                    'Five essential steps for accurate optical pulse recordings.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _steps.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12.0),
                      itemBuilder: (context, index) {
                        final s = _steps[index];
                        return MetricCard(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36.0,
                                height: 36.0,
                                decoration: BoxDecoration(
                                  color: AppColors.accentBlue.withValues(
                                    alpha: 0.15,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.accentBlue.withValues(
                                      alpha: 0.4,
                                    ),
                                    width: 1.0,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    s.step,
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accentCyan,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.title,
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 15.0,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      s.description,
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
                      },
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  PillButton(
                    label: 'Continue',
                    style: PillButtonStyle.white,
                    width: double.infinity,
                    height: 52.0,
                    onPressed: onContinue,
                  ),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
