import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../domain/signal/ble_packet.dart';
import 'heart_rate_source.dart';

/// Real BLE implementation interfacing with the ESP32-C3 hardware patch over flutter_blue_plus.
class BleHeartRateSource implements HeartRateSource {
  BleHeartRateSource() {
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
  String get sourceLabel => 'ESP32-C3 BLE';

  void _setState(BleConnectionState state) {
    if (_isDisposed) return;
    _currentState = state;
    _connectionStateController.add(state);
  }

  void _initAdapterListener() {
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

          if (name.contains('PulsePatch') ||
              r.advertisementData.serviceUuids.contains(Guid(serviceUuid))) {
            discoveredMap[r.device.remoteId.str] = DiscoveredBleDevice(
              id: r.device.remoteId.str,
              name: name.isNotEmpty ? name : 'PulsePatch-C3',
              rssi: r.rssi,
            );
          }
        }
        if (!_isDisposed) {
          _discoveredDevicesController.add(discoveredMap.values.toList());
        }
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        withServices: [Guid(serviceUuid)],
      );
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
            }
          }
        }
      }

      _resetTimeoutWatchdog();
    } catch (_) {
      _handleDisconnect();
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
      lastReceivedTime: packet.receivedAt,
    );

    _packetController.add(packet);
    _diagnosticsController.add(_diagnostics);
  }

  void _resetTimeoutWatchdog() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 4), () {
      if (_currentState == BleConnectionState.connected && !_isDisposed) {
        _setState(BleConnectionState.noSensorData);
      }
    });
  }

  void _handleDisconnect() {
    _timeoutTimer?.cancel();
    _charSubscription?.cancel();
    _deviceStateSubscription?.cancel();
    _setState(BleConnectionState.disconnected);
  }

  @override
  Future<void> disconnect() async {
    _timeoutTimer?.cancel();
    await _charSubscription?.cancel();
    await _deviceStateSubscription?.cancel();
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }
    _setState(BleConnectionState.disconnected);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timeoutTimer?.cancel();
    _adapterSubscription?.cancel();
    _scanSubscription?.cancel();
    _deviceStateSubscription?.cancel();
    _charSubscription?.cancel();
    _connectionStateController.close();
    _discoveredDevicesController.close();
    _packetController.close();
    _diagnosticsController.close();
    _waveformController.close();
  }
}
