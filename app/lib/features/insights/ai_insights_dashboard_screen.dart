import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/session_repository.dart';
import '../../shared/widgets/bottom_circle_nav.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/status_chip.dart';
import 'ai_model_info_screen.dart';

/// AI Insights screen matching Insights.dc.html and AI Insights.png exactly.
/// 390x844 logical artboard, Outfit typography, 2x2 grid + 1 full card for features.
class AiInsightsDashboardScreen extends ConsumerWidget {
  const AiInsightsDashboardScreen({
    super.key,
    this.onBack,
    this.onSelectTab,
    this.currentNavIndex = 2,
    this.showBottomNav = true,
  });

  final VoidCallback? onBack;
  final ValueChanged<int>? onSelectTab;
  final int currentNavIndex;
  final bool showBottomNav;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionRepo = ref.watch(sessionRepositoryProvider);
    final allSessions = sessionRepo.getAllSessions();
    final latestSession = allSessions.isNotEmpty ? allSessions.first : null;
    final stats = latestSession != null
        ? sessionRepo.getStatsForSession(latestSession.id)
        : null;
    final aiResult = latestSession != null
        ? sessionRepo.getAiResultForSession(latestSession.id)
        : null;

    final patternLabel = aiResult?.label ?? 'Typical pattern';
    final String explanationText =
        (aiResult?.explanation != null && aiResult!.explanation!.isNotEmpty)
        ? aiResult.explanation!
        : 'Similar to your last 5 rest sessions. A pattern label, not a health rating.';

    final meanHr = stats?.meanHr.round() ?? 74;
    final stdHr = stats != null ? stats.stdHr.toStringAsFixed(1) : '3.1';
    final startHr = stats?.startHr.round() ?? 78;
    final endHr = stats?.endHr.round() ?? 70;
    final recoveryDrop = stats?.recoveryDrop?.round() ?? -8;
    final dropSign = recoveryDrop <= 0
        ? '−${recoveryDrop.abs()}'
        : '+$recoveryDrop';

    return DesignCanvasScaffold(
      padding: const EdgeInsets.fromLTRB(20.0, 28.0, 20.0, 20.0),
      bottomNavigationBar: showBottomNav
          ? BottomCircleNav(
              currentIndex: currentNavIndex,
              onTap: onSelectTab ?? (_) {},
            )
          : null,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
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
                  'AI Insights',
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

            const SizedBox(height: 20.0),

            // Hero Model Result Card (.c with AI gradient)
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AiModelInfoScreen()),
                );
              },
              child: MetricCard(
                gradient: const LinearGradient(
                  begin: Alignment(-0.26, -1.59),
                  end: Alignment(0.26, 1.59),
                  colors: [Color(0xFF4A1A8F), Color(0xFF0F2160)],
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Model result',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.0,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textMuted,
                          ),
                        ),
                        StatusChip(label: 'Experimental'),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 14.0, bottom: 10.0),
                      child: Text(
                        patternLabel,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 40.0,
                          fontWeight: FontWeight.w300,
                          color: AppColors.textPrimary,
                          height: 1.1,
                        ),
                      ),
                    ),
                    Text(
                      explanationText,
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
            ),

            // Measured values label (.m)
            const Padding(
              padding: EdgeInsets.only(top: 12.0, bottom: 8.0),
              child: Text(
                'Measured values used',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.0,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textMuted,
                ),
              ),
            ),

            // 2x2 Feature Grid (flex: 1 1 40%)
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    minHeight: 89.0,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'mean_hr',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.0,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          '$meanHr BPM',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 26.0,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textPrimary,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: MetricCard(
                    minHeight: 89.0,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'std_hr',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.0,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          stdHr,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 26.0,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textPrimary,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10.0),

            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    minHeight: 89.0,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'start_hr',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.0,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          '$startHr BPM',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 26.0,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textPrimary,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: MetricCard(
                    minHeight: 89.0,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'end_hr',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.0,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          '$endHr BPM',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 26.0,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textPrimary,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10.0),

            // Full-Width Card 5 (flex: 1 1 100%)
            MetricCard(
              minHeight: 65.0,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 14.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'recovery_drop',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.0,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    '$dropSign BPM',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 26.0,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textPrimary,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14.0),

            // Footnote (.m)
            const Text(
              'Runs on this phone · small neural network running locally in the app · 6 sessions available',
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.0,
                fontWeight: FontWeight.w300,
                color: AppColors.textMuted,
                letterSpacing: -0.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
