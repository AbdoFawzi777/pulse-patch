import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/pill_button.dart';

/// Screen providing actionable step-by-step diagnostic and troubleshooting guidance.
/// Derived screen #7 adhering strictly to design tokens.
class DeviceTroubleshootingScreen extends StatelessWidget {
  const DeviceTroubleshootingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DesignCanvasScaffold(
      child: Column(
        children: [
          // Top Bar
          Row(
            children: [
              CircleIconButton(
                type: CircleIconType.back,
                semanticLabel: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Troubleshooting',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22.0,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 56.0),
            ],
          ),
          const SizedBox(height: 12.0),

          // Content List
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                _buildTroubleshootCard(
                  icon: Icons.bluetooth_disabled_rounded,
                  title: 'Bluetooth is Disabled',
                  issue: 'Phone Bluetooth is turned off or in airplane mode.',
                  steps: [
                    'Open Quick Settings or device settings.',
                    'Turn on Bluetooth.',
                    'Return to PulsePatch Lite and retry scanning.',
                  ],
                  actionLabel: 'Open System Settings',
                  onAction: () => openAppSettings(),
                ),
                const SizedBox(height: 14.0),
                _buildTroubleshootCard(
                  icon: Icons.security_rounded,
                  title: 'Permissions Denied',
                  issue:
                      'Bluetooth or Location permissions are permanently denied.',
                  steps: [
                    'Android 12+ requires "Nearby Devices" permission.',
                    'Android 11 and earlier requires "Location" access for BLE scanning.',
                    'Open App Info and grant Nearby Devices permission.',
                  ],
                  actionLabel: 'App Permissions',
                  onAction: () => openAppSettings(),
                ),
                const SizedBox(height: 14.0),
                _buildTroubleshootCard(
                  icon: Icons.radar_rounded,
                  title: 'Device Not Found During Scan',
                  issue: 'The ESP32-C3 patch is not detected by the phone.',
                  steps: [
                    'Ensure the patch is powered (check board LED).',
                    'Keep the device within 1 meter of the phone.',
                    'Ensure another phone is not already connected to it.',
                    'Cycle power to the ESP32-C3 board.',
                  ],
                  actionLabel: null,
                  onAction: null,
                ),
                const SizedBox(height: 14.0),
                _buildTroubleshootCard(
                  icon: Icons.fingerprint_rounded,
                  title: 'Weak Optical Signal / Noise',
                  issue: 'Signal quality is below 60 or jumping erratically.',
                  steps: [
                    'Gently rest your fingertip over the MAX30102 sensor.',
                    'Do NOT press too hard: excessive pressure restricts capillary blood flow.',
                    'Keep your hand and arm completely motionless.',
                    'Ensure ambient sunlight is not saturating the photodiode.',
                  ],
                  actionLabel: null,
                  onAction: null,
                ),
                const SizedBox(height: 14.0),
                _buildTroubleshootCard(
                  icon: Icons.developer_board_off_rounded,
                  title: 'Sensor Communication Error (I2C)',
                  issue:
                      'ESP32-C3 firmware reports MAX30102 sensor initialization failure.',
                  steps: [
                    'Verify 3.3V power and ground wiring to MAX30102.',
                    'Check I2C SDA pin is connected to GPIO4.',
                    'Check I2C SCL pin is connected to GPIO5.',
                    'Ensure I2C pull-up resistors (4.7kΩ) are present.',
                  ],
                  actionLabel: null,
                  onAction: null,
                ),
                const SizedBox(height: 24.0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootCard({
    required IconData icon,
    required String title,
    required String issue,
    required List<String> steps,
    required String? actionLabel,
    required VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.6, -0.8),
          end: Alignment(0.6, 0.8),
          colors: [Color(0xFF0F2160), Color(0xFF08122E)],
        ),
        borderRadius: BorderRadius.circular(22.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Icon(icon, color: AppColors.accentCyan, size: 22.0),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18.0,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Text(
            issue,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.0,
              fontWeight: FontWeight.w500,
              color: AppColors.accentMagenta,
            ),
          ),
          const SizedBox(height: 10.0),
          ...steps.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$idx. ',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentCyan,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      step,
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
            );
          }),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14.0),
            PillButton(
              label: actionLabel,
              style: PillButtonStyle.white,
              onPressed: onAction,
              height: 44.0,
            ),
          ],
        ],
      ),
    );
  }
}
