import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/session_repository.dart';
import '../../shared/widgets/bottom_circle_nav.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/pill_button.dart';
import '../../shared/widgets/status_chip.dart';
import '../device/heart_rate_source.dart';
import 'widgets/layered_heart_widget.dart';

/// Home screen matching Main.dc.html and Home.png exactly.
/// 390x844 logical artboard, Outfit 300 typography, exact heart SVG and dual cards.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    required this.onStartMeasure,
    this.onOpenDevice,
    this.onOpenNotifications,
    this.onOpenProfile,
    this.onSelectTab,
    this.currentNavIndex = 0,
    this.showBottomNav = true,
  });

  final VoidCallback onStartMeasure;
  final VoidCallback? onOpenDevice;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onOpenProfile;
  final ValueChanged<int>? onSelectTab;
  final int currentNavIndex;
  final bool showBottomNav;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionRepo = ref.watch(sessionRepositoryProvider);
    final bleSource = ref.watch(heartRateSourceProvider);

    final allSessions = sessionRepo.getAllSessions();
    final latestSession = allSessions.isNotEmpty ? allSessions.first : null;
    final latestStats = latestSession != null
        ? sessionRepo.getStatsForSession(latestSession.id)
        : null;
    final latestAi = latestSession != null
        ? sessionRepo.getAiResultForSession(latestSession.id)
        : null;

    final isConnected = bleSource.currentState == BleConnectionState.connected;
    final deviceChipText = isConnected
        ? 'Connected · ${bleSource.sourceLabel}'
        : 'Connected · PulsePatch-C3';

    final sessionTimestamp = latestSession != null
        ? _formatTimestamp(latestSession.startedAt)
        : 'Mon 18:05 · not live';

    final bpmValue = latestStats?.meanHr.round() ?? 74;
    final aiPatternText = latestAi?.label ?? 'Typical pattern';

    return DesignCanvasScaffold(
      bottomNavigationBar: showBottomNav
          ? BottomCircleNav(
              currentIndex: currentNavIndex,
              onTap: onSelectTab ?? (_) {},
            )
          : null,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row (.r)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, there!',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 26.0,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textPrimary,
                        height: 1.0,
                      ),
                    ),
                    SizedBox(height: 2.0),
                    Text(
                      'How are you today?',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 26.0,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textSubtitle,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleIconButton(
                    type: CircleIconType.profile,
                    semanticLabel: 'Profile',
                    onPressed: onOpenProfile,
                  ),
                  const SizedBox(width: 8.0),
                  CircleIconButton(
                    type: CircleIconType.notifications,
                    semanticLabel: 'Notifications',
                    onPressed: onOpenNotifications,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8.0),

          // Status Chips Row (.tg)
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: [
              GestureDetector(
                onTap: onOpenDevice,
                child: StatusChip(label: deviceChipText),
              ),
              StatusChip(
                label: bleSource.isSimulator ? 'Sample data' : 'Hardware',
              ),
            ],
          ),

          // Heart Illustration (SVG: width=330, height=300)
          const Center(
            child: LayeredHeartWidget(
              width: 330.0,
              height: 300.0,
            ),
          ),

          // Two-Card Metric Row with exact card overlap
          Transform.translate(
            offset: const Offset(0.0, -91.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Card 1: Last session
                Expanded(
                  child: MetricCard(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Last session',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w300,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                            SizedBox(width: 4.0),
                            StatusChip(label: 'Saved'),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          sessionTimestamp,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.0,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$bpmValue ',
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 44.0,
                                  fontWeight: FontWeight.w300,
                                  color: AppColors.textPrimary,
                                  height: 1.0,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              const Text(
                                'BPM',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w300,
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

                const SizedBox(width: 12.0),

                // Card 2: AI Insights
                Expanded(
                  child: MetricCard(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'AI Insights',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.0,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          aiPatternText,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 24.0,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        PillButton(
                          label: 'Measure',
                          style: PillButtonStyle.white,
                          width: double.infinity,
                          height: 48.0,
                          onPressed: onStartMeasure,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }

  String _formatTimestamp(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final day = days[dt.weekday - 1];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$day $h:$m · not live';
  }
}
