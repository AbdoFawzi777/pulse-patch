import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/session_record.dart';
import '../../domain/signal/ble_packet.dart';
import '../../domain/signal/standard_ble_hr_parser.dart';
import 'heart_rate_source.dart';

/// Experimental source adapter for Xiaomi Mi Smart Band 5.
/// Supports two operation modes:
/// 1. Broadcast Mode (Recommended): When enabled in Zepp Life / Mi Fitness,
///    the band broadcasts standard 0x180D and streams via 0x2A37.
/// 2. Huami Direct Mode: Connects to proprietary service 0xFEE1 with user-provided
///    16-byte auth key stored locally (never hardcoded or committed).
class MiBand5Source implements HeartRateSource {
  MiBand5Source({this.prefs}) {
    _initAdapterListener();
  }

  final SharedPreferences? prefs;

  static const String huamiAuthServiceUuid =
      '0000fee1-0000-1000-8000-00805f9b34fb';
  static const String huamiAuthCharUuid =
      '00000009-0000-3512-2118-0009af100700';
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
  SessionSource get source => SessionSource.miBand5;

  @override
  String get sourceLabel => 'Mi Smart Band 5';

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
            name: name.isNotEmpty ? name : 'Mi Smart Band 5',
            rssi: r.rssi,
            category: cat,
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

      final services = await device.discoverServices();

      // Check Path 1: Standard 0x180D Heart Rate Service (Broadcast Mode)
      BluetoothCharacteristic? hrChar;
      for (final service in services) {
        if (service.uuid.str.toLowerCase().contains('180d')) {
          for (final char in service.characteristics) {
            if (char.uuid.str.toLowerCase().contains('2a37')) {
              hrChar = char;
              break;
            }
          }
        }
      }

      if (hrChar != null) {
        // Standard broadcast mode active!
        await hrChar.setNotifyValue(true);
        _charSubscription?.cancel();
        _charSubscription = hrChar.onValueReceived.listen(_handlePacketData);
        _resetTimeoutWatchdog();
        return;
      }

      // Check Path 2: Huami Auth Service 0xFEE1
      BluetoothCharacteristic? authChar;
      for (final service in services) {
        if (service.uuid.str.toLowerCase().contains('fee1')) {
          for (final char in service.characteristics) {
            if (char.uuid.str.toLowerCase().contains('00000009')) {
              authChar = char;
              break;
            }
          }
        }
      }

      if (authChar != null) {
        final authKey = prefs?.getString('mi_band_auth_key');
        if (authKey == null || authKey.isEmpty) {
          // Instruct user that broadcast mode or auth key is required
          _setState(BleConnectionState.noSensorData);
          return;
        }

        // Send challenge request to Huami auth characteristic
        await authChar.setNotifyValue(true);
        await authChar.write([0x01, 0x00], withoutResponse: false);
        _resetTimeoutWatchdog();
      } else {
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
