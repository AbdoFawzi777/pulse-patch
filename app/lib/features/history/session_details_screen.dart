import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/entities/session_record.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/dot_variability_chart.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/pulse_trace_chart.dart';

/// Heart Rate screen matching Detail.dc.html and Heart Rate.png exactly.
class SessionDetailsScreen extends ConsumerWidget {
  const SessionDetailsScreen({
    super.key,
    required this.session,
    required this.onBack,
    this.onDeleted,
  });

  final SessionRecord session;
  final VoidCallback onBack;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionRepo = ref.watch(sessionRepositoryProvider);
    final stats = sessionRepo.getStatsForSession(session.id);

    final meanHr = stats?.meanHr.round() ?? 74;
    final minHr = stats?.minHr.round() ?? 58;
    final maxHr = stats?.maxHr.round() ?? 96;
    final pulseInterval = stats?.pulseIntervalMs?.round() ?? 811;
    final variability = stats?.variabilityEstMs?.round() ?? 41;

    return DesignCanvasScaffold(
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
                onPressed: onBack,
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

          const SizedBox(height: 8.0),

          // Optical Pulse Trace Waveform
          const Center(
            child: PulseTraceChart(
              useDesignPath: true,
              width: 350.0,
              height: 130.0,
            ),
          ),

          const SizedBox(height: 8.0),

          // Hero BPM & Min/Max Row (.r)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$meanHr',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 96.0,
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
                          fontSize: 22.0,
                          fontWeight: FontWeight.w300,
                          color: AppColors.textPrimary,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '$minHr min   $maxHr max',
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

          // Card 1: Pulse interval
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$pulseInterval ',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 24.0,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textPrimary,
                        height: 1.0,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const Text(
                      'ms',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.0,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8.0),

          // Card 2: Variability (est.) & Dot Scatter Chart
          MetricCard(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$variability ',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 24.0,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textPrimary,
                            height: 1.0,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const Text(
                          'ms',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.0,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                const DotVariabilityChart(),
              ],
            ),
          ),

          const SizedBox(height: 10.0),

          // Footer disclaimer
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
