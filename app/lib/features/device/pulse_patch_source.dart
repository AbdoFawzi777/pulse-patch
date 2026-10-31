import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../domain/entities/session_record.dart';
import '../../domain/signal/ble_packet.dart';
import 'heart_rate_source.dart';

/// Hardware BLE implementation interfacing with the ESP32-C3 PulsePatch hardware patch
/// over custom 12-byte GATT binary protocol.
class PulsePatchSource implements HeartRateSource {
  PulsePatchSource() {
    _initAdapterListener();
  }

  static const String serviceUuid = '180D0000-7243-4E64-8843-50554C534531';
  static const String hrCharUuid = '180D0001-7243-4E64-8843-50554C534531';
  static const String opticalCharUuid = '180D0002-7243-4E64-8843-50554C534531';
  static const String devInfoCharUuid = '180D0003-7243-4E64-8843-50554C534531';

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
  StreamSubscription? _opticalSubscription;

  BluetoothDevice? _connectedDevice;
  Timer? _timeoutTimer;
  int? _lastSequence;
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
  SessionSource get source => SessionSource.pulsepatch;

  @override
  String get sourceLabel => 'PulsePatch-C3';

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
            name: name.isNotEmpty ? name : 'PulsePatch-C3',
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
        timeout: const Duration(seconds: 10),
      );
      _setState(BleConnectionState.connected);

      // Discover GATT services and subscribe to heart rate notifications
      final services = await device.discoverServices();
      for (final service in services) {
        if (service.uuid == Guid(serviceUuid)) {
          for (final char in service.characteristics) {
            if (char.uuid == Guid(hrCharUuid)) {
              await char.setNotifyValue(true);
              _charSubscription?.cancel();
              _charSubscription = char.onValueReceived.listen(
                _handlePacketData,
              );
            } else if (char.uuid == Guid(opticalCharUuid)) {
              try {
                await char.setNotifyValue(true);
                _opticalSubscription?.cancel();
                _opticalSubscription = char.onValueReceived.listen(
                  _handleOpticalData,
                );
              } catch (_) {}
            }
          }
        }
      }

      _resetTimeoutWatchdog();
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _handleOpticalData(List<int> rawBytes) {
    if (rawBytes.length >= 2) {
      final bd = ByteData.sublistView(Uint8List.fromList(rawBytes));
      final sample = bd.getInt16(0, Endian.little).toDouble();
      _waveformController.add(sample);
    }
  }

  void _handlePacketData(List<int> rawBytes) {
    _resetTimeoutWatchdog();

    final packet = BlePacket.parse(rawBytes);
    if (packet == null) {
      _diagnostics = _diagnostics.copyWith(
        malformedPackets: _diagnostics.malformedPackets + 1,
      );
      _diagnosticsController.add(_diagnostics);
      return;
    }

    int lost = _diagnostics.lostPackets;
    int dups = _diagnostics.duplicatePackets;

    if (_lastSequence != null) {
      final expected = (_lastSequence! + 1) & 0xFFFF;
      if (packet.sequenceNumber == _lastSequence) {
        dups++;
      } else if (packet.sequenceNumber != expected) {
        final diff = (packet.sequenceNumber - expected) & 0xFFFF;
        if (diff < 100) {
          lost += diff;
        }
      }
    }
    _lastSequence = packet.sequenceNumber;

    _diagnostics = _diagnostics.copyWith(
      totalPackets: _diagnostics.totalPackets + 1,
      lostPackets: lost,
      duplicatePackets: dups,
      lastReceivedTime: DateTime.now(),
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
    _opticalSubscription?.cancel();
    _opticalSubscription = null;
    _deviceStateSubscription?.cancel();
    _deviceStateSubscription = null;
    _connectedDevice = null;
    _lastSequence = null;
    _setState(BleConnectionState.disconnected);
  }

  @override
  Future<void> disconnect() async {
    _timeoutTimer?.cancel();
    try {
      await _charSubscription?.cancel();
      _charSubscription = null;
      await _opticalSubscription?.cancel();
      _opticalSubscription = null;
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
      final hasPulsePatch = services.any(
        (s) => s.uuid.str.toLowerCase().contains('7243-4e64'),
      );
      final hasHr = services.any(
        (s) => s.uuid.str.toLowerCase().contains('180d'),
      );
      await dev.disconnect();
      return DiscoveredBleDevice(
        id: deviceId,
        name: dev.platformName.isNotEmpty ? dev.platformName : 'PulsePatch-C3',
        rssi: -50,
        category: (hasPulsePatch || hasHr)
            ? BleDeviceCategory.pulsePatch
            : BleDeviceCategory.unknown,
        discoveredServices: services
            .map((s) => s.uuid.str.toLowerCase())
            .toList(),
        compatibilityStatus: (hasPulsePatch || hasHr)
            ? 'Compatible: heart rate stream available'
            : 'No heart-rate service',
      );
    } catch (e) {
      return DiscoveredBleDevice(
        id: deviceId,
        name: 'PulsePatch Device',
        rssi: -80,
        compatibilityStatus: 'Connection check failed: $e',
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
