import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/preferences_repository.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/pill_button.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({
    super.key,
    required this.onFinish,
    required this.onBack,
  });

  final VoidCallback onFinish;
  final VoidCallback onBack;

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  PermissionStatus _bluetoothStatus = PermissionStatus.denied;
  PermissionStatus _notificationStatus = PermissionStatus.denied;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkInitialStatuses();
  }

  Future<void> _checkInitialStatuses() async {
    final btStatus = await Permission.bluetoothScan.status;
    final notifStatus = await Permission.notification.status;
    if (mounted) {
      setState(() {
        _bluetoothStatus = btStatus;
        _notificationStatus = notifStatus;
      });
    }
  }

  Future<void> _requestBluetooth() async {
    setState(() => _isLoading = true);
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    if (mounted) {
      setState(() {
        _bluetoothStatus =
            statuses[Permission.bluetoothScan] ??
            statuses[Permission.bluetoothConnect] ??
            PermissionStatus.denied;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestNotification() async {
    setState(() => _isLoading = true);
    final status = await Permission.notification.request();
    if (mounted) {
      setState(() {
        _notificationStatus = status;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleComplete() async {
    final prefs = ref.read(preferencesRepositoryProvider);
    await prefs.setOnboardingCompleted(true);
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final isBtGranted = _bluetoothStatus.isGranted;
    final isNotifGranted = _notificationStatus.isGranted;

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
                onPressed: widget.onBack,
              ),
              const Text(
                'Permissions',
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
          const SizedBox(height: 16.0),
          const Text(
            'Grant permissions to discover and connect with your PulsePatch hardware.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.0,
              fontWeight: FontWeight.w300,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20.0),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // Bluetooth Card
                MetricCard(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 44.0,
                        height: 44.0,
                        decoration: const BoxDecoration(
                          color: AppColors.cardBgNavy,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.bluetooth_searching_rounded,
                          color: isBtGranted
                              ? AppColors.accentCyan
                              : AppColors.textMuted,
                          size: 24.0,
                        ),
                      ),
                      const SizedBox(width: 14.0),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bluetooth Low Energy',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16.0,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2.0),
                            Text(
                              'Required for scanning and receiving real-time packets.',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.0,
                                fontWeight: FontWeight.w300,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      PillButton(
                        label: isBtGranted ? 'Granted' : 'Allow',
                        style: isBtGranted
                            ? PillButtonStyle.dark
                            : PillButtonStyle.white,
                        onPressed: isBtGranted ? null : _requestBluetooth,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14.0),
                // Notification Card
                MetricCard(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 44.0,
                        height: 44.0,
                        decoration: const BoxDecoration(
                          color: AppColors.cardBgNavy,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_active_outlined,
                          color: isNotifGranted
                              ? AppColors.accentCyan
                              : AppColors.textMuted,
                          size: 24.0,
                        ),
                      ),
                      const SizedBox(width: 14.0),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notifications',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16.0,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2.0),
                            Text(
                              'Optional reminders for scheduled rest measurements.',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.0,
                                fontWeight: FontWeight.w300,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      PillButton(
                        label: isNotifGranted ? 'Granted' : 'Allow',
                        style: isNotifGranted
                            ? PillButtonStyle.dark
                            : PillButtonStyle.white,
                        onPressed:
                            isNotifGranted ? null : _requestNotification,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          PillButton(
            label: 'Complete Setup',
            style: PillButtonStyle.white,
            width: double.infinity,
            height: 48.0,
            onPressed: _isLoading ? null : _handleComplete,
          ),
          const SizedBox(height: 10.0),
        ],
      ),
    );
  }
}
