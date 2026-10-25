import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/pill_button.dart';

enum SystemStateType {
  firstLaunch,
  bluetoothOff,
  permissionDenied,
  scanning,
  connecting,
  connected,
  disconnected,
  reconnecting,
  noSensorData,
  weakSignal,
  invalidMeasurement,
  measuring,
  completed,
  modelLoading,
  analyzing,
  modelUnavailable,
  insufficientData,
  noHistory,
  storageFailure,
  exportFailure,
  unexpectedError,
}

class SystemStateInfo {
  const SystemStateInfo({
    required this.type,
    required this.title,
    required this.message,
    required this.actionLabel,
    this.icon = Icons.info_outline_rounded,
    this.isCritical = false,
  });

  final SystemStateType type;
  final String title;
  final String message;
  final String actionLabel;
  final IconData icon;
  final bool isCritical;

  static SystemStateInfo forType(SystemStateType type) {
    switch (type) {
      case SystemStateType.firstLaunch:
        return const SystemStateInfo(
          type: SystemStateType.firstLaunch,
          title: 'Welcome to PulsePatch Lite',
          message:
              'Connect your ESP32-C3 pulse patch or launch the simulator to start.',
          actionLabel: 'Get Started',
          icon: Icons.waving_hand_rounded,
        );
      case SystemStateType.bluetoothOff:
        return const SystemStateInfo(
          type: SystemStateType.bluetoothOff,
          title: 'Bluetooth is Disabled',
          message:
              'Enable Bluetooth on your phone to scan and pair with your pulse sensor.',
          actionLabel: 'Open Bluetooth Settings',
          icon: Icons.bluetooth_disabled_rounded,
        );
      case SystemStateType.permissionDenied:
        return const SystemStateInfo(
          type: SystemStateType.permissionDenied,
          title: 'Bluetooth Permission Required',
          message:
              'Grant Nearby Devices access so PulsePatch can discover your sensor.',
          actionLabel: 'Grant Permission',
          icon: Icons.lock_outline_rounded,
        );
      case SystemStateType.scanning:
        return const SystemStateInfo(
          type: SystemStateType.scanning,
          title: 'Scanning for Sensor',
          message:
              'Searching for PulsePatch BLE device. Keep patch within 1 meter.',
          actionLabel: 'Cancel Scan',
          icon: Icons.radar_rounded,
        );
      case SystemStateType.connecting:
        return const SystemStateInfo(
          type: SystemStateType.connecting,
          title: 'Connecting...',
          message: 'Establishing encrypted GATT connection with ESP32-C3.',
          actionLabel: 'Cancel',
          icon: Icons.sync_rounded,
        );
      case SystemStateType.connected:
        return const SystemStateInfo(
          type: SystemStateType.connected,
          title: 'Sensor Connected',
          message: 'Pulse telemetry active. Ready to measure pulse rate.',
          actionLabel: 'Start Measuring',
          icon: Icons.bluetooth_connected_rounded,
        );
      case SystemStateType.disconnected:
        return const SystemStateInfo(
          type: SystemStateType.disconnected,
          title: 'Sensor Disconnected',
          message: 'BLE connection dropped. Verify sensor power and range.',
          actionLabel: 'Reconnect',
          icon: Icons.bluetooth_disabled_rounded,
        );
      case SystemStateType.reconnecting:
        return const SystemStateInfo(
          type: SystemStateType.reconnecting,
          title: 'Reconnecting...',
          message: 'Attempting to restore wireless link with PulsePatch.',
          actionLabel: 'Cancel',
          icon: Icons.autorenew_rounded,
        );
      case SystemStateType.noSensorData:
        return const SystemStateInfo(
          type: SystemStateType.noSensorData,
          title: 'No Optical Telemetry',
          message: 'Sensor is paired but no pulse data is being received.',
          actionLabel: 'Troubleshoot',
          icon: Icons.sensors_off_rounded,
        );
      case SystemStateType.weakSignal:
        return const SystemStateInfo(
          type: SystemStateType.weakSignal,
          title: 'Weak Optical Signal',
          message:
              'Quality score is low. Press fingertip firmly and remain still.',
          actionLabel: 'Adjust Placement',
          icon: Icons.signal_cellular_alt_1_bar_rounded,
        );
      case SystemStateType.invalidMeasurement:
        return const SystemStateInfo(
          type: SystemStateType.invalidMeasurement,
          title: 'Measurement Incomplete',
          message:
              'Not enough valid samples passed quality filters to record stats.',
          actionLabel: 'Try Again',
          icon: Icons.replay_rounded,
        );
      case SystemStateType.measuring:
        return const SystemStateInfo(
          type: SystemStateType.measuring,
          title: 'Recording Pulse',
          message: 'Capturing optical pulse waveform and heart rate telemetry.',
          actionLabel: 'Stop and Save',
          icon: Icons.favorite_rounded,
        );
      case SystemStateType.completed:
        return const SystemStateInfo(
          type: SystemStateType.completed,
          title: 'Session Complete',
          message: 'Pulse session recorded and statistics computed.',
          actionLabel: 'View Insights',
          icon: Icons.check_circle_outline_rounded,
        );
      case SystemStateType.modelLoading:
        return const SystemStateInfo(
          type: SystemStateType.modelLoading,
          title: 'Loading Model',
          message:
              'Initializing local small neural network inference isolate...',
          actionLabel: 'Wait',
          icon: Icons.hourglass_top_rounded,
        );
      case SystemStateType.analyzing:
        return const SystemStateInfo(
          type: SystemStateType.analyzing,
          title: 'Analyzing Patterns',
          message:
              'Evaluating session features against educational model weights.',
          actionLabel: 'Processing',
          icon: Icons.psychology_rounded,
        );
      case SystemStateType.modelUnavailable:
        return const SystemStateInfo(
          type: SystemStateType.modelUnavailable,
          title: 'AI Model Unavailable',
          message:
              'Model asset could not be loaded. Standard statistics remain available.',
          actionLabel: 'View Stats',
          icon: Icons.error_outline_rounded,
        );
      case SystemStateType.insufficientData:
        return const SystemStateInfo(
          type: SystemStateType.insufficientData,
          title: 'Insufficient Data for AI',
          message: 'Requires at least 30 seconds of valid pulse samples.',
          actionLabel: 'Record 60s Session',
          icon: Icons.timer_outlined,
        );
      case SystemStateType.noHistory:
        return const SystemStateInfo(
          type: SystemStateType.noHistory,
          title: 'No Recorded History',
          message:
              'Recorded sessions will appear here with trends and PDF reports.',
          actionLabel: 'Record First Session',
          icon: Icons.history_rounded,
        );
      case SystemStateType.storageFailure:
        return const SystemStateInfo(
          type: SystemStateType.storageFailure,
          title: 'Storage Error',
          message: 'Could not access local SQLite database on disk.',
          actionLabel: 'Retry',
          icon: Icons.sd_card_alert_rounded,
          isCritical: true,
        );
      case SystemStateType.exportFailure:
        return const SystemStateInfo(
          type: SystemStateType.exportFailure,
          title: 'Export Failed',
          message: 'Could not generate report file or share intent.',
          actionLabel: 'Retry Export',
          icon: Icons.upload_file_rounded,
        );
      case SystemStateType.unexpectedError:
        return const SystemStateInfo(
          type: SystemStateType.unexpectedError,
          title: 'Unexpected Application Error',
          message:
              'A safe recovery boundary caught an unhandled runtime event.',
          actionLabel: 'Reset View',
          icon: Icons.bug_report_rounded,
          isCritical: true,
        );
    }
  }
}

/// Reusable banner component displaying system states and recovery actions.
class SystemStateBanner extends StatelessWidget {
  const SystemStateBanner({
    super.key,
    required this.stateType,
    required this.onAction,
  });

  final SystemStateType stateType;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final info = SystemStateInfo.forType(stateType);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: info.isCritical
            ? Colors.red.withValues(alpha: 0.12)
            : AppColors.cardBgNavy,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(
          color: info.isCritical
              ? Colors.red.withValues(alpha: 0.4)
              : AppColors.cardBorder,
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            info.icon,
            color: info.isCritical ? Colors.redAccent : AppColors.accentCyan,
            size: 24.0,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.0,
                    fontWeight: FontWeight.w600,
                    color: info.isCritical
                        ? Colors.redAccent
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  info.message,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.0,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10.0),
                PillButton(
                  label: info.actionLabel,
                  style: info.isCritical
                      ? PillButtonStyle.dark
                      : PillButtonStyle.white,
                  onPressed: onAction,
                  height: 36.0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
