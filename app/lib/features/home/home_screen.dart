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
import '../bp/bp_monitoring_screen.dart';
import '../doctors/doctor_discovery_screen.dart';
import '../device/heart_rate_source.dart';
import '../knowledge/medical_knowledge_assistant_screen.dart';
import '../reports/reports_screen.dart';
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

    final connectionState = bleSource.currentState;
    final isConnected = connectionState == BleConnectionState.connected ||
        connectionState == BleConnectionState.streaming;
    final isScanning = connectionState == BleConnectionState.scanning;
    final isConnecting = connectionState == BleConnectionState.connecting ||
        connectionState == BleConnectionState.discovering ||
        connectionState == BleConnectionState.subscribing;

    final deviceChipText = isConnected
        ? 'Connected · ${bleSource.sourceLabel}'
        : 'No device connected';

    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final String statusBadgeText;
    final Color statusBadgeBg;
    final Color statusBadgeColor;
    final String connectionSubtitle;

    if (isConnected) {
      statusBadgeText = isRtl ? 'متصل' : 'Connected';
      statusBadgeBg = const Color(0xFF10B981).withValues(alpha: 0.2);
      statusBadgeColor = const Color(0xFF10B981);
      connectionSubtitle = isRtl
          ? 'متصل · ${bleSource.sourceLabel}'
          : 'Connected · ${bleSource.sourceLabel}';
    } else if (isConnecting) {
      statusBadgeText = isRtl ? 'جاري الاتصال...' : 'Connecting...';
      statusBadgeBg = const Color(0xFFF59E0B).withValues(alpha: 0.2);
      statusBadgeColor = const Color(0xFFF59E0B);
      connectionSubtitle = isRtl
          ? 'جاري إنشاء اتصال BLE...'
          : 'Negotiating BLE telemetry...';
    } else if (isScanning) {
      statusBadgeText = isRtl ? 'جاري البحث...' : 'Scanning...';
      statusBadgeBg = AppColors.accentCyan.withValues(alpha: 0.2);
      statusBadgeColor = AppColors.accentCyan;
      connectionSubtitle = isRtl
          ? 'البحث عن أجهزة مستشعر النبض...'
          : 'Scanning nearby BLE sensors...';
    } else {
      statusBadgeText = isRtl ? 'غير متصل' : 'Not Connected';
      statusBadgeBg = AppColors.cardBorder.withValues(alpha: 0.6);
      statusBadgeColor = AppColors.textMuted;
      connectionSubtitle = isRtl
          ? 'اضغط للبحث عن مستشعر PulsePatch والاقتران'
          : 'Tap to discover and pair your sensor';
    }

    final sessionTimestamp = latestSession != null
        ? _formatTimestamp(latestSession.startedAt)
        : 'No sessions yet';

    final bpmValue = latestStats?.meanHr.round();
    final aiPatternText = latestAi?.label ?? 'No data';

    return DesignCanvasScaffold(
      padding: const EdgeInsets.fromLTRB(20.0, 28.0, 20.0, 20.0),
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

            const SizedBox(height: 12.0),

            // Prominent Device Connection Card (Phase 2)
            MetricCard(
              key: const Key('home_device_connection_card'),
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              child: InkWell(
                onTap: onOpenDevice,
                borderRadius: BorderRadius.circular(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 44.0,
                      height: 44.0,
                      decoration: BoxDecoration(
                        color: isConnected
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : (isScanning || isConnecting
                                ? AppColors.accentCyan.withValues(alpha: 0.15)
                                : AppColors.cardBorder.withValues(alpha: 0.4)),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          isConnected
                              ? Icons.bluetooth_connected_rounded
                              : (isScanning
                                  ? Icons.bluetooth_searching_rounded
                                  : (isConnecting
                                      ? Icons.bluetooth_audio_rounded
                                      : Icons.bluetooth_rounded)),
                          color: isConnected
                              ? const Color(0xFF10B981)
                              : (isScanning || isConnecting
                                  ? AppColors.accentCyan
                                  : AppColors.textMuted),
                          size: 22.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  isRtl
                                      ? 'اتصال بجهاز PulsePatch'
                                      : 'Connect PulsePatch Device',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 2.0,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBadgeBg,
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: Text(
                                  statusBadgeText,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.w600,
                                    color: statusBadgeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3.0),
                          Text(
                            connectionSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.0,
                              fontWeight: FontWeight.w300,
                              color: AppColors.textSubtitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    if (!isConnected)
                      PillButton(
                        label: isRtl ? 'اقتران' : 'Pair',
                        style: PillButtonStyle.white,
                        height: 32.0,
                        onPressed: onOpenDevice,
                      )
                    else
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF10B981),
                        size: 20.0,
                      ),
                  ],
                ),
              ),
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
            Transform.translate(
              offset: const Offset(0.0, -11.0),
              child: const Center(
                child: LayeredHeartWidget(width: 330.0, height: 300.0),
              ),
            ),

            // Two-Card Metric Row with exact card overlap (-70px in CSS)
            Transform.translate(
              offset: const Offset(0.0, -82.0),
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
                                  bpmValue != null ? '$bpmValue ' : '-- ',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 44.0,
                                    fontWeight: FontWeight.w300,
                                    color: AppColors.textPrimary,
                                    height: 1.0,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
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

            // Quick Health Overview & Clinical Services
            Transform.translate(
              offset: const Offset(0.0, -66.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Health Overview Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Health Services & Vitals',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18.0,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'Clinical Grade',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.0,
                          fontWeight: FontWeight.w300,
                          color: AppColors.accentCyan.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),

                  // Mini Vitals Summary
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 12.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8.0,
                                    height: 8.0,
                                    decoration: const BoxDecoration(
                                      color: AppColors.accentCyan,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6.0),
                                  const Expanded(
                                    child: Text(
                                      'Blood Oxygen',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w300,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6.0),
                              const Text(
                                '98%',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Text(
                                'Optimal resting',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.0,
                                  color: AppColors.textSubtitle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: MetricCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 12.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8.0,
                                    height: 8.0,
                                    decoration: const BoxDecoration(
                                      color: AppColors.accentGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6.0),
                                  const Expanded(
                                    child: Text(
                                      'Signal Quality',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w300,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6.0),
                              const Text(
                                'Good',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Text(
                                'Low motion artifact',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.0,
                                  color: AppColors.textSubtitle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // Quick Action Shortcuts Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    childAspectRatio: 2.1,
                    children: [
                      _QuickActionTile(
                        icon: Icons.picture_as_pdf_outlined,
                        title: 'PDF Reports',
                        subtitle: 'Clinical export',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReportsScreen(
                                onBack: () => Navigator.of(context).maybePop(),
                              ),
                            ),
                          );
                        },
                      ),
                      _QuickActionTile(
                        icon: Icons.speed_rounded,
                        title: 'BP Research',
                        subtitle: 'PPG model inference',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BpMonitoringScreen(),
                            ),
                          );
                        },
                      ),
                      _QuickActionTile(
                        icon: Icons.local_hospital_outlined,
                        title: 'Find Doctors',
                        subtitle: 'Specialists & clinics',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DoctorDiscoveryScreen(),
                            ),
                          );
                        },
                      ),
                      _QuickActionTile(
                        icon: Icons.smart_toy_outlined,
                        title: 'Medical AI',
                        subtitle: 'Evidence assistant',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const MedicalKnowledgeAssistantScreen(),
                            ),
                          );
                        },
                      ),
                    ],
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

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MetricCard(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: AppColors.accentCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Icon(
                icon,
                color: AppColors.accentCyan,
                size: 20.0,
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.0,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.0,
                      color: AppColors.textSubtitle,
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
}
