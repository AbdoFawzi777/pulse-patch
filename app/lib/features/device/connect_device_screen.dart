import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/signal/generic_ble_hr_parser.dart';
import '../../domain/signal/import_file_parser.dart';
import '../../shared/widgets/bottom_circle_nav.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/pill_button.dart';
import 'generic_ble_heart_rate_source.dart';
import 'heart_rate_source.dart';
import 'unified_heart_rate_source.dart';

/// Connect Device screen matching Device.dc.html and Connect device.png.
/// Supports universal BLE discovery (Standard BLE 0x180D, PulsePatch-C3, Nordic UART, custom mapping)
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
  bool _filterOnlyHeartRate = false;
  bool _permissionDenied = false;
  final Map<String, DiscoveredBleDevice> _compatibilityResults = {};
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  StreamSubscription<BluetoothAdapterState>? _adapterSub;

  @override
  void initState() {
    super.initState();
    _initAdapterListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionsAndScan();
    });
  }

  Future<void> _initAdapterListener() async {
    try {
      if (await FlutterBluePlus.isSupported) {
        _adapterSub = FlutterBluePlus.adapterState.listen((state) {
          if (mounted) setState(() => _adapterState = state);
        });
      }
    } catch (_) {
      // In tests or environments without Bluetooth hardware
    }
  }

  @override
  void dispose() {
    _adapterSub?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissionsAndScan() async {
    try {
      final scanStatus = await Permission.bluetoothScan.request();
      final connectStatus = await Permission.bluetoothConnect.request();
      if (!scanStatus.isGranted) {
        await Permission.locationWhenInUse.request();
      }

      if (scanStatus.isPermanentlyDenied || connectStatus.isPermanentlyDenied) {
        if (mounted) setState(() => _permissionDenied = true);
        return;
      }

      if (mounted) {
        setState(() => _permissionDenied = false);
        ref.read(unifiedHeartRateSourceProvider).startScan();
      }
    } catch (_) {
      // In tests or environments without permission_handler hardware
      if (mounted) {
        ref.read(unifiedHeartRateSourceProvider).startScan();
      }
    }
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

  Future<void> _handleCheckCompatibility(DiscoveredBleDevice dev) async {
    setState(() => _checkingDeviceId = dev.id);
    try {
      final res = await ref
          .read(unifiedHeartRateSourceProvider)
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

  void _showDeviceBottomSheet(DiscoveredBleDevice dev) {
    final unifiedSource = ref.read(unifiedHeartRateSourceProvider);
    final isRemembered =
        unifiedSource.getRememberedDeviceId() == dev.id.toUpperCase();
    bool rememberThis = isRemembered;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBgNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.0)),
      ),
      builder: (ctx) => DeviceDetailBottomSheet(
        device: dev,
        initialRemember: isRemembered,
        onRememberChanged: (val) => rememberThis = val,
        onConnect: () async {
          Navigator.pop(ctx);
          if (rememberThis) {
            await unifiedSource.rememberDevice(
              dev.id,
              dev.displayName,
              dev.category,
            );
          } else if (isRemembered) {
            await unifiedSource.forgetDevice();
          }
          setState(() => _connectingDeviceId = dev.id);
          try {
            await unifiedSource.connect(dev.id);
          } finally {
            if (mounted) {
              setState(() => _connectingDeviceId = null);
            }
          }
        },
        onCheckCompatibility: () {
          Navigator.pop(ctx);
          _handleCheckCompatibility(dev);
        },
        onAdvancedMap: () {
          Navigator.pop(ctx);
          _showGenericMappingDialog(dev);
        },
      ),
    );
  }

  void _showGenericMappingDialog(DiscoveredBleDevice dev) {
    final unifiedSource = ref.read(unifiedHeartRateSourceProvider);
    final existingMapping = unifiedSource.getGenericMapping(dev.id);

    final serviceCtrl = TextEditingController(
      text:
          existingMapping?.serviceUuid ??
          (dev.hasNordicUart
              ? GenericBleHeartRateSource.nordicUartServiceUuid
              : ''),
    );
    final charCtrl = TextEditingController(
      text:
          existingMapping?.characteristicUuid ??
          (dev.hasNordicUart
              ? GenericBleHeartRateSource.nordicUartTxCharUuid
              : ''),
    );
    final regexCtrl = TextEditingController(
      text: existingMapping?.customRegex ?? r'(\d{2,3})',
    );
    GenericBleFormat selectedFormat =
        existingMapping?.format ?? GenericBleFormat.uint8;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBgNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.0)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 20.0,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.0,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Map Characteristic Telemetry',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 19.0,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  const Text(
                    'For Nordic UART, Arduino, ESP32, or custom BLE peripherals.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.0,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: serviceCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Service UUID (e.g. 6E400001-...)',
                      labelStyle: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  TextField(
                    controller: charCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Characteristic UUID (e.g. 6E400003-...)',
                      labelStyle: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Data Wire Format:',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.0,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  DropdownButton<GenericBleFormat>(
                    value: selectedFormat,
                    dropdownColor: AppColors.cardBgNavy,
                    isExpanded: true,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.0,
                      color: Colors.white,
                    ),
                    items: GenericBleFormat.values.map((f) {
                      return DropdownMenuItem(value: f, child: Text(f.label));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedFormat = val);
                      }
                    },
                  ),
                  if (selectedFormat == GenericBleFormat.asciiRegex) ...[
                    const SizedBox(height: 12.0),
                    TextField(
                      controller: regexCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText:
                            'ASCII Extraction Regex (e.g. r"(\\d{2,3})")',
                        labelStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.cardBorder),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20.0),
                  SizedBox(
                    width: double.infinity,
                    child: PillButton(
                      label: 'Save Mapping & Connect',
                      style: PillButtonStyle.white,
                      onPressed: () async {
                        final mapping = GenericBleMapping(
                          deviceId: dev.id,
                          serviceUuid: serviceCtrl.text.trim(),
                          characteristicUuid: charCtrl.text.trim(),
                          format: selectedFormat,
                          customRegex: regexCtrl.text.trim(),
                        );
                        Navigator.pop(ctx);
                        await unifiedSource.saveGenericMapping(mapping);
                        if (!mounted) return;
                        setState(() => _connectingDeviceId = dev.id);
                        try {
                          await unifiedSource.connect(dev.id);
                        } finally {
                          if (mounted) {
                            setState(() => _connectingDeviceId = null);
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildRssiBars(int rssi) {
    final int bars;
    if (rssi >= -60) {
      bars = 4;
    } else if (rssi >= -70) {
      bars = 3;
    } else if (rssi >= -80) {
      bars = 2;
    } else {
      bars = 1;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final active = i < bars;
        final height = 4.0 + (i * 3.0);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.0),
          width: 3.0,
          height: height,
          decoration: BoxDecoration(
            color: active
                ? AppColors.accentCyan
                : AppColors.textMuted.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(1.0),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unifiedSource = ref.watch(unifiedHeartRateSourceProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final rememberedId = unifiedSource.getRememberedDeviceId();
    final rememberedName = unifiedSource.getRememberedDeviceName();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && widget.onBack != null) {
          widget.onBack!();
        }
      },
      child: DesignCanvasScaffold(
        bottomNavigationBar: widget.showBottomNav
            ? BottomCircleNav(
                currentIndex: widget.currentNavIndex,
                onTap: widget.onSelectTab ?? (_) {},
              )
            : null,
        child: RefreshIndicator(
          onRefresh: () async {
            await unifiedSource.startScan();
          },
          color: AppColors.accentCyan,
          backgroundColor: AppColors.cardBgNavy,
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
                          widget.onBack ??
                          () => Navigator.of(context).maybePop(),
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

            // Radar Scanner Illustration
            SliverPersistentHeader(
              pinned: false,
              delegate: _RadarHeaderDelegate(
                onTap: () => unifiedSource.startScan(),
              ),
            ),

            // Scanning Subtitle
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: StreamBuilder<BleConnectionState>(
                  stream: unifiedSource.connectionStateStream,
                  initialData: unifiedSource.currentState,
                  builder: (context, snapshot) {
                    final state = snapshot.data ?? BleConnectionState.idle;
                    final String label;
                    if (state == BleConnectionState.connected ||
                        state == BleConnectionState.streaming) {
                      label = 'Connected to ${unifiedSource.sourceLabel}';
                    } else if (state == BleConnectionState.connecting ||
                        state == BleConnectionState.discovering) {
                      label = 'Connecting to peripheral...';
                    } else if (state == BleConnectionState.subscribing) {
                      label = 'Subscribing to heart rate telemetry...';
                    } else if (state == BleConnectionState.reconnecting) {
                      label = 'Reconnecting with backoff...';
                    } else if (state == BleConnectionState.blocked) {
                      label = 'Heart rate stream blocked by device';
                    } else if (state == BleConnectionState.scanning) {
                      label = 'Scanning · keep peripheral nearby';
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

            // Prominent Scan Control Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: StreamBuilder<BleConnectionState>(
                  stream: unifiedSource.connectionStateStream,
                  initialData: unifiedSource.currentState,
                  builder: (context, snapshot) {
                    final isScanning =
                        snapshot.data == BleConnectionState.scanning;
                    return Center(
                      child: PillButton(
                        key: const Key('ble_scan_toggle_button'),
                        label: isScanning ? 'Stop Scan' : 'Start BLE Scan',
                        style: isScanning
                            ? PillButtonStyle.dark
                            : PillButtonStyle.white,
                        height: 38.0,
                        onPressed: () {
                          if (isScanning) {
                            unifiedSource.stopScan();
                          } else {
                            unifiedSource.startScan();
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

            // Bluetooth Disabled Warning Banner
            StreamBuilder<BleConnectionState>(
              stream: unifiedSource.connectionStateStream,
              initialData: unifiedSource.currentState,
              builder: (context, snapshot) {
                final isOff = _adapterState == BluetoothAdapterState.off ||
                    snapshot.data == BleConnectionState.bluetoothOff;
                if (!isOff) return const SliverToBoxAdapter(child: SizedBox.shrink());
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: MetricCard(
                      key: const Key('ble_bluetooth_off_banner'),
                      borderColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.bluetooth_disabled_rounded,
                            color: Color(0xFFEF4444),
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bluetooth is Turned Off',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Turn on Bluetooth to discover PulsePatch hardware.',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12,
                                    color: AppColors.textSubtitle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PillButton(
                            label: 'Turn On',
                            style: PillButtonStyle.white,
                            height: 32,
                            onPressed: () async {
                              try {
                                await FlutterBluePlus.turnOn();
                              } catch (_) {}
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Permission Denied Warning Banner
            if (_permissionDenied)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: MetricCard(
                    borderColor: const Color(0xFFF59E0B),
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Bluetooth permissions are required to scan for heart rate devices.',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        PillButton(
                          label: 'Settings',
                          style: PillButtonStyle.dark,
                          onPressed: () => openAppSettings(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Blocked Alert Banner if state is blocked
            StreamBuilder<BleConnectionState>(
              stream: unifiedSource.connectionStateStream,
              initialData: unifiedSource.currentState,
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
                                  'Heart rate blocked by device',
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
                            'The device refused to enable heart-rate notifications (GATT status 3). Cause not confirmed.',
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
                                      unifiedSource.connect('sim-sample'),
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

            // Remembered Device Quick-Connect Banner
            if (rememberedId != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: MetricCard(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Remembered Device',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.accentCyan,
                                ),
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                rememberedName ?? 'Device',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            PillButton(
                              label: 'Connect',
                              style: PillButtonStyle.white,
                              onPressed: () =>
                                  unifiedSource.connect(rememberedId),
                            ),
                            const SizedBox(width: 6.0),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                              tooltip: 'Forget device',
                              onPressed: () async {
                                await unifiedSource.forgetDevice();
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Filter Toggle Row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4.0,
                  vertical: 6.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Nearby BLE Peripherals',
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
                    Row(
                      children: [
                        Text(
                          _filterOnlyHeartRate ? 'HR Only' : 'All Devices',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.0,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Switch(
                          value: _filterOnlyHeartRate,
                          activeTrackColor: AppColors.accentCyan.withValues(
                            alpha: 0.5,
                          ),
                          thumbColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppColors.accentCyan;
                            }
                            return AppColors.textMuted;
                          }),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: (val) {
                            setState(() => _filterOnlyHeartRate = val);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Real Discovered Devices List
            StreamBuilder<List<DiscoveredBleDevice>>(
              stream: unifiedSource.discoveredDevicesStream,
              builder: (context, snapshot) {
                final rawDevices = snapshot.data ?? [];
                // Filter out simulated devices from real scan list
                var devices = rawDevices
                    .where((d) => !d.id.startsWith('sim-'))
                    .toList();

                if (_filterOnlyHeartRate) {
                  devices = devices.where((d) => d.isCompatible).toList();
                }

                // Sort: compatible first, then by descending RSSI
                devices.sort((a, b) {
                  if (a.isCompatible != b.isCompatible) {
                    return a.isCompatible ? -1 : 1;
                  }
                  return b.rssi.compareTo(a.rssi);
                });

                if (devices.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Text(
                          unifiedSource.currentState ==
                                  BleConnectionState.scanning
                              ? 'Scanning for nearby Bluetooth devices...'
                              : (_filterOnlyHeartRate
                                    ? 'No heart-rate devices detected.\nToggle "All Devices" or tap radar to rescan.'
                                    : 'No real devices found nearby.\nTap radar to scan or use simulator below.'),
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
                        (unifiedSource.currentState ==
                            BleConnectionState.connected ||
                        unifiedSource.currentState ==
                            BleConnectionState.streaming);
                    final isConnecting =
                        _connectingDeviceId == dev.id &&
                        (unifiedSource.currentState ==
                                BleConnectionState.connecting ||
                            unifiedSource.currentState ==
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
                      child: GestureDetector(
                        onTap: () => _showDeviceBottomSheet(updatedDev),
                        child: MetricCard(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                dev.displayName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 17.0,
                                                  fontWeight: FontWeight.w400,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6.0),
                                            _buildRssiBars(dev.rssi),
                                          ],
                                        ),
                                        const SizedBox(height: 2.0),
                                        Text(
                                          '${dev.maskedId} · $signalText',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                                      onPressed: () =>
                                          unifiedSource.disconnect(),
                                    )
                                  else if (isConnecting)
                                    const PillButton(
                                      label: 'Connecting',
                                      style: PillButtonStyle.dark,
                                      onPressed: null,
                                    )
                                  else
                                    PillButton(
                                      label: 'Connect',
                                      style: updatedDev.isCompatible
                                          ? PillButtonStyle.white
                                          : PillButtonStyle.dark,
                                      onPressed: () =>
                                          _showDeviceBottomSheet(updatedDev),
                                    ),
                                ],
                              ),

                              // Badges Row
                              const SizedBox(height: 8.0),
                              Wrap(
                                spacing: 6.0,
                                runSpacing: 4.0,
                                children: [
                                  if (updatedDev.hasPulsePatch)
                                    _buildBadge(
                                      'PulsePatch Custom Protocol',
                                      const Color(0xFF06B6D4),
                                    )
                                  else if (updatedDev.hasHeartRate)
                                    _buildBadge(
                                      'Standard HR (0x180D)',
                                      const Color(0xFF10B981),
                                    )
                                  else if (updatedDev.hasNordicUart)
                                    _buildBadge(
                                      'Nordic UART',
                                      const Color(0xFFF59E0B),
                                    )
                                  else if (updatedDev.isMiBand)
                                    _buildBadge(
                                      'Mi Band',
                                      const Color(0xFFF59E0B),
                                    )
                                  else
                                    _buildBadge(
                                      'BLE Peripheral',
                                      const Color(0xFF64748B),
                                    ),
                                  if (updatedDev.hasSpO2)
                                    _buildBadge(
                                      'SpO2 (0x1822)',
                                      const Color(0xFF8B5CF6),
                                    ),
                                ],
                              ),

                              // Compatibility Status Banner
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
                            label: unifiedSource.isSimulator
                                ? 'Active'
                                : 'Start',
                            style: unifiedSource.isSimulator
                                ? PillButtonStyle.white
                                : PillButtonStyle.dark,
                            onPressed: () async {
                              await unifiedSource.connect('sim-sample');
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
      ),
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

/// Standalone bottom sheet displaying BLE device details and pairing actions.
class DeviceDetailBottomSheet extends StatefulWidget {
  const DeviceDetailBottomSheet({
    super.key,
    required this.device,
    this.initialRemember = false,
    this.onRememberChanged,
    this.onConnect,
    this.onCheckCompatibility,
    this.onAdvancedMap,
  });

  final DiscoveredBleDevice device;
  final bool initialRemember;
  final ValueChanged<bool>? onRememberChanged;
  final VoidCallback? onConnect;
  final VoidCallback? onCheckCompatibility;
  final VoidCallback? onAdvancedMap;

  @override
  State<DeviceDetailBottomSheet> createState() => _DeviceDetailBottomSheetState();
}

class _DeviceDetailBottomSheetState extends State<DeviceDetailBottomSheet> {
  late bool _rememberThis;

  @override
  void initState() {
    super.initState();
    _rememberThis = widget.initialRemember;
  }

  @override
  Widget build(BuildContext context) {
    final dev = widget.device;
    return Material(
      color: AppColors.cardBgNavy,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22.0)),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        dev.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20.0,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _ConnectDeviceScreenState._buildRssiBars(dev.rssi),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  '${dev.maskedId} · ${dev.rssi} dBm',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.0,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12.0),
                Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: [
                    if (dev.hasHeartRate)
                      _ConnectDeviceScreenState._buildBadge(
                        'Heart rate (0x180D)',
                        const Color(0xFF10B981),
                      ),
                    if (dev.hasSpO2)
                      _ConnectDeviceScreenState._buildBadge(
                        'SpO2 (0x1822)',
                        const Color(0xFF8B5CF6),
                      ),
                    if (dev.hasPulsePatch)
                      _ConnectDeviceScreenState._buildBadge(
                        'PulsePatch',
                        const Color(0xFF06B6D4),
                      ),
                    if (dev.hasNordicUart)
                      _ConnectDeviceScreenState._buildBadge(
                        'Nordic UART (6E40)',
                        const Color(0xFFF59E0B),
                      ),
                    if (dev.isMiBand)
                      _ConnectDeviceScreenState._buildBadge(
                        'Mi Band',
                        const Color(0xFFF59E0B),
                      ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberThis,
                      activeColor: AppColors.accentCyan,
                      onChanged: (val) {
                        setState(() => _rememberThis = val ?? false);
                        widget.onRememberChanged?.call(_rememberThis);
                      },
                    ),
                    Expanded(
                      child: const Text(
                        'Remember this device for auto-connect',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.0,
                          fontWeight: FontWeight.w300,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: PillButton(
                        label: 'Connect',
                        style: PillButtonStyle.white,
                        onPressed: widget.onConnect,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: PillButton(
                        label: 'Check compatibility',
                        style: PillButtonStyle.dark,
                        onPressed: widget.onCheckCompatibility,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                SizedBox(
                  width: double.infinity,
                  child: PillButton(
                    label: 'Advanced: map this characteristic',
                    style: PillButtonStyle.dark,
                    onPressed: widget.onAdvancedMap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

