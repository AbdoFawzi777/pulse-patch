import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/session_repository.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/heart_rate_hero_number.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/pill_button.dart';
import '../../shared/widgets/status_chip.dart';
import '../device/heart_rate_source.dart';
import 'widgets/layered_heart_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    required this.onStartMeasure,
    this.onOpenDevice,
    this.onOpenNotifications,
    this.onOpenProfile,
  });

  final VoidCallback onStartMeasure;
  final VoidCallback? onOpenDevice;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onOpenProfile;

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
        : 'Connect device';

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12.0),
                            // Header Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hi, there!',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 28.0,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      SizedBox(height: 2.0),
                                      Text(
                                        'How are you today?',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 22.0,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleIconButton(
                                      icon: Icons.person_outline_rounded,
                                      semanticLabel: 'Profile',
                                      onPressed: onOpenProfile,
                                    ),
                                    const SizedBox(width: 10.0),
                                    CircleIconButton(
                                      icon: Icons.notifications_none_rounded,
                                      semanticLabel: 'Notifications',
                                      onPressed: onOpenNotifications,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14.0),
                            // Status chips row
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 6.0,
                              children: [
                                GestureDetector(
                                  onTap: onOpenDevice,
                                  child: StatusChip(
                                    label: deviceChipText,
                                    variant: isConnected
                                        ? StatusChipVariant.active
                                        : StatusChipVariant.neutral,
                                    leadingDot: isConnected,
                                    dotColor: AppColors.accentCyan,
                                  ),
                                ),
                                StatusChip(
                                  label: bleSource.isSimulator
                                      ? 'Sample data'
                                      : 'Hardware',
                                  variant: StatusChipVariant.sample,
                                ),
                              ],
                            ),
                            // Centerpiece Illustration
                            const Spacer(),
                            const Center(child: LayeredHeartWidget()),
                            const Spacer(),
                            // Bottom two-card metrics row
                            Row(
                              children: [
                                // Left Card: Last Session
                                Expanded(
                                  child: MetricCard(
                                    minHeight: 180.0,
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Expanded(
                                              child: Text(
                                                'Last session',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 13.0,
                                                  fontWeight: FontWeight.w400,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                            if (latestSession != null) ...[
                                              const SizedBox(width: 4.0),
                                              const StatusChip(
                                                label: 'Saved',
                                                variant:
                                                    StatusChipVariant.neutral,
                                              ),
                                            ],
                                          ],
                                        ),
                                        Text(
                                          latestSession != null
                                              ? _formatTimestamp(
                                                  latestSession.startedAt,
                                                )
                                              : 'No sessions',
                                          style: const TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 13.0,
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                        HeartRateHeroNumber(
                                          bpm:
                                              latestStats?.meanHr.round() ??
                                              (latestSession != null
                                                  ? 74
                                                  : null),
                                          size: HeroNumberSize.card,
                                          isStale: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14.0),
                                // Right Card: AI Insights & Measure
                                Expanded(
                                  child: MetricCard(
                                    minHeight: 180.0,
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'AI Insights',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 13.0,
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          latestAi?.label == 'different'
                                              ? 'Different\npattern'
                                              : 'Typical\npattern',
                                          style: const TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 22.0,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textPrimary,
                                            height: 1.15,
                                          ),
                                        ),
                                        PillButton(
                                          label: 'Measure',
                                          style: PillButtonStyle.white,
                                          width: double.infinity,
                                          height: 46.0,
                                          onPressed: onStartMeasure,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
