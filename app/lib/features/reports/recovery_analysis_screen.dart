import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/entities/session_record.dart';
import '../../domain/entities/session_stats_record.dart';
import '../../domain/signal/feature_extractor.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/status_chip.dart';
import '../../shared/widgets/trend_chart.dart';

class RecoveryAnalysisScreen extends ConsumerWidget {
  const RecoveryAnalysisScreen({
    super.key,
    required this.session,
    required this.stats,
    required this.onBack,
  });

  final SessionRecord session;
  final SessionStatsRecord? stats;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionRepo = ref.watch(sessionRepositoryProvider);
    final isPostActivity = session.type == SessionType.postActivity;

    final durationSec = session.endedAt != null
        ? session.endedAt!.difference(session.startedAt).inSeconds
        : (stats?.totalDurationSeconds ?? 0);

    final hasSufficientRecovery =
        isPostActivity &&
        durationSec >= FeatureExtractor.minRecoveryDurationSeconds &&
        stats?.recoveryDrop != null;

    // Fetch prior sessions of same type for personal baseline comparison
    final priorSessions = sessionRepo
        .getAllSessions()
        .where((s) => s.id != session.id && s.type == session.type)
        .toList();

    final priorStats = priorSessions
        .map((s) => sessionRepo.getStatsForSession(s.id))
        .whereType<SessionStatsRecord>()
        .toList();

    final baseline = stats != null
        ? FeatureExtractor.compareBaseline(
            currentMeanHr: stats!.meanHr,
            priorStats: priorStats,
          )
        : null;

    // Build recovery curve points if samples exist
    final samples = sessionRepo.getSamplesForSession(session.id);
    final recoveryCurveValues = <double?>[];
    final recoveryCurveLabels = <String>[];

    if (samples.isNotEmpty) {
      final validSamples = samples
          .where((s) => s.isValid && s.bpm != null)
          .toList();
      const step = 10;
      for (int t = 0; t <= durationSec; t += step) {
        recoveryCurveLabels.add('${t}s');
        final windowSamples = validSamples
            .where(
              (s) =>
                  (s.tMs - samples.first.tMs) ~/ 1000 >= t &&
                  (s.tMs - samples.first.tMs) ~/ 1000 < t + step,
            )
            .map((s) => s.bpm!)
            .toList();
        if (windowSamples.isNotEmpty) {
          final avg =
              windowSamples.reduce((a, b) => a + b) / windowSamples.length;
          recoveryCurveValues.add(avg);
        } else {
          recoveryCurveValues.add(null);
        }
      }
    }

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
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12.0),
                    // Header Row
                    Row(
                      children: [
                        CircleIconButton(
                          icon: Icons.chevron_left_rounded,
                          semanticLabel: 'Back',
                          onPressed: onBack,
                        ),
                        const Expanded(
                          child: Text(
                            'Recovery Analysis',
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
                    const SizedBox(height: 18.0),

                    // Recovery Drop Metric Card
                    MetricCard(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 4.0,
                            children: [
                              const Text(
                                'Post-Activity Recovery Drop',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              StatusChip(
                                label: hasSufficientRecovery
                                    ? '60s Window'
                                    : 'Insufficient data',
                                variant: hasSufficientRecovery
                                    ? StatusChipVariant.active
                                    : StatusChipVariant.neutral,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14.0),
                          if (hasSufficientRecovery) ...[
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '-${stats!.recoveryDrop!.round()}',
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 48.0,
                                      fontWeight: FontWeight.w300,
                                      color: AppColors.accentCyan,
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  const Text(
                                    'BPM in 60s',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 16.0,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            Text(
                              'Heart rate dropped from ${stats!.startHr.round()} BPM (initial) '
                              'to ${(stats!.startHr - stats!.recoveryDrop!).round()} BPM at 1 minute post-activity.',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.0,
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(14.0),
                              decoration: BoxDecoration(
                                color: AppColors.cardBgNavy,
                                borderRadius: BorderRadius.circular(14.0),
                                border: Border.all(
                                  color: AppColors.cardBorder,
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    color: AppColors.textMuted,
                                    size: 20.0,
                                  ),
                                  const SizedBox(width: 10.0),
                                  Expanded(
                                    child: Text(
                                      isPostActivity
                                          ? 'Recovery drop calculation requires at least 70 seconds of recording with valid samples in the 55s–65s window. '
                                                'Current duration: ${durationSec}s. Data is marked Insufficient for AI (no guess is made).'
                                          : 'This session was recorded as Resting protocol. Post-activity recovery drop is evaluated on active exercise sessions only.',
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 13.0,
                                        color: AppColors.textSecondary,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Recovery Curve Chart Card
                    if (recoveryCurveValues.isNotEmpty) ...[
                      MetricCard(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Heart Rate Trajectory',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16.0,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            TrendChart(
                              values: recoveryCurveValues,
                              labels: recoveryCurveLabels,
                              height: 130.0,
                              lineColor: AppColors.accentCyan,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16.0),
                    ],

                    // Personal Baseline Statistical Comparison Card
                    MetricCard(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 4.0,
                            children: [
                              Text(
                                'Personal Baseline Statistics',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              StatusChip(
                                label: 'Statistical z-score',
                                variant: StatusChipVariant.neutral,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12.0),
                          if (baseline != null && baseline.hasBaseline) ...[
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 10.0,
                              runSpacing: 4.0,
                              children: [
                                Text(
                                  'z = ${baseline.zScore! > 0 ? "+" : ""}${baseline.zScore!.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 28.0,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Baseline Mean: ${baseline.baselineMeanHr!.toStringAsFixed(1)} BPM (±${baseline.baselineStdHr!.toStringAsFixed(1)})',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13.0,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              baseline.summaryText,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.0,
                                color: AppColors.accentCyan,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Calculated from your past ${baseline.baselineCount} ${session.type == SessionType.rest ? "resting" : "post-activity"} sessions. Described strictly as sample statistics, not AI.',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.0,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ] else ...[
                            Text(
                              'Baseline comparison requires at least 5 comparable recorded sessions '
                              '(${baseline?.baselineCount ?? 0}/5 recorded so far). '
                              'Continue recording to unlock longitudinal statistical comparisons.',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.0,
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Educational Disclaimer Banner
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgNavy,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: AppColors.cardBorder,
                          width: 1.0,
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            color: AppColors.textMuted,
                            size: 20.0,
                          ),
                          SizedBox(width: 10.0),
                          Expanded(
                            child: Text(
                              'PulsePatch Lite is an educational research prototype. '
                              'Recovery rate varies naturally with ambient temperature, hydration, and fatigue. '
                              'It does not constitute a cardiovascular fitness diagnosis.',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.0,
                                color: AppColors.textMuted,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
