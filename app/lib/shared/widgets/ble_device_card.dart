import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'metric_card.dart';
import 'pill_button.dart';

/// Device card matching Connect device.png layout.
class BleDeviceCard extends StatelessWidget {
  const BleDeviceCard({
    super.key,
    required this.name,
    required this.rssi,
    required this.onConnect,
    this.isConnected = false,
    this.isConnecting = false,
    this.isPrimary = true,
  });

  final String name;
  final int rssi;
  final VoidCallback onConnect;
  final bool isConnected;
  final bool isConnecting;
  final bool isPrimary;

  String get _signalStrength {
    if (rssi >= -65) return 'Signal strong';
    if (rssi >= -75) return 'Signal good';
    if (rssi >= -85) return 'Signal fair';
    return 'Signal weak';
  }

  @override
  Widget build(BuildContext context) {
    final statusText = '$_signalStrength · $rssi dBm';

    return MetricCard(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 17.0,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  statusText,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12.0),
          PillButton(
            label: isConnected
                ? 'Disconnect'
                : isConnecting
                ? 'Connecting'
                : 'Connect',
            style: isPrimary ? PillButtonStyle.white : PillButtonStyle.dark,
            height: 42.0,
            onPressed: isConnecting ? null : onConnect,
          ),
        ],
      ),
    );
  }
}
