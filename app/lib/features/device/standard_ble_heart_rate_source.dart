import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../domain/entities/session_record.dart';
import '../../domain/signal/ble_packet.dart';
import '../../domain/signal/standard_ble_hr_parser.dart';
import 'heart_rate_source.dart';

/// Source adapter for standard Bluetooth SIG Heart Rate Service (0x180D).
/// Compatible with chest straps (Polar H10, Garmin HRM), smart rings,
/// and smartwatches/fitness bands broadcasting heart rate (including Mi Smart Band 5).
class StandardBleHeartRateSource implements HeartRateSource {
  StandardBleHeartRateSource({this.customDeviceName}) {
    _initAdapterListener();
  }

  final String? customDeviceName;

  static const String standardHrServiceUuid = '180d';
  static const String standardHrCharUuid = '2a37';

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
  SessionSource get source => SessionSource.standardBle;

  @override
  String get sourceLabel => customDeviceName ?? 'Standard BLE (0x180D)';

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
    } catch (_) {
      // Headless unit test environment without Bluetooth hardware
    }
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

          BleDeviceCategory cat = BleDeviceCategory.unknown;
          if (name.contains('PulsePatch') ||
              serviceUuids.any((u) => u.contains('7243-4e64'))) {
            cat = BleDeviceCategory.pulsePatch;
          } else if (name.contains('Band 5') ||
              name.contains('Mi Smart') ||
              serviceUuids.any(
                (u) => u.contains('fee0') || u.contains('fee1'),
              )) {
            cat = BleDeviceCategory.miBand;
          } else if (serviceUuids.any((u) => u.contains('180d'))) {
            cat = BleDeviceCategory.standardBle;
          }

          discoveredMap[r.device.remoteId.str] = DiscoveredBleDevice(
            id: r.device.remoteId.str,
            name: name.isNotEmpty
                ? name
                : 'BLE Device (${r.device.remoteId.str.substring(0, 5)})',
            rssi: r.rssi,
            category: cat,
            advertisedServices: serviceUuids,
          );
        }
        if (!_isDisposed) {
          _discoveredDevicesController.add(discoveredMap.values.toList());
        }
      });

      // Scan all BLE devices without service filters so users can see compatible & nearby devices
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (_) {
      _setState(BleConnectionState.idle);
    }
  }

  @override
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
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

      // Discover GATT services and find Heart Rate Service 0x180D
      final services = await device.discoverServices();
      BluetoothCharacteristic? hrChar;

      for (final service in services) {
        final sUuid = service.uuid.str.toLowerCase();
        if (sUuid.contains('180d')) {
          for (final char in service.characteristics) {
            final cUuid = char.uuid.str.toLowerCase();
            if (cUuid.contains('2a37')) {
              hrChar = char;
              break;
            }
          }
        }
      }

      if (hrChar != null) {
        await hrChar.setNotifyValue(true);
        _charSubscription?.cancel();
        _charSubscription = hrChar.onValueReceived.listen(_handlePacketData);
        _resetTimeoutWatchdog();
      } else {
        // Device connected but does not expose 0x2A37
        _setState(BleConnectionState.noSensorData);
      }
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _handlePacketData(List<int> rawBytes) {
    _resetTimeoutWatchdog();

    final now = DateTime.now();
    final packet = StandardBleHrParser.parse(
      rawBytes,
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
      // Synthesize smooth optical trend waveform from live BPM
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
    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (_currentState == BleConnectionState.connected) {
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
  Future<DiscoveredBleDevice?> checkCompatibility(String deviceId) async {
    try {
      final dev = BluetoothDevice.fromId(deviceId);
      await dev.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 8),
      );
      final services = await dev.discoverServices();
      final hasHr = services.any(
        (s) => s.uuid.str.toLowerCase().contains('180d'),
      );

      String status;
      int? gattError;
      if (hasHr) {
        BluetoothCharacteristic? hrChar;
        for (final s in services) {
          if (s.uuid.str.toLowerCase().contains('180d')) {
            for (final c in s.characteristics) {
              if (c.uuid.str.toLowerCase().contains('2a37')) {
                hrChar = c;
                break;
              }
            }
          }
        }
        if (hrChar != null) {
          try {
            await hrChar.setNotifyValue(true);
            await hrChar.setNotifyValue(false);
            status = 'Compatible: heart rate stream available';
          } catch (e) {
            status = 'Connected but heart rate is blocked by the device ($e)';
            if (e.toString().contains('3')) {
              gattError = 3;
            }
          }
        } else {
          status = 'No heart-rate service';
        }
      } else {
        status = 'No heart-rate service';
      }
      await dev.disconnect();
      return DiscoveredBleDevice(
        id: deviceId,
        name: dev.platformName.isNotEmpty
            ? dev.platformName
            : (customDeviceName ?? 'Standard BLE Device'),
        rssi: -50,
        category: hasHr
            ? BleDeviceCategory.standardBle
            : BleDeviceCategory.unknown,
        discoveredServices: services
            .map((s) => s.uuid.str.toLowerCase())
            .toList(),
        compatibilityStatus: status,
        gattErrorCode: gattError,
      );
    } catch (e) {
      return DiscoveredBleDevice(
        id: deviceId,
        name: customDeviceName ?? 'BLE Device',
        rssi: -80,
        compatibilityStatus: 'Check failed: $e',
      );
    }
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
