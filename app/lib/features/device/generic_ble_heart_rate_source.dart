import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../domain/entities/session_record.dart';
import '../../domain/signal/ble_packet.dart';
import '../../domain/signal/generic_ble_hr_parser.dart';
import 'heart_rate_source.dart';

/// Generic BLE source adapter for custom BLE chips, Nordic UART Service (NUS),
/// ESP32/Arduino, and mapped characteristics.
class GenericBleHeartRateSource implements HeartRateSource {
  GenericBleHeartRateSource({required this.mapping, this.customDeviceName}) {
    _initAdapterListener();
  }

  final GenericBleMapping mapping;
  final String? customDeviceName;

  static const String nordicUartServiceUuid =
      '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const String nordicUartTxCharUuid =
      '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  final _connectionStateController =
      StreamController<BleConnectionState>.broadcast();
  final _discoveredDevicesController =
      StreamController<List<DiscoveredBleDevice>>.broadcast();
  final _packetController = StreamController<BlePacket>.broadcast();
  final _diagnosticsController =
      StreamController<PacketDiagnostics>.broadcast();
  final _waveformController = StreamController<double>.broadcast();

  BleConnectionState _currentState = BleConnectionState.idle;
  PacketDiagnostics _diagnostics = const PacketDiagnostics();

  StreamSubscription? _scanSubscription;
  StreamSubscription? _adapterSubscription;
  StreamSubscription? _deviceStateSubscription;
  StreamSubscription? _charSubscription;

  BluetoothDevice? _connectedDevice;
  Timer? _timeoutTimer;
  double? _lastBpm;
  DateTime? _lastSampleTime;
  int _sequenceNumber = 0;
  bool _isDisposed = false;

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
  BleConnectionState get currentState => _currentState;

  @override
  PacketDiagnostics get currentDiagnostics => _diagnostics;

  @override
  bool get isSimulator => false;

  @override
  SessionSource get source => SessionSource.genericBle;

  @override
  String get sourceLabel => customDeviceName ?? 'Generic BLE / UART';

  void _setState(BleConnectionState state) {
    if (_isDisposed) return;
    _currentState = state;
    _connectionStateController.add(state);
  }

  Future<void> _initAdapterListener() async {
    try {
      if (await FlutterBluePlus.isSupported) {
        _adapterSubscription = FlutterBluePlus.adapterState.listen((state) {
          if (state == BluetoothAdapterState.off) {
            _setState(BleConnectionState.bluetoothOff);
          } else if (state == BluetoothAdapterState.unauthorized) {
            _setState(BleConnectionState.permissionDenied);
          } else if (state == BluetoothAdapterState.on &&
              _currentState == BleConnectionState.bluetoothOff) {
            _setState(BleConnectionState.idle);
          }
        });
      }
    } catch (_) {}
  }

  @override
  Future<void> startScan() async {
    try {
      _setState(BleConnectionState.scanning);
      final discoveredMap = <String, DiscoveredBleDevice>{};

      await _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final name = r.advertisementData.advName.isNotEmpty
              ? r.advertisementData.advName
              : r.device.platformName;

          final serviceUuids = r.advertisementData.serviceUuids
              .map((g) => g.str.toLowerCase())
              .toList();

          discoveredMap[r.device.remoteId.str] = DiscoveredBleDevice(
            id: r.device.remoteId.str,
            name: name.isNotEmpty ? name : 'Unnamed device',
            rssi: r.rssi,
            category: BleDeviceCategory.genericBle,
            advertisedServices: serviceUuids,
          );
        }
        if (!_isDisposed) {
          _discoveredDevicesController.add(discoveredMap.values.toList());
        }
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (_) {
      _setState(BleConnectionState.idle);
    }
  }

  @override
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    if (_currentState == BleConnectionState.scanning) {
      _setState(BleConnectionState.idle);
    }
  }

  @override
  Future<void> connect(String deviceId) async {
    await stopScan();
    _setState(BleConnectionState.connecting);

    try {
      final device = BluetoothDevice.fromId(deviceId);
      _connectedDevice = device;

      _deviceStateSubscription?.cancel();
      _deviceStateSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnect();
        }
      });

      await device.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 12),
      );

      _setState(BleConnectionState.connected);
      _setState(BleConnectionState.discovering);

      final services = await device.discoverServices();
      BluetoothCharacteristic? targetChar;

      final targetServUuid = mapping.serviceUuid.toLowerCase().trim();
      final targetCharUuid = mapping.characteristicUuid.toLowerCase().trim();

      // Find specified service or fallback to Nordic UART
      for (final s in services) {
        final sUuid = s.uuid.str.toLowerCase();
        final matchService = targetServUuid.isNotEmpty
            ? sUuid.contains(targetServUuid)
            : sUuid.contains('6e400001') || sUuid.contains('6e40');

        if (matchService) {
          for (final c in s.characteristics) {
            final cUuid = c.uuid.str.toLowerCase();
            final matchChar = targetCharUuid.isNotEmpty
                ? cUuid.contains(targetCharUuid)
                : (cUuid.contains('6e400003') ||
                      c.properties.notify ||
                      c.properties.indicate);

            if (matchChar) {
              targetChar = c;
              break;
            }
          }
        }
        if (targetChar != null) break;
      }

      // Fallback: search all services for the characteristic if not found in matched service
      if (targetChar == null && targetCharUuid.isNotEmpty) {
        for (final s in services) {
          for (final c in s.characteristics) {
            if (c.uuid.str.toLowerCase().contains(targetCharUuid)) {
              targetChar = c;
              break;
            }
          }
          if (targetChar != null) break;
        }
      }

      if (targetChar == null) {
        _setState(BleConnectionState.noSensorData);
        return;
      }

      _setState(BleConnectionState.subscribing);

      try {
        await targetChar.setNotifyValue(true);
      } catch (_) {
        // Fallback descriptor write
        for (final d in targetChar.descriptors) {
          if (d.uuid.str.toLowerCase().contains('2902')) {
            await d.write([0x01, 0x00]);
            break;
          }
        }
      }

      _setState(BleConnectionState.streaming);
      _charSubscription?.cancel();
      _charSubscription = targetChar.onValueReceived.listen(_handlePacketData);
      _resetTimeoutWatchdog();
    } catch (_) {
      _handleDisconnect();
    }
  }

  @override
  Future<DiscoveredBleDevice?> checkCompatibility(String deviceId) async {
    try {
      final dev = BluetoothDevice.fromId(deviceId);
      await dev.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 10),
      );
      final services = await dev.discoverServices();

      final targetServUuid = mapping.serviceUuid.toLowerCase().trim();
      final targetCharUuid = mapping.characteristicUuid.toLowerCase().trim();

      bool found = false;
      for (final s in services) {
        final sUuid = s.uuid.str.toLowerCase();
        final matchService = targetServUuid.isNotEmpty
            ? sUuid.contains(targetServUuid)
            : sUuid.contains('6e400001') || sUuid.contains('6e40');

        if (matchService) {
          for (final c in s.characteristics) {
            final cUuid = c.uuid.str.toLowerCase();
            final matchChar = targetCharUuid.isNotEmpty
                ? cUuid.contains(targetCharUuid)
                : (cUuid.contains('6e400003') ||
                      c.properties.notify ||
                      c.properties.indicate);

            if (matchChar) {
              found = true;
              break;
            }
          }
        }
        if (found) break;
      }

      await dev.disconnect();

      return DiscoveredBleDevice(
        id: deviceId,
        name: dev.platformName.isNotEmpty
            ? dev.platformName
            : (customDeviceName ?? 'Generic BLE Device'),
        rssi: -55,
        category: BleDeviceCategory.genericBle,
        discoveredServices: services
            .map((s) => s.uuid.str.toLowerCase())
            .toList(),
        compatibilityStatus: found
            ? 'Compatible: mapped characteristic available'
            : 'Mapped characteristic not found in services',
      );
    } catch (e) {
      return DiscoveredBleDevice(
        id: deviceId,
        name: customDeviceName ?? 'Generic BLE Device',
        rssi: -80,
        category: BleDeviceCategory.genericBle,
        compatibilityStatus: 'Check failed: $e',
      );
    }
  }

  void _handlePacketData(List<int> rawBytes) {
    _resetTimeoutWatchdog();

    final now = DateTime.now();
    final packet = GenericBleHrParser.parse(
      rawBytes,
      format: mapping.format,
      customRegex: mapping.customRegex,
      receivedAt: now,
      sequenceNumber: _sequenceNumber++,
      lastBpm: _lastBpm,
      lastSampleTime: _lastSampleTime,
    );

    if (packet == null) {
      _diagnostics = _diagnostics.copyWith(
        malformedPackets: _diagnostics.malformedPackets + 1,
      );
      _diagnosticsController.add(_diagnostics);
      return;
    }

    if (packet.rawBpm != null) {
      _lastBpm = packet.rawBpm;
      _lastSampleTime = now;
      _waveformController.add(packet.rawBpm!);
    }

    _diagnostics = _diagnostics.copyWith(
      totalPackets: _diagnostics.totalPackets + 1,
      lastReceivedTime: now,
    );

    _diagnosticsController.add(_diagnostics);
    _packetController.add(packet);
  }

  void _resetTimeoutWatchdog() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (_currentState == BleConnectionState.streaming) {
        _setState(BleConnectionState.noSensorData);
      }
    });
  }

  void _handleDisconnect() {
    _timeoutTimer?.cancel();
    _charSubscription?.cancel();
    _charSubscription = null;
    _deviceStateSubscription?.cancel();
    _deviceStateSubscription = null;
    _connectedDevice = null;
    _lastBpm = null;
    _lastSampleTime = null;
    _setState(BleConnectionState.disconnected);
  }

  @override
  Future<void> disconnect() async {
    _timeoutTimer?.cancel();
    try {
      await _charSubscription?.cancel();
      _charSubscription = null;
      await _connectedDevice?.disconnect();
    } catch (_) {}
    _handleDisconnect();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timeoutTimer?.cancel();
    _scanSubscription?.cancel();
    _adapterSubscription?.cancel();
    _deviceStateSubscription?.cancel();
    _charSubscription?.cancel();
    _connectionStateController.close();
    _discoveredDevicesController.close();
    _packetController.close();
    _diagnosticsController.close();
    _waveformController.close();
  }
}
