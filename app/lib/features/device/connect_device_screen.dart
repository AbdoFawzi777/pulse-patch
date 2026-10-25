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
  String? _checkingDeviceId;
  final Map<String, DiscoveredBleDevice> _compatibilityResults = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(heartRateSourceProvider).startScan();
    });
  }

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

  Future<void> _handleCheckCompatibility(DiscoveredBleDevice dev) async {
    setState(() => _checkingDeviceId = dev.id);
    try {
      final res = await ref
          .read(heartRateSourceProvider)
          .checkCompatibility(dev.id);
      if (res != null && mounted) {
        setState(() {
          _compatibilityResults[dev.id] = res;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _checkingDeviceId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bleSource = ref.watch(heartRateSourceProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return DesignCanvasScaffold(
      bottomNavigationBar: widget.showBottomNav
          ? BottomCircleNav(
              currentIndex: widget.currentNavIndex,
              onTap: widget.onSelectTab ?? (_) {},
            )
          : null,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Header Row (.r)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleIconButton(
                    type: CircleIconType.back,
                    semanticLabel: 'Back',
                    onPressed:
                        widget.onBack ?? () => Navigator.of(context).maybePop(),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Connect device',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 22.0,
                          fontWeight: FontWeight.w300,
                          color: AppColors.textPrimary,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
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
                    child: Container(
                      width: 56.0,
                      height: 56.0,
                      decoration: const BoxDecoration(
                        color: AppColors.cardBgNavy,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.more_horiz,
                          color: AppColors.textPrimary,
                          size: 22.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Radar Scanner Illustration (shrinks smoothly when scrolling)
          SliverPersistentHeader(
            pinned: false,
            delegate: _RadarHeaderDelegate(
              onTap: () => ref.read(heartRateSourceProvider).startScan(),
            ),
          ),

          // Scanning Subtitle
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: StreamBuilder<BleConnectionState>(
                stream: bleSource.connectionStateStream,
                initialData: bleSource.currentState,
                builder: (context, snapshot) {
                  final state = snapshot.data ?? BleConnectionState.idle;
                  final String label;
                  if (state == BleConnectionState.connected ||
                      state == BleConnectionState.streaming) {
                    label = 'Connected to ${bleSource.sourceLabel}';
                  } else if (state == BleConnectionState.connecting ||
                      state == BleConnectionState.discovering) {
                    label = 'Connecting to peripheral...';
                  } else if (state == BleConnectionState.subscribing) {
                    label = 'Subscribing to heart rate telemetry...';
                  } else if (state == BleConnectionState.blocked) {
                    label = 'Heart rate stream blocked by device';
                  } else if (state == BleConnectionState.scanning) {
                    label = 'Scanning · keep the patch within 1 m';
                  } else {
                    label = 'Ready · tap radar to scan nearby devices';
                  }
                  return Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.0,
                      fontWeight: FontWeight.w300,
                      color: state == BleConnectionState.blocked
                          ? const Color(0xFFEF4444)
                          : AppColors.textMuted,
                    ),
                  );
                },
              ),
            ),
          ),

          // Blocked Alert Banner if state is blocked
          StreamBuilder<BleConnectionState>(
            stream: bleSource.connectionStateStream,
            initialData: bleSource.currentState,
            builder: (context, snapshot) {
              final isBlocked = snapshot.data == BleConnectionState.blocked;
              if (!isBlocked) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: MetricCard(
                    borderColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              color: Color(0xFFEF4444),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Heart-rate access blocked by device',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This band blocks heart-rate access from third-party apps in its current state (GATT status: 3 WRITE_NOT_PERMITTED). The firmware refuses descriptor writes to 0x2A37 without proprietary authentication.',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: PillButton(
                                label: 'Import session file',
                                style: PillButtonStyle.white,
                                onPressed: _handleImportFile,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: PillButton(
                                label: 'Use simulator',
                                style: PillButtonStyle.dark,
                                onPressed: () =>
                                    bleSource.connect('sim-sample'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Real Discovered Devices List
          StreamBuilder<List<DiscoveredBleDevice>>(
            stream: bleSource.discoveredDevicesStream,
            builder: (context, snapshot) {
              final rawDevices = snapshot.data ?? [];
              // Filter out simulated devices from real scan list
              final devices = rawDevices
                  .where((d) => !d.id.startsWith('sim-'))
                  .toList();

              // Sort: connected first, then by RSSI
              devices.sort((a, b) => b.rssi.compareTo(a.rssi));

              if (devices.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text(
                        bleSource.currentState == BleConnectionState.scanning
                            ? 'Scanning for nearby Bluetooth devices...'
                            : 'No real devices found nearby.\nTap radar to scan or use simulator below.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.0,
                          fontWeight: FontWeight.w300,
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final dev = devices[index];
                  final updatedDev = _compatibilityResults[dev.id] ?? dev;
                  final isConnected =
                      bleSource.currentState == BleConnectionState.connected ||
                      bleSource.currentState == BleConnectionState.streaming;
                  final isConnecting =
                      _connectingDeviceId == dev.id &&
                      (bleSource.currentState ==
                              BleConnectionState.connecting ||
                          bleSource.currentState ==
                              BleConnectionState.subscribing);
                  final isChecking = _checkingDeviceId == dev.id;

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dev.name.isNotEmpty
                                          ? dev.name
                                          : 'Unnamed Device',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 17.0,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2.0),
                                    Text(
                                      '${dev.maskedId} · $signalText',
                                      style: const TextStyle(
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
                              if (isChecking)
                                const SizedBox(
                                  width: 88,
                                  height: 36,
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.accentCyan,
                                      ),
                                    ),
                                  ),
                                )
                              else if (isConnected)
                                PillButton(
                                  label: 'Disconnect',
                                  style: PillButtonStyle.dark,
                                  onPressed: () => bleSource.disconnect(),
                                )
                              else if (isConnecting)
                                const PillButton(
                                  label: 'Connecting',
                                  style: PillButtonStyle.dark,
                                  onPressed: null,
                                )
                              else if (updatedDev.isCompatible)
                                PillButton(
                                  label: 'Connect',
                                  style: PillButtonStyle.white,
                                  onPressed: () async {
                                    setState(
                                      () => _connectingDeviceId = dev.id,
                                    );
                                    try {
                                      await bleSource.connect(dev.id);
                                    } finally {
                                      if (mounted) {
                                        setState(
                                          () => _connectingDeviceId = null,
                                        );
                                      }
                                    }
                                  },
                                )
                              else
                                PillButton(
                                  label: 'Check compatibility',
                                  style: PillButtonStyle.dark,
                                  onPressed: () =>
                                      _handleCheckCompatibility(dev),
                                ),
                            ],
                          ),

                          // Badges Row: Heart Rate (0x180D), SpO2 (0x1822), PulsePatch, Mi Band
                          const SizedBox(height: 8.0),
                          Wrap(
                            spacing: 6.0,
                            runSpacing: 4.0,
                            children: [
                              if (updatedDev.hasHeartRate)
                                _buildBadge(
                                  'Heart rate (0x180D)',
                                  const Color(0xFF10B981),
                                ),
                              if (updatedDev.hasSpO2)
                                _buildBadge(
                                  'SpO2 (0x1822)',
                                  const Color(0xFF8B5CF6),
                                ),
                              if (updatedDev.hasPulsePatch)
                                _buildBadge(
                                  'PulsePatch',
                                  const Color(0xFF06B6D4),
                                ),
                              if (updatedDev.isMiBand)
                                _buildBadge('Mi Band', const Color(0xFFF59E0B)),
                            ],
                          ),

                          // Compatibility Status Banner (if checked)
                          if (updatedDev.compatibilityStatus != null) ...[
                            const SizedBox(height: 8.0),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                                vertical: 6.0,
                              ),
                              decoration: BoxDecoration(
                                color: updatedDev.gattErrorCode != null
                                    ? const Color(0x33EF4444)
                                    : (updatedDev.isCompatible
                                          ? const Color(0x3310B981)
                                          : const Color(0x336B7280)),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                updatedDev.compatibilityStatus!,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w400,
                                  color: updatedDev.gattErrorCode != null
                                      ? const Color(0xFFFCA5A5)
                                      : (updatedDev.isCompatible
                                            ? const Color(0xFF6EE7B7)
                                            : AppColors.textMuted),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }, childCount: devices.length),
              );
            },
          ),

          // Dedicated "Use Simulator (sample data)" Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 10.0, bottom: 12.0),
              child: MetricCard(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.tune,
                                color: AppColors.accentCyan,
                                size: 20.0,
                              ),
                              SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  'Use Simulator (sample data)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        PillButton(
                          label: bleSource.isSimulator ? 'Active' : 'Start',
                          style: bleSource.isSimulator
                              ? PillButtonStyle.white
                              : PillButtonStyle.dark,
                          onPressed: () async {
                            await bleSource.connect('sim-sample');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    const Text(
                      'Simulate a running MAX30102 sensor with realistic heart-rate data for offline testing without physical hardware.',
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
            ),
          ),

          // Hardware Footnote (.m)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 12.0),
              child: Text(
                'Sensor: MAX30102 · Battery and firmware shown only if reported',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.0,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),

          // Bottom padding clearing the floating circle navigation bar & system gesture pill
          SliverToBoxAdapter(child: SizedBox(height: 96.0 + bottomInset)),
        ],
      ),
    );
  }

  static Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11.0,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _RadarHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _RadarHeaderDelegate({required this.onTap});

  final VoidCallback onTap;

  @override
  double get minExtent => 90.0;

  @override
  double get maxExtent => 220.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final scale = 1.0 - (0.4 * progress);
    final opacity = (1.0 - (progress * 0.6)).clamp(0.3, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: SizedBox(
          width: 320.0,
          height: maxExtent - shrinkOffset,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: const SizedBox(
                  width: 320.0,
                  height: 220.0,
                  child: CustomPaint(
                    size: Size(320.0, 220.0),
                    painter: _RadarScannerPainter(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _RadarHeaderDelegate oldDelegate) => false;
}

class _RadarScannerPainter extends CustomPainter {
  const _RadarScannerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 320.0;
    final scaleY = size.height / 220.0;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    const center = Offset(160.0, 110.0);

    // Outer ring: r=105, stroke #3A2A8F opacity .4
    final outerPaint = Paint()
      ..color = const Color(0x663A2A8F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, 105.0, outerPaint);

    // Middle ring: r=70, stroke #3A2A8F opacity .6
    final midPaint = Paint()
      ..color = const Color(0x993A2A8F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, 70.0, midPaint);

    // Inner ring: r=40, stroke #4C8DF5
    final innerPaint = Paint()
      ..color = const Color(0xFF4C8DF5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, 40.0, innerPaint);

    // Center beacon: r=12, fill #C0148F
    final beaconPaint = Paint()
      ..color = const Color(0xFFC0148F)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 12.0, beaconPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
