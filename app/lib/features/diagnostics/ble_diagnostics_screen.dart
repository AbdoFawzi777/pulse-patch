import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/signal/ble_packet.dart';

/// Hidden diagnostic screen for BLE bring-up and packet validation.
/// Accessible via 7 taps on About screen version or in debug build.
class BleDiagnosticsScreen extends StatefulWidget {
  const BleDiagnosticsScreen({
    super.key,
    this.deviceName = 'PulsePatch Lite',
    this.deviceAddress = 'E8:6B:EA:D4:55:01',
    this.serviceUuid = '180D0000-7243-4E64-8843-50554C534531',
    this.charUuid = '180D0001-7243-4E64-8843-50554C534531',
    this.lastRawBytes,
    this.parsedPacket,
    this.packetsPerSecond = 0.0,
    this.sequenceGaps = 0,
    this.parseRejects = 0,
    this.rejectReason,
    this.rssi = -65,
  });

  final String deviceName;
  final String deviceAddress;
  final String serviceUuid;
  final String charUuid;
  final List<int>? lastRawBytes;
  final BlePacket? parsedPacket;
  final double packetsPerSecond;
  final int sequenceGaps;
  final int parseRejects;
  final String? rejectReason;
  final int? rssi;

  @override
  State<BleDiagnosticsScreen> createState() => _BleDiagnosticsScreenState();
}

class _BleDiagnosticsScreenState extends State<BleDiagnosticsScreen> {
  String _bytesToHex(List<int>? bytes) {
    if (bytes == null || bytes.isEmpty) return 'No packet received';
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.cardBgNavy,
        title: const Text(
          'BLE Diagnostics',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Diagnostic Banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade900.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade600),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'DIAGNOSTIC ONLY — Hardware Bring-Up & Telemetry',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Device & GATT Info Card
              _buildCard(
                title: 'Device & GATT Link',
                children: [
                  _buildRow('Device Name', widget.deviceName),
                  _buildRow('Address / ID', widget.deviceAddress),
                  _buildRow('Service UUID', widget.serviceUuid),
                  _buildRow('Measurement Char', widget.charUuid),
                  _buildRow(
                    'Signal (RSSI)',
                    widget.rssi != null ? '${widget.rssi} dBm' : 'N/A',
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Streaming Metrics Card
              _buildCard(
                title: 'Packet Stream Telemetry',
                children: [
                  _buildRow(
                    'Throughput',
                    '${widget.packetsPerSecond.toStringAsFixed(1)} pkts/sec',
                  ),
                  _buildRow(
                    'Sequence Gaps',
                    '${widget.sequenceGaps} dropped',
                    highlight: widget.sequenceGaps > 0,
                  ),
                  _buildRow(
                    'Parse Rejections',
                    '${widget.parseRejects}',
                    highlight: widget.parseRejects > 0,
                  ),
                  if (widget.rejectReason != null)
                    _buildRow(
                      'Last Reject Reason',
                      widget.rejectReason!,
                      highlight: true,
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Raw 12-Byte Hex Card
              _buildCard(
                title: 'Last Packet (Raw 12 Bytes Little-Endian)',
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      _bytesToHex(widget.lastRawBytes),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: AppColors.accentCyan,
                        fontSize: 14,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Parsed Struct Breakdown Card
              _buildCard(
                title: 'Decoded Payload Breakdown',
                children: widget.parsedPacket != null
                    ? [
                        _buildRow(
                          'Protocol Version',
                          '${widget.parsedPacket!.protocolVersion}',
                        ),
                        _buildRow(
                          'Contact Detected',
                          widget.parsedPacket!.contactDetected ? 'YES' : 'NO',
                        ),
                        _buildRow(
                          'Motion Suspected',
                          widget.parsedPacket!.motionSuspected ? 'YES' : 'NO',
                        ),
                        _buildRow(
                          'Raw BPM',
                          widget.parsedPacket!.rawBpm != null
                              ? '${widget.parsedPacket!.rawBpm!.toStringAsFixed(1)} BPM'
                              : '0xFFFF (Calculating / No Contact)',
                        ),
                        _buildRow(
                          'Signal Quality (SQI)',
                          '${widget.parsedPacket!.quality}%',
                        ),
                        _buildRow(
                          'Device Timestamp',
                          '${widget.parsedPacket!.deviceTimestampMs} ms',
                        ),
                        _buildRow(
                          'Sequence Number',
                          '#${widget.parsedPacket!.sequenceNumber}',
                        ),
                      ]
                    : [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No packet decoded yet. Connect device and start measurement.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBgNavy,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: highlight ? Colors.redAccent : AppColors.textPrimary,
                fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
