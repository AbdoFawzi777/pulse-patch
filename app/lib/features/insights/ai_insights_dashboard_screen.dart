import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/session_record.dart';
import '../../domain/ml/ai_providers.dart';
import '../../shared/widgets/bottom_circle_nav.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_state.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/status_chip.dart';
import 'ai_model_info_screen.dart';
import 'session_pattern_analysis_screen.dart';

/// Aggregated dashboard for all session pattern classifications.
/// Derived screen #10 adhering strictly to design tokens.
class AiInsightsDashboardScreen extends ConsumerWidget {
  const AiInsightsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(aiDashboardSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'AI Insights',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  CircleIconButton(
                    icon: Icons.model_training_rounded,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AiModelInfoScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: summaryAsync.when(
                loading: () =>
                    const LoadingState(message: 'Loading pattern history...'),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: EmptyState(
                      title: 'Data Unavailable',
                      description: 'Could not load pattern summary: $err',
                    ),
                  ),
                ),
                data: (summary) {
                  if (summary.totalSessions == 0) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: EmptyState(
                          title: 'No Sessions Yet',
                          description:
                              'Record your first pulse session to explore automated on-device pattern classification.',
                          icon: Icons.insights_rounded,
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Educational Disclaimer Card
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: AppColors.cardBgNavy,
                            borderRadius: BorderRadius.circular(18.0),
                            border: Border.all(
                              color: AppColors.cardBorder,
                              width: 1.0,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.school_outlined,
                                color: AppColors.accentCyan,
                                size: 24.0,
                              ),
                              SizedBox(width: 12.0),
                              Expanded(
                                child: Text(
                                  'Pattern classifications are statistical clusters from research protocols. Not a medical evaluation.',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16.0),

                        // Metric Cards Row 1: Typical vs Different
                        Row(
                          children: [
                            Expanded(
                              child: MetricCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Typical',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14.0,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      '${summary.typicalCount}',
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 28.0,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.accentCyan,
                                      ),
                                    ),
                                    const SizedBox(height: 2.0),
                                    const Text(
                                      'Rest sessions',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 12.0,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: MetricCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Different',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14.0,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      '${summary.differentCount}',
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 28.0,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.accentPurple,
                                      ),
                                    ),
                                    const SizedBox(height: 2.0),
                                    const Text(
                                      'Varied patterns',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 12.0,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12.0),

                        // Metric Cards Row 2: Consistency & Avg Recovery
                        Row(
                          children: [
                            Expanded(
                              child: MetricCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Consistency',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14.0,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      '${summary.consistencyPercentage.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 28.0,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2.0),
                                    const Text(
                                      'Pattern stability',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 12.0,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: MetricCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Avg Recovery',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14.0,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      summary.averageRecoveryDrop != null
                                          ? '${summary.averageRecoveryDrop!.toStringAsFixed(0)} BPM'
                                          : '--',
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 28.0,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2.0),
                                    const Text(
                                      'Post-activity',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 12.0,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24.0),

                        // Recent Sessions Header
                        const Text(
                          'Recent Classified Sessions',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12.0),

                        // Sessions List
                        ...summary.recentSessionsWithAi.map((item) {
                          final dateStr = DateFormat(
                            'EEE, MMM d · HH:mm',
                          ).format(item.session.startedAt);
                          final meanHrStr = item.stats != null
                              ? '${item.stats!.meanHr.toStringAsFixed(0)} BPM'
                              : '--';
                          final isTypical =
                              item.aiResult?.label.toLowerCase().contains(
                                'typical',
                              ) ??
                              true;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10.0),
                            decoration: BoxDecoration(
                              color: AppColors.cardBgNavy,
                              borderRadius: BorderRadius.circular(18.0),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 6.0,
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      dateStr,
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 15.0,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    meanHrStr,
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Row(
                                  children: [
                                    StatusChip(
                                      label: item.aiResult != null
                                          ? item.aiResult!.label
                                          : 'Unclassified',
                                      variant: item.aiResult != null
                                          ? (isTypical
                                                ? StatusChipVariant.active
                                                : StatusChipVariant
                                                      .experimental)
                                          : StatusChipVariant.neutral,
                                    ),
                                    const SizedBox(width: 8.0),
                                    Text(
                                      item.session.type ==
                                              SessionType.postActivity
                                          ? 'Post-Activity'
                                          : 'Rest',
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 12.0,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textSecondary,
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SessionPatternAnalysisScreen(
                                          sessionId: item.session.id,
                                        ),
                                  ),
                                );
                              },
                            ),
                          );
                        }),

                        const SizedBox(height: 16.0),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation with Circle 3 (Insights) active
            BottomCircleNav(
              currentIndex: 2,
              onTap: (index) {
                if (index != 2) {
                  Navigator.of(context).maybePop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
