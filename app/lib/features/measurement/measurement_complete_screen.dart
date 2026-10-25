import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/session_stats_record.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/dot_variability_chart.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/pill_button.dart';
import '../../shared/widgets/pulse_trace_chart.dart';

class MeasurementCompleteScreen extends StatelessWidget {
  const MeasurementCompleteScreen({
    super.key,
    required this.stats,
    this.pulseWaveformPoints = const [],
    required this.onSave,
    required this.onDiscard,
    required this.onViewInsights,
    required this.onBack,
    this.isSampleData = true,
  });

  final SessionStatsRecord stats;
  final List<double> pulseWaveformPoints;
  final VoidCallback onSave;
  final VoidCallback onDiscard;
  final VoidCallback onViewInsights;
  final VoidCallback onBack;
  final bool isSampleData;

  @override
  Widget build(BuildContext context) {
    final meanBpm = stats.meanHr.round();
    final minBpm = stats.minHr.round();
    final maxBpm = stats.maxHr.round();
    final pulseInterval = stats.pulseIntervalMs?.round() ?? 0;
    final variability = stats.variabilityEstMs?.round() ?? 0;

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
              const Expanded(
                child: Center(
                  child: Text(
                    'Heart Rate Summary',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22.0,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textPrimary,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 56.0),
            ],
          ),
          const SizedBox(height: 8.0),
          const Center(
            child: PulseTraceChart(
              useDesignPath: true,
              width: 350.0,
              height: 110.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$meanBpm',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 72.0,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textPrimary,
                        height: 1.0,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0, left: 4.0),
                      child: Text(
                        'BPM',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20.0,
                          fontWeight: FontWeight.w300,
                          color: AppColors.textPrimary,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '$minBpm min   $maxBpm max',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.0,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                MetricCard(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          'Pulse interval',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.0,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '$pulseInterval ms',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20.0,
                          fontWeight: FontWeight.w300,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10.0),
                MetricCard(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text(
                              'Variability (est.)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16.0,
                                fontWeight: FontWeight.w300,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '$variability ms',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 20.0,
                              fontWeight: FontWeight.w300,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      const DotVariabilityChart(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              Expanded(
                child: PillButton(
                  label: 'Discard',
                  style: PillButtonStyle.dark,
                  onPressed: () async {
                    final confirmed = await ConfirmDialog.show(
                      context,
                      title: 'Discard Recording?',
                      message:
                          'This measurement data will not be saved to your device.',
                      confirmLabel: 'Discard',
                      cancelLabel: 'Keep',
                      isDestructive: true,
                    );
                    if (confirmed == true) {
                      onDiscard();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: PillButton(
                  label: 'Save Session',
                  style: PillButtonStyle.white,
                  onPressed: onSave,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
        ],
      ),
    );
  }
}
