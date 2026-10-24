import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/session_stats_record.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/dot_variability_chart.dart';
import '../../shared/widgets/heart_rate_hero_number.dart';
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

  static const List<List<DotPoint>> _sampleVariabilityColumns = [
    [
      DotPoint(normalizedY: 0.25, isMagenta: true),
      DotPoint(normalizedY: 0.45, isMagenta: false),
      DotPoint(normalizedY: 0.65, isMagenta: false),
      DotPoint(normalizedY: 0.85, isMagenta: true),
    ],
    [
      DotPoint(normalizedY: 0.35, isMagenta: true),
      DotPoint(normalizedY: 0.55, isMagenta: false),
      DotPoint(normalizedY: 0.80, isMagenta: false),
    ],
    [
      DotPoint(normalizedY: 0.40, isMagenta: true),
      DotPoint(normalizedY: 0.55, isMagenta: true),
      DotPoint(normalizedY: 0.70, isMagenta: false),
      DotPoint(normalizedY: 0.85, isMagenta: false),
    ],
    [
      DotPoint(normalizedY: 0.30, isMagenta: false),
      DotPoint(normalizedY: 0.50, isMagenta: false),
      DotPoint(normalizedY: 0.68, isMagenta: false),
      DotPoint(normalizedY: 0.88, isMagenta: false),
    ],
    [
      DotPoint(normalizedY: 0.35, isMagenta: true),
      DotPoint(normalizedY: 0.50, isMagenta: false),
      DotPoint(normalizedY: 0.60, isMagenta: true),
      DotPoint(normalizedY: 0.75, isMagenta: true),
      DotPoint(normalizedY: 0.85, isMagenta: false),
    ],
    [
      DotPoint(normalizedY: 0.30, isMagenta: false),
      DotPoint(normalizedY: 0.45, isMagenta: true),
      DotPoint(normalizedY: 0.60, isMagenta: false),
      DotPoint(normalizedY: 0.75, isMagenta: false),
      DotPoint(normalizedY: 0.88, isMagenta: false),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final meanBpm = stats.meanHr.round();
    final minBpm = stats.minHr.round();
    final maxBpm = stats.maxHr.round();
    final pulseInterval =
        stats.pulseIntervalMs?.round() ??
        (meanBpm > 0 ? (60000 ~/ meanBpm) : 811);
    final variability = stats.variabilityEstMs?.round() ?? 41;

    final defaultWaveform = pulseWaveformPoints.isNotEmpty
        ? pulseWaveformPoints
        : [0.6, 0.4, 0.2, 0.5, 0.8, 0.4, 0.2, 0.5, 0.8, 0.3, 0.6];

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        children: [
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12.0),
                  // Top Header
                  Row(
                    children: [
                      CircleIconButton(
                        icon: Icons.chevron_left_rounded,
                        semanticLabel: 'Back',
                        onPressed: onBack,
                      ),
                      const Expanded(
                        child: Text(
                          'Heart Rate',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 22.0,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 56.0),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  // Optical Pulse Waveform / Trend
                  PulseTraceChart(
                    points: defaultWaveform,
                    height: 90.0,
                    strokeWidth: 2.5,
                  ),
                  const SizedBox(height: 8.0),
                  Center(
                    child: Text(
                      isSampleData
                          ? 'Optical pulse trace · Simulator'
                          : 'Heart rate trend (BPM) · Real device (12-byte GATT stream)',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.0,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  // Hero stats block
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: HeartRateHeroNumber(
                          bpm: meanBpm,
                          size: HeroNumberSize.medium,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        '$minBpm min $maxBpm max',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.0,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Pulse interval card
                        MetricCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 18.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Pulse interval',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '$pulseInterval',
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 26.0,
                                      fontWeight: FontWeight.w300,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4.0),
                                  const Text(
                                    'ms',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14.0,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        // Variability card with dot chart
                        MetricCard(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Variability (est.)',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '$variability',
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 26.0,
                                          fontWeight: FontWeight.w300,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 4.0),
                                      const Text(
                                        'ms',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 14.0,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16.0),
                              const DotVariabilityChart(
                                columns: _sampleVariabilityColumns,
                                height: 120.0,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        // Actions Row: Discard, Save, AI Insights
                        Row(
                          children: [
                            Expanded(
                              child: PillButton(
                                label: 'Discard',
                                style: PillButtonStyle.dark,
                                onPressed: () async {
                                  final confirm = await ConfirmDialog.show(
                                    context,
                                    title: 'Discard Session?',
                                    message:
                                        'This session measurement will not be saved.',
                                    confirmLabel: 'Discard',
                                    isDestructive: true,
                                  );
                                  if (confirm == true) {
                                    onDiscard();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: PillButton(
                                label: 'Save',
                                style: PillButtonStyle.white,
                                onPressed: onSave,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10.0),
                        PillButton(
                          label: 'View AI Insights',
                          style: PillButtonStyle.dark,
                          width: double.infinity,
                          icon: Icons.auto_awesome_rounded,
                          onPressed: onViewInsights,
                        ),
                        const SizedBox(height: 14.0),
                        // Footer notice
                        Center(
                          child: Text(
                            isSampleData
                                ? 'Sample data · estimated from optical pulse peaks'
                                : 'Recorded · estimated from optical pulse peaks',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.0,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
