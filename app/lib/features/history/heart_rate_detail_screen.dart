import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/dot_variability_chart.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/pulse_trace_chart.dart';

/// Heart Rate screen matching Detail.dc.html and Heart Rate.png exactly.
/// 390x844 logical artboard, Outfit typography, exact pulse trace and 12x4 dot chart.
class HeartRateDetailScreen extends StatelessWidget {
  const HeartRateDetailScreen({
    super.key,
    this.onBack,
    this.bpm = 74,
    this.minBpm = 58,
    this.maxBpm = 96,
    this.pulseIntervalMs = 811,
    this.variabilityMs = 41,
  });

  final VoidCallback? onBack;
  final int bpm;
  final int minBpm;
  final int maxBpm;
  final int pulseIntervalMs;
  final int variabilityMs;

  @override
  Widget build(BuildContext context) {
    return DesignCanvasScaffold(
      padding: const EdgeInsets.fromLTRB(20.0, 28.0, 20.0, 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row (.r)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleIconButton(
                type: CircleIconType.back,
                semanticLabel: 'Back',
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              ),
              const Text(
                'Heart Rate',
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

          // Optical pulse trace waveform (350x130, stroke #fff, width 1.3)
          const Center(
            child: PulseTraceChart(
              useDesignPath: true,
              width: 350.0,
              height: 130.0,
            ),
          ),

          // Hero BPM Number and Min/Max Row (.r)
          Padding(
            padding: const EdgeInsets.fromLTRB(0.0, 16.0, 0.0, 20.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 350.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: '$bpm',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 96.0,
                          fontWeight: FontWeight.w300,
                          color: AppColors.textPrimary,
                          height: 1.0,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                        children: const [
                          TextSpan(
                            text: ' BPM',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 22.0,
                              fontWeight: FontWeight.w300,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Text(
                        '$minBpm min   $maxBpm max',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.0,
                          fontWeight: FontWeight.w300,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Card 1: Pulse interval (.c)
          SizedBox(
            height: 62.0,
            child: MetricCard(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pulse interval',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.0,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      text: '$pulseIntervalMs ',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 24.0,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textPrimary,
                        height: 1.0,
                      ),
                      children: const [
                        TextSpan(
                          text: 'ms',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.0,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8.0),

          // Card 2: Variability (est.) (.c with dot chart)
          SizedBox(
            height: 204.0,
            child: MetricCard(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Variability (est.)',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.0,
                          fontWeight: FontWeight.w300,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          text: '41 ',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 24.0,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textPrimary,
                            height: 1.0,
                          ),
                          children: [
                            TextSpan(
                              text: 'ms',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.0,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const DotVariabilityChart(width: 318.0, height: 142.0),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10.0),

          // Footnote (.m)
          const Text(
            'Sample data · estimated from optical pulse peaks',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.0,
              fontWeight: FontWeight.w300,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
