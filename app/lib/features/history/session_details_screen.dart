import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/entities/session_record.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/heart_rate_hero_number.dart';
import '../../shared/widgets/insight_card.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/pill_button.dart';
import '../../shared/widgets/pulse_trace_chart.dart';
import '../../shared/widgets/status_chip.dart';

class SessionDetailsScreen extends ConsumerStatefulWidget {
  const SessionDetailsScreen({
    super.key,
    required this.session,
    required this.onBack,
    required this.onDeleted,
  });

  final SessionRecord session;
  final VoidCallback onBack;
  final VoidCallback onDeleted;

  @override
  ConsumerState<SessionDetailsScreen> createState() =>
      _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends ConsumerState<SessionDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final sessionRepo = ref.watch(sessionRepositoryProvider);
    final stats = sessionRepo.getStatsForSession(widget.session.id);
    final aiResult = sessionRepo.getAiResultForSession(widget.session.id);
    final samples = sessionRepo.getSamplesForSession(widget.session.id);

    final durationSec = widget.session.endedAt != null
        ? widget.session.endedAt!.difference(widget.session.startedAt).inSeconds
        : (stats?.totalDurationSeconds ?? 60);

    final isSampleData = widget.session.source == SessionSource.simulator;

    // Build synthetic or real waveform points for the optical trace chart
    final waveformPoints = samples.isNotEmpty
        ? samples
              .map((s) => (s.bpm != null ? (s.bpm! - 40.0) / 140.0 : 0.5))
              .take(60)
              .toList()
        : List.generate(
            50,
            (i) => 0.5 + 0.3 * (i % 2 == 0 ? 1.0 : -0.8) * ((i % 10) / 10.0),
          );

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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  const SizedBox(height: 12.0),
                  // Header Row
                  Row(
                    children: [
                      CircleIconButton(
                        icon: Icons.chevron_left_rounded,
                        semanticLabel: 'Back',
                        onPressed: widget.onBack,
                      ),
                      const Expanded(
                        child: Text(
                          'Session Details',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 22.0,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      CircleIconButton(
                        icon: Icons.delete_outline_rounded,
                        semanticLabel: 'Delete Session',
                        onPressed: _handleDelete,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14.0),
                  // Content Scroll View
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Metadata Row
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: 6.0,
                          children: [
                            Text(
                              '${DateFormat('EEEE, MMM d · HH:mm').format(widget.session.startedAt)} · ${durationSec}s',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Wrap(
                              spacing: 6.0,
                              children: [
                                StatusChip(
                                  label: widget.session.type == SessionType.rest
                                      ? 'Rest'
                                      : 'Post-Activity',
                                  variant: StatusChipVariant.neutral,
                                ),
                                StatusChip(
                                  label: isSampleData
                                      ? 'Sample data'
                                      : 'Hardware',
                                  variant: StatusChipVariant.sample,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),

                        // Hero Number & Min/Max Banner
                        MetricCard(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Expanded(
                                    child: HeartRateHeroNumber(
                                      bpm: stats?.meanHr.round() ?? 74,
                                      size: HeroNumberSize.large,
                                      isStale: true,
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Text(
                                    stats != null
                                        ? '${stats.minHr.round()} min · ${stats.maxHr.round()} max'
                                        : 'Saved session',
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14.0,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14.0),
                              // Optical Pulse Trace Waveform
                              PulseTraceChart(
                                points: waveformPoints,
                                height: 90.0,
                                strokeWidth: 2.2,
                              ),
                              const SizedBox(height: 8.0),
                              const Center(
                                child: Text(
                                  'Optical pulse trace · recorded samples',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.0,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14.0),

                        // Stats Grid: 5 ML Features + Intervals
                        Row(
                          children: [
                            Expanded(
                              child: _StatMiniCard(
                                label: 'mean_hr',
                                value: stats != null
                                    ? '${stats.meanHr.toStringAsFixed(1)} BPM'
                                    : 'N/A',
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: _StatMiniCard(
                                label: 'std_hr',
                                value: stats != null
                                    ? stats.stdHr.toStringAsFixed(2)
                                    : 'N/A',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10.0),
                        Row(
                          children: [
                            Expanded(
                              child: _StatMiniCard(
                                label: 'start_hr',
                                value: stats != null
                                    ? '${stats.startHr.round()} BPM'
                                    : 'N/A',
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: _StatMiniCard(
                                label: 'end_hr',
                                value: stats != null
                                    ? '${stats.endHr.round()} BPM'
                                    : 'N/A',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10.0),
                        Row(
                          children: [
                            Expanded(
                              child: _StatMiniCard(
                                label: 'recovery_drop',
                                value: stats?.recoveryDrop != null
                                    ? '${stats!.recoveryDrop!.round()} BPM'
                                    : 'N/A',
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: _StatMiniCard(
                                label: 'Pulse interval',
                                value: stats?.pulseIntervalMs != null
                                    ? '${stats!.pulseIntervalMs!.round()} ms'
                                    : 'N/A',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14.0),

                        // AI Pattern Card
                        InsightCard.modelResult(
                          patternTitle: aiResult != null
                              ? (aiResult.label == 'different'
                                    ? 'Different pattern'
                                    : 'Typical pattern')
                              : 'Typical pattern',
                          explanation:
                              'Compared against baseline recordings. Experimental pattern label, not a health or clinical rating.',
                          badgeText: 'On-device TFLite',
                        ),
                        const SizedBox(height: 16.0),

                        // Export Actions Row
                        Row(
                          children: [
                            Expanded(
                              child: PillButton(
                                label: 'Share CSV',
                                style: PillButtonStyle.dark,
                                icon: Icons.share_rounded,
                                onPressed: () => _shareCsv(sessionRepo),
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: PillButton(
                                label: 'Share JSON',
                                style: PillButtonStyle.dark,
                                icon: Icons.code_rounded,
                                onPressed: () => _shareJson(sessionRepo),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24.0),
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

  Future<void> _handleDelete() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Session?',
      message:
          'This measurement and its recorded pulse samples will be permanently removed.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(sessionRepositoryProvider);
      repo.deleteSession(widget.session.id);
      widget.onDeleted();
    }
  }

  void _shareCsv(SessionRepository repo) {
    final csv = repo.exportToCsv();
    SharePlus.instance.share(
      ShareParams(
        text: csv,
        subject: 'PulsePatch Lite Session - ${widget.session.id}.csv',
      ),
    );
  }

  void _shareJson(SessionRepository repo) {
    final jsonStr = repo.exportToJson();
    SharePlus.instance.share(
      ShareParams(
        text: jsonStr,
        subject: 'PulsePatch Lite Session - ${widget.session.id}.json',
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  const _StatMiniCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return MetricCard(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.0,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4.0),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18.0,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
