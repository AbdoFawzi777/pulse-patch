import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/preferences_repository.dart';
import '../../shared/widgets/circle_icon_button.dart';
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

  Future<void> _completeOnboarding() async {
    final prefs = ref.read(preferencesRepositoryProvider);
    await prefs.setOnboardingCompleted(true);
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final hasPermanentlyDenied =
        _bluetoothStatus.isPermanentlyDenied ||
        _notificationStatus.isPermanentlyDenied;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        children: [
          // Background corner glow
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12.0),
                  CircleIconButton(
                    icon: Icons.chevron_left_rounded,
                    semanticLabel: 'Back',
                    onPressed: widget.onBack,
                  ),
                  const SizedBox(height: 20.0),
                  const Text(
                    'Permissions',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 28.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  const Text(
                    'PulsePatch Lite requires Bluetooth to communicate with your patch hardware.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Bluetooth permission card
                        _PermissionCard(
                          icon: Icons.bluetooth_rounded,
                          title: 'Bluetooth Low Energy',
                          description:
                              'Used exclusively to discover and stream optical pulse telemetry from your ESP32-C3 patch.',
                          status: _bluetoothStatus,
                          onRequest: _requestBluetooth,
                        ),
                        const SizedBox(height: 16.0),
                        // Notification permission card
                        _PermissionCard(
                          icon: Icons.notifications_active_rounded,
                          title: 'Measurement Alerts',
                          description:
                              'Alerts you when a timed pulse session finishes, without keeping your screen on continuously.',
                          status: _notificationStatus,
                          onRequest: _requestNotification,
                        ),
                        if (hasPermanentlyDenied) ...[
                          const SizedBox(height: 20.0),
                          MetricCard(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.settings_outlined,
                                  color: AppColors.accentCyan,
                                  size: 24.0,
                                ),
                                const SizedBox(width: 12.0),
                                const Expanded(
                                  child: Text(
                                    'A permission was permanently denied. Open Settings to grant access.',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 13.0,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: openAppSettings,
                                  child: const Text(
                                    'Settings',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accentBlue,
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
                  PillButton(
                    label: _isLoading ? 'Checking...' : 'Finish Setup',
                    style: PillButtonStyle.white,
                    width: double.infinity,
                    height: 52.0,
                    onPressed: _isLoading ? null : _completeOnboarding,
                  ),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.onRequest,
  });

  final IconData icon;
  final String title;
  final String description;
  final PermissionStatus status;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final isGranted = status.isGranted;

    return MetricCard(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.0,
                height: 40.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF131D44),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Icon(
                  icon,
                  color: isGranted
                      ? AppColors.accentCyan
                      : AppColors.textSecondary,
                  size: 20.0,
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (isGranted)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 22.0,
                )
              else
                PillButton(
                  label: 'Allow',
                  style: PillButtonStyle.white,
                  height: 38.0,
                  width: 80.0,
                  onPressed: onRequest,
                ),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            description,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.0,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
