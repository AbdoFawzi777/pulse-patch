import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/preferences_repository.dart';
import '../../domain/entities/session_record.dart';
import '../../domain/signal/ble_packet.dart';
import '../../domain/signal/generic_ble_hr_parser.dart';
import 'generic_ble_heart_rate_source.dart';
import 'heart_rate_source.dart';
import 'mi_band_5_source.dart';
import 'pulse_patch_source.dart';
import 'standard_ble_heart_rate_source.dart';

/// Idle / no-op HeartRateSource used as the default production state.
/// Emits no packets, no waveform, and never enters simulator mode.
class IdleHeartRateSource implements HeartRateSource {
  final _connectionStateController =
      StreamController<BleConnectionState>.broadcast();
  final _discoveredDevicesController =
      StreamController<List<DiscoveredBleDevice>>.broadcast();
  final _packetController = StreamController<BlePacket>.broadcast();
  final _diagnosticsController = StreamController<PacketDiagnostics>.broadcast();
  final _waveformController = StreamController<double>.broadcast();

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
  BleConnectionState get currentState => BleConnectionState.idle;
  @override
  PacketDiagnostics get currentDiagnostics => const PacketDiagnostics();

  @override
  bool get isSimulator => false;
  @override
  String get sourceLabel => 'No device';
  @override
  SessionSource get source => SessionSource.pulsepatch;

  @override
  Future<void> startScan() async {}
  @override
  Future<void> stopScan() async {}
  @override
  Future<void> connect(String deviceId) async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<DiscoveredBleDevice?> checkCompatibility(String deviceId) async => null;

  @override
  void dispose() {
    _connectionStateController.close();
    _discoveredDevicesController.close();
    _packetController.close();
    _diagnosticsController.close();
    _waveformController.close();
  }
}

/// Unified Heart Rate Source managing multi-protocol routing:
/// - PulsePatch-C3 (Custom 12-byte protocol)
/// - Standard BLE 0x180D / 0x2A37 (Chest straps, smartwatches, Mi Band broadcast)
/// - Generic BLE / UART (Nordic UART Service, ESP32/Arduino, custom mapping)
/// - Mi Smart Band 5 (Standard BLE without credentials)
/// - Simulator (Offline testing)
class UnifiedHeartRateSource implements HeartRateSource {
  UnifiedHeartRateSource({required this.prefs}) {
    _activeSource = IdleHeartRateSource();
    _forwardActiveSourceStreams();
  }

  final SharedPreferences prefs;

  static const String keyRememberedDeviceId = 'remembered_ble_device_id';
  static const String keyRememberedDeviceName = 'remembered_ble_device_name';
  static const String keyRememberedCategory = 'remembered_ble_category';
  static const String keyGenericMappingPrefix = 'generic_ble_mapping_';

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

  bool isSessionActive = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  String? _lastConnectedDeviceId;

  void _forwardActiveSourceStreams() {
    _activeStateSub?.cancel();
    _activePacketSub?.cancel();
    _activeDiagSub?.cancel();
    _activeWaveSub?.cancel();

    _activeStateSub = _activeSource.connectionStateStream.listen((state) {
      if (!_isDisposed) {
        _connectionStateController.add(state);
        if (state == BleConnectionState.connected ||
            state == BleConnectionState.streaming) {
          _reconnectAttempts = 0;
          _reconnectTimer?.cancel();
        } else if (state == BleConnectionState.disconnected &&
            isSessionActive &&
            _lastConnectedDeviceId != null &&
            _reconnectAttempts < 4) {
          _handleAutoReconnect();
        }
      }
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

  void _handleAutoReconnect() {
    if (_lastConnectedDeviceId == null || _isDisposed) return;
    _reconnectAttempts++;
    final delaySeconds = 1 << (_reconnectAttempts - 1); // 1, 2, 4, 8s backoff
    _connectionStateController.add(BleConnectionState.reconnecting);

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (isSessionActive && _lastConnectedDeviceId != null && !_isDisposed) {
        connect(_lastConnectedDeviceId!);
      }
    });
  }

  // --- Persistence Methods ---

  Future<void> rememberDevice(
    String id,
    String name,
    BleDeviceCategory category,
  ) async {
    await prefs.setString(keyRememberedDeviceId, id.toUpperCase());
    await prefs.setString(keyRememberedDeviceName, name);
    await prefs.setString(keyRememberedCategory, category.name);
  }

  Future<void> forgetDevice() async {
    await prefs.remove(keyRememberedDeviceId);
    await prefs.remove(keyRememberedDeviceName);
    await prefs.remove(keyRememberedCategory);
  }

  String? getRememberedDeviceId() => prefs.getString(keyRememberedDeviceId);
  String? getRememberedDeviceName() => prefs.getString(keyRememberedDeviceName);

  Future<void> saveGenericMapping(GenericBleMapping mapping) async {
    final key = '$keyGenericMappingPrefix${mapping.deviceId.toUpperCase()}';
    await prefs.setString(key, jsonEncode(mapping.toJson()));
  }

  GenericBleMapping? getGenericMapping(String deviceId) {
    final key = '$keyGenericMappingPrefix${deviceId.toUpperCase()}';
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return GenericBleMapping.fromJson(map);
    } catch (_) {
      return null;
    }
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
      _discoveredMap.clear();

      // Query connected system devices
      try {
        final sysDevices = await FlutterBluePlus.systemDevices([]);
        for (final d in sysDevices) {
          final id = d.remoteId.str.toUpperCase();
          final rawName = d.platformName.isNotEmpty
              ? d.platformName
              : d.advName;
          final name = rawName.trim().isNotEmpty
              ? rawName.trim()
              : 'Unnamed device';
          BleDeviceCategory cat = BleDeviceCategory.unknown;
          if (name.contains('PulsePatch')) {
            cat = BleDeviceCategory.pulsePatch;
          } else if (name.contains('Band 5') ||
              name.contains('Mi Smart') ||
              name.contains('Mi Band')) {
            cat = BleDeviceCategory.miBand;
          }
          _discoveredMap[id] = DiscoveredBleDevice(
            id: id,
            name: name,
            rssi: -50,
            category: cat,
            advertisedServices: const [],
          );
        }
      } catch (_) {}

      // Query bonded devices
      try {
        final bonded = await FlutterBluePlus.bondedDevices;
        for (final d in bonded) {
          final id = d.remoteId.str.toUpperCase();
          if (!_discoveredMap.containsKey(id)) {
            final rawName = d.platformName.isNotEmpty
                ? d.platformName
                : d.advName;
            final name = rawName.trim().isNotEmpty
                ? rawName.trim()
                : 'Unnamed device';
            BleDeviceCategory cat = BleDeviceCategory.unknown;
            if (name.contains('PulsePatch')) {
              cat = BleDeviceCategory.pulsePatch;
            } else if (name.contains('Band 5') ||
                name.contains('Mi Smart') ||
                name.contains('Mi Band')) {
              cat = BleDeviceCategory.miBand;
            }
            _discoveredMap[id] = DiscoveredBleDevice(
              id: id,
              name: name,
              rssi: -55,
              category: cat,
              advertisedServices: const [],
            );
          }
        }
      } catch (_) {}

      if (!_isDisposed && _discoveredMap.isNotEmpty) {
        _discoveredDevicesController.add(_discoveredMap.values.toList());
      }

      await _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final id = r.device.remoteId.str.toUpperCase();
          final rawName = r.advertisementData.advName.isNotEmpty
              ? r.advertisementData.advName
              : r.device.platformName;

          final serviceUuids = r.advertisementData.serviceUuids
              .map((g) => g.str.toLowerCase())
              .toList();

          BleDeviceCategory cat = BleDeviceCategory.unknown;
          if (rawName.contains('PulsePatch') ||
              serviceUuids.any((u) => u.contains('7243-4e64'))) {
            cat = BleDeviceCategory.pulsePatch;
          } else if (rawName.contains('Band 5') ||
              rawName.contains('Mi Smart') ||
              rawName.contains('Mi Band') ||
              serviceUuids.any(
                (u) => u.contains('fee0') || u.contains('fee1'),
              )) {
            cat = BleDeviceCategory.miBand;
          } else if (serviceUuids.any((u) => u.contains('180d'))) {
            cat = BleDeviceCategory.standardBle;
          } else if (serviceUuids.any((u) => u.contains('6e40'))) {
            cat = BleDeviceCategory.genericBle;
          }

          final existing = _discoveredMap[id];
          final mergedServices = existing != null
              ? {...existing.advertisedServices, ...serviceUuids}.toList()
              : serviceUuids;

          final isSimHost =
              rawName.contains('ABDOFAWZI') || rawName.contains('PulsePatch');
          final cleanName = isSimHost
              ? 'PulsePatch-SimHR'
              : (rawName.trim().isNotEmpty
                    ? rawName.trim()
                    : (existing != null &&
                              existing.name.trim().isNotEmpty &&
                              existing.name != 'Unnamed device'
                          ? existing.name.trim()
                          : 'Unnamed device'));

          _discoveredMap[id] = DiscoveredBleDevice(
            id: id,
            name: cleanName,
            rssi: r.rssi,
            category: (cat != BleDeviceCategory.unknown)
                ? cat
                : (existing?.category ?? BleDeviceCategory.unknown),
            advertisedServices: mergedServices,
            discoveredServices: existing?.discoveredServices ?? const [],
            compatibilityStatus: existing?.compatibilityStatus,
            gattErrorCode: existing?.gattErrorCode,
          );
        }
        if (!_isDisposed) {
          _discoveredDevicesController.add(_discoveredMap.values.toList());
        }
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (_) {
      if (!_isDisposed) {
        _discoveredDevicesController.add(_discoveredMap.values.toList());
        _connectionStateController.add(BleConnectionState.idle);
      }
    }
  }

  @override
  Future<DiscoveredBleDevice?> checkCompatibility(String deviceId) async {
    final dev =
        _discoveredMap[deviceId.toUpperCase()] ?? _discoveredMap[deviceId];
    if (dev == null) return null;

    final savedMapping = getGenericMapping(dev.id);

    HeartRateSource checker;
    if (savedMapping != null || dev.category == BleDeviceCategory.genericBle) {
      checker = GenericBleHeartRateSource(
        mapping:
            savedMapping ??
            GenericBleMapping(
              deviceId: dev.id,
              serviceUuid: '',
              characteristicUuid: '',
            ),
        customDeviceName: dev.name,
      );
    } else {
      switch (dev.category) {
        case BleDeviceCategory.pulsePatch:
          final hasCustom =
              dev.advertisedServices.any((u) => u.contains('7243-4e64')) ||
              dev.discoveredServices.any((u) => u.contains('7243-4e64'));
          if (hasCustom) {
            checker = PulsePatchSource();
          } else {
            checker = StandardBleHeartRateSource(customDeviceName: dev.name);
          }
          break;
        case BleDeviceCategory.miBand:
          checker = MiBand5Source(prefs: prefs);
          break;
        case BleDeviceCategory.genericBle:
          checker = GenericBleHeartRateSource(
            mapping:
                savedMapping ??
                GenericBleMapping(
                  deviceId: dev.id,
                  serviceUuid: '',
                  characteristicUuid: '',
                ),
            customDeviceName: dev.name,
          );
          break;
        case BleDeviceCategory.standardBle:
        case BleDeviceCategory.unknown:
          checker = StandardBleHeartRateSource(customDeviceName: dev.name);
          break;
      }
    }

    try {
      final res = await checker.checkCompatibility(dev.id);
      if (res != null) {
        _discoveredMap[dev.id] = res;
        if (!_isDisposed) {
          _discoveredDevicesController.add(_discoveredMap.values.toList());
        }
      }
      return res;
    } finally {
      checker.dispose();
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

    final upperId = deviceId.toUpperCase();
    final device = _discoveredMap[upperId] ?? _discoveredMap[deviceId];

    if (deviceId.startsWith('sim-') || device == null) {
      // Simulator connections are disabled in production.
      // Only allow if actively testing; do nothing and stay idle.
      return;
    }

    _lastConnectedDeviceId = device.id;

    // Determine target source adapter by category or saved generic mapping
    _activeSource.dispose();

    final savedMapping = getGenericMapping(device.id);

    if (savedMapping != null ||
        device.category == BleDeviceCategory.genericBle) {
      _activeSource = GenericBleHeartRateSource(
        mapping:
            savedMapping ??
            GenericBleMapping(
              deviceId: device.id,
              serviceUuid: '',
              characteristicUuid: '',
            ),
        customDeviceName: device.name,
      );
    } else {
      switch (device.category) {
        case BleDeviceCategory.pulsePatch:
          final hasCustom =
              device.advertisedServices.any((u) => u.contains('7243-4e64')) ||
              device.discoveredServices.any((u) => u.contains('7243-4e64'));
          if (hasCustom) {
            _activeSource = PulsePatchSource();
          } else {
            _activeSource = StandardBleHeartRateSource(
              customDeviceName: device.name,
            );
          }
          break;
        case BleDeviceCategory.miBand:
          _activeSource = MiBand5Source(prefs: prefs);
          break;
        case BleDeviceCategory.genericBle:
          _activeSource = GenericBleHeartRateSource(
            mapping:
                savedMapping ??
                GenericBleMapping(
                  deviceId: device.id,
                  serviceUuid: '',
                  characteristicUuid: '',
                ),
            customDeviceName: device.name,
          );
          break;
        case BleDeviceCategory.standardBle:
        case BleDeviceCategory.unknown:
          _activeSource = StandardBleHeartRateSource(
            customDeviceName: device.name,
          );
          break;
      }
    }

    _forwardActiveSourceStreams();
    await _activeSource.connect(deviceId);
  }

  @override
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    await _activeSource.disconnect();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
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
