import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/signal/import_file_parser.dart';
import '../../shared/widgets/bottom_circle_nav.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/pill_button.dart';
import 'heart_rate_source.dart';
import 'widgets/mi_band_settings_dialog.dart';

/// Connect Device screen matching Device.dc.html and Connect device.png.
/// Supports multi-protocol BLE discovery (PulsePatch-C3, Mi Smart Band 5, Standard BLE 0x180D)
/// and file imports (CSV, JSON, Gadgetbridge exports).
class ConnectDeviceScreen extends ConsumerStatefulWidget {
  const ConnectDeviceScreen({
    super.key,
    this.onBack,
    this.onSelectTab,
    this.currentNavIndex = 3,
    this.showBottomNav = true,
  });

  final VoidCallback? onBack;
  final ValueChanged<int>? onSelectTab;
  final int currentNavIndex;
  final bool showBottomNav;

  @override
  ConsumerState<ConnectDeviceScreen> createState() =>
      _ConnectDeviceScreenState();
}

class _ConnectDeviceScreenState extends ConsumerState<ConnectDeviceScreen> {
  String? _connectingDeviceId;

  Future<void> _handleImportFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'json', 'txt'],
      );

      if (files.isEmpty) return;

      final file = files.first;
      final content = await file.xFile.readAsString();
      final parsed = ImportFileParser.parseFileContent(
        content,
        fileName: file.name,
      );
      final repo = ref.read(sessionRepositoryProvider);
      await repo.insertSession(
        session: parsed.session,
        samples: parsed.samples,
        stats: parsed.stats,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported session successfully (${parsed.samples.length} samples, ${parsed.stats.meanHr} BPM avg)',
          ),
          backgroundColor: AppColors.cardBgNavy,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Colors.red.shade900,
        ),
      );
    }
  }

  void _showMiBandSettings() {
    showDialog(
      context: context,
      builder: (context) => const MiBandSettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bleSource = ref.watch(heartRateSourceProvider);

    return DesignCanvasScaffold(
      bottomNavigationBar: widget.showBottomNav
          ? BottomCircleNav(
              currentIndex: widget.currentNavIndex,
              onTap: widget.onSelectTab ?? (_) {},
            )
          : null,
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
                onPressed:
                    widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
              const Text(
                'Connect device',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 22.0,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textPrimary,
                  height: 1.0,
                ),
              ),
              GestureDetector(
                onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: AppColors.cardBgGradientEnd,
                    builder: (ctx) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.file_upload,
                              color: Colors.white,
                            ),
                            title: const Text(
                              'Import CSV/JSON data',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              _handleImportFile();
                            },
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.settings,
                              color: Colors.white,
                            ),
                            title: const Text(
                              'Mi Band auth settings',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              _showMiBandSettings();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: const SizedBox(width: 56.0, height: 56.0),
              ),
            ],
          ),

          const SizedBox(height: 8.0),

          // Radar Scanner Illustration (width: 320, height: 250)
          const Center(
            child: SizedBox(
              width: 320.0,
              height: 250.0,
              child: CustomPaint(
                size: Size(320.0, 250.0),
                painter: _RadarScannerPainter(),
              ),
            ),
          ),

          // Scanning Subtitle
          StreamBuilder<BleConnectionState>(
            stream: bleSource.connectionStateStream,
            initialData: bleSource.currentState,
            builder: (context, snapshot) {
              final state = snapshot.data ?? BleConnectionState.idle;
              final String label;
              if (state == BleConnectionState.connected) {
                label = 'Connected to ${bleSource.sourceLabel}';
              } else if (state == BleConnectionState.connecting) {
                label = 'Connecting to peripheral...';
              } else {
                label = 'Scanning · keep the patch within 1 m';
              }
              return Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.0,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textMuted,
                ),
              );
            },
          ),

          const SizedBox(height: 12.0),

          // Dynamic Device List or Default Canvas Devices
          StreamBuilder<List<DiscoveredBleDevice>>(
            stream: bleSource.discoveredDevicesStream,
            builder: (context, snapshot) {
              final devices =
                  snapshot.data ??
                  [
                    const DiscoveredBleDevice(
                      id: 'sim-pulsepatch-1',
                      name: 'PulsePatch-C3',
                      rssi: -52,
                      category: BleDeviceCategory.pulsePatch,
                    ),
                    const DiscoveredBleDevice(
                      id: 'sim-pulsepatch-2',
                      name: 'PulsePatch-C3 (2)',
                      rssi: -85,
                      category: BleDeviceCategory.pulsePatch,
                    ),
                  ];

              return Column(
                children: devices.take(2).toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final dev = entry.value;
                  final isConnected =
                      bleSource.currentState == BleConnectionState.connected;
                  final isConnecting =
                      _connectingDeviceId == dev.id &&
                      bleSource.currentState == BleConnectionState.connecting;

                  final String minusRssi = '−${dev.rssi.abs()}';
                  final String signalText;
                  if (dev.rssi > -60) {
                    signalText = 'Signal strong · $minusRssi dBm';
                  } else if (dev.rssi > -75) {
                    signalText = 'Signal good · $minusRssi dBm';
                  } else {
                    signalText = 'Signal weak · $minusRssi dBm';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: MetricCard(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dev.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w300,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  signalText,
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
                          const SizedBox(width: 8.0),
                          PillButton(
                            label: isConnecting
                                ? 'Connecting'
                                : (isConnected
                                      ? 'Disconnect'
                                      : (dev.isCompatible
                                            ? 'Connect'
                                            : 'Unavailable')),
                            style: isConnected || index > 0
                                ? PillButtonStyle.dark
                                : PillButtonStyle.white,
                            onPressed: () async {
                              if (isConnected) {
                                await bleSource.disconnect();
                              } else if (dev.isCompatible) {
                                setState(() => _connectingDeviceId = dev.id);
                                await bleSource.connect(dev.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 12.0),

          // Hardware Footnote (.m)
          const Text(
            'Sensor: MAX30102 · Battery and firmware shown only if reported',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.0,
              fontWeight: FontWeight.w300,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarScannerPainter extends CustomPainter {
  const _RadarScannerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 320.0;
    final scaleY = size.height / 250.0;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    const center = Offset(160.0, 125.0);

    // Outer ring: r=115, stroke #3A2A8F opacity .4
    final outerPaint = Paint()
      ..color = const Color(0x663A2A8F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, 115.0, outerPaint);

    // Middle ring: r=80, stroke #3A2A8F opacity .6
    final midPaint = Paint()
      ..color = const Color(0x993A2A8F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, 80.0, midPaint);

    // Inner ring: r=45, stroke #4C8DF5
    final innerPaint = Paint()
      ..color = const Color(0xFF4C8DF5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, 45.0, innerPaint);

    // Center beacon: r=14, fill #C0148F
    final beaconPaint = Paint()
      ..color = const Color(0xFFC0148F)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 14.0, beaconPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
