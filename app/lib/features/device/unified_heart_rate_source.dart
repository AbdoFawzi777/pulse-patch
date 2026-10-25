import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/preferences_repository.dart';
import '../../domain/entities/session_record.dart';
import '../../domain/signal/ble_packet.dart';
import 'heart_rate_source.dart';
import 'mi_band_5_source.dart';
import 'pulse_patch_source.dart';
import 'simulated_heart_rate_source.dart';
import 'standard_ble_heart_rate_source.dart';

/// Unified Heart Rate Source managing multi-protocol routing:
/// - PulsePatch-C3 (Custom 12-byte protocol)
/// - Standard BLE 0x180D / 0x2A37 (Chest straps, smartwatches, Mi Band broadcast)
/// - Mi Smart Band 5 (Experimental direct & broadcast modes)
/// - Simulator (Offline testing)
class UnifiedHeartRateSource implements HeartRateSource {
  UnifiedHeartRateSource({required this.prefs}) {
    _activeSource = SimulatedHeartRateSource();
    _forwardActiveSourceStreams();
    _initScanner();
  }

  final SharedPreferences prefs;

  late HeartRateSource _activeSource;
  StreamSubscription? _activeStateSub;
  StreamSubscription? _activePacketSub;
  StreamSubscription? _activeDiagSub;
  StreamSubscription? _activeWaveSub;

  final _connectionStateController =
      StreamController<BleConnectionState>.broadcast();
  final _discoveredDevicesController =
      StreamController<List<DiscoveredBleDevice>>.broadcast();
  final _packetController = StreamController<BlePacket>.broadcast();
  final _diagnosticsController =
      StreamController<PacketDiagnostics>.broadcast();
  final _waveformController = StreamController<double>.broadcast();

  StreamSubscription? _scanSubscription;
  final Map<String, DiscoveredBleDevice> _discoveredMap = {};
  bool _isDisposed = false;

  void _forwardActiveSourceStreams() {
    _activeStateSub?.cancel();
    _activePacketSub?.cancel();
    _activeDiagSub?.cancel();
    _activeWaveSub?.cancel();

    _activeStateSub = _activeSource.connectionStateStream.listen((state) {
      if (!_isDisposed) _connectionStateController.add(state);
    });
    _activePacketSub = _activeSource.packetStream.listen((packet) {
      if (!_isDisposed) _packetController.add(packet);
    });
    _activeDiagSub = _activeSource.diagnosticsStream.listen((diag) {
      if (!_isDisposed) _diagnosticsController.add(diag);
    });
    _activeWaveSub = _activeSource.opticalWaveformStream.listen((wave) {
      if (!_isDisposed) _waveformController.add(wave);
    });
  }

  void _initScanner() {
    // Populate default discovered devices for immediate preview matching design
    _discoveredMap['sim-pulsepatch-1'] = const DiscoveredBleDevice(
      id: 'sim-pulsepatch-1',
      name: 'PulsePatch-C3',
      rssi: -52,
      category: BleDeviceCategory.pulsePatch,
      advertisedServices: ['180d0000-7243-4e64-8843-50554c534531'],
    );
    _discoveredMap['sim-miband-1'] = const DiscoveredBleDevice(
      id: 'sim-miband-1',
      name: 'Mi Smart Band 5',
      rssi: -64,
      category: BleDeviceCategory.miBand,
      advertisedServices: [
        '0000180d-0000-1000-8000-00805f9b34fb',
        '0000fee0-0000-1000-8000-00805f9b34fb',
      ],
    );
  }

  @override
  Stream<BleConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  @override
  Stream<List<DiscoveredBleDevice>> get discoveredDevicesStream =>
      _discoveredDevicesController.stream;

  @override
  Stream<BlePacket> get packetStream => _packetController.stream;

  @override
  Stream<PacketDiagnostics> get diagnosticsStream =>
      _diagnosticsController.stream;

  @override
  Stream<double> get opticalWaveformStream => _waveformController.stream;

  @override
  BleConnectionState get currentState => _activeSource.currentState;

  @override
  PacketDiagnostics get currentDiagnostics => _activeSource.currentDiagnostics;

  @override
  bool get isSimulator => _activeSource.isSimulator;

  @override
  SessionSource get source => _activeSource.source;

  @override
  String get sourceLabel => _activeSource.sourceLabel;

  @override
  Future<void> startScan() async {
    _connectionStateController.add(BleConnectionState.scanning);
    try {
      await _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final name = r.advertisementData.advName.isNotEmpty
              ? r.advertisementData.advName
              : r.device.platformName;

          final serviceUuids = r.advertisementData.serviceUuids
              .map((g) => g.str.toLowerCase())
              .toList();

          BleDeviceCategory cat = BleDeviceCategory.unknown;
          if (name.contains('PulsePatch') ||
              serviceUuids.any((u) => u.contains('7243-4e64'))) {
            cat = BleDeviceCategory.pulsePatch;
          } else if (name.contains('Band 5') ||
              name.contains('Mi Smart') ||
              name.contains('Mi Band') ||
              serviceUuids.any(
                (u) => u.contains('fee0') || u.contains('fee1'),
              )) {
            cat = BleDeviceCategory.miBand;
          } else if (serviceUuids.any((u) => u.contains('180d'))) {
            cat = BleDeviceCategory.standardBle;
          }

          _discoveredMap[r.device.remoteId.str] = DiscoveredBleDevice(
            id: r.device.remoteId.str,
            name: name.isNotEmpty
                ? name
                : 'BLE Device (${r.device.remoteId.str.length > 5 ? r.device.remoteId.str.substring(0, 5) : r.device.remoteId.str})',
            rssi: r.rssi,
            category: cat,
            advertisedServices: serviceUuids,
          );
        }
        if (!_isDisposed) {
          _discoveredDevicesController.add(_discoveredMap.values.toList());
        }
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (_) {
      // In simulator or offline environment, emit initial list
      if (!_isDisposed) {
        _discoveredDevicesController.add(_discoveredMap.values.toList());
        _connectionStateController.add(BleConnectionState.idle);
      }
    }
  }

  @override
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    await _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  @override
  Future<void> connect(String deviceId) async {
    await stopScan();

    final device = _discoveredMap[deviceId];
    if (deviceId.startsWith('sim-') || device == null) {
      // Connecting to simulator
      if (_activeSource is! SimulatedHeartRateSource) {
        _activeSource.dispose();
        _activeSource = SimulatedHeartRateSource();
        _forwardActiveSourceStreams();
      }
      await _activeSource.connect(deviceId);
      return;
    }

    // Determine target source adapter by category
    _activeSource.dispose();

    switch (device.category) {
      case BleDeviceCategory.pulsePatch:
        _activeSource = PulsePatchSource();
        break;
      case BleDeviceCategory.miBand:
        _activeSource = MiBand5Source(prefs: prefs);
        break;
      case BleDeviceCategory.standardBle:
      case BleDeviceCategory.unknown:
        _activeSource = StandardBleHeartRateSource(
          customDeviceName: device.name,
        );
        break;
    }

    _forwardActiveSourceStreams();
    await _activeSource.connect(deviceId);
  }

  @override
  Future<void> disconnect() async {
    await _activeSource.disconnect();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _activeStateSub?.cancel();
    _activePacketSub?.cancel();
    _activeDiagSub?.cancel();
    _activeWaveSub?.cancel();
    _scanSubscription?.cancel();
    _activeSource.dispose();
    _connectionStateController.close();
    _discoveredDevicesController.close();
    _packetController.close();
    _diagnosticsController.close();
    _waveformController.close();
  }
}

/// Provider managing active HeartRateSource
final unifiedHeartRateSourceProvider = Provider<UnifiedHeartRateSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final source = UnifiedHeartRateSource(prefs: prefs);
  ref.onDispose(source.dispose);
  return source;
});
