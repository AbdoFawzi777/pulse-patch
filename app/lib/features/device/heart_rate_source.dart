import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/signal/ble_packet.dart';
import 'simulated_heart_rate_source.dart';

enum BleConnectionState {
  bluetoothOff,
  permissionDenied,
  idle,
  scanning,
  connecting,
  connected,
  disconnected,
  reconnecting,
  noSensorData,
  timeout,
}

class DiscoveredBleDevice {
  const DiscoveredBleDevice({
    required this.id,
    required this.name,
    required this.rssi,
  });

  final String id;
  final String name;
  final int rssi;
}

class PacketDiagnostics {
  const PacketDiagnostics({
    this.totalPackets = 0,
    this.malformedPackets = 0,
    this.lostPackets = 0,
    this.duplicatePackets = 0,
    this.lastReceivedTime,
  });

  final int totalPackets;
  final int malformedPackets;
  final int lostPackets;
  final int duplicatePackets;
  final DateTime? lastReceivedTime;

  PacketDiagnostics copyWith({
    int? totalPackets,
    int? malformedPackets,
    int? lostPackets,
    int? duplicatePackets,
    DateTime? lastReceivedTime,
  }) {
    return PacketDiagnostics(
      totalPackets: totalPackets ?? this.totalPackets,
      malformedPackets: malformedPackets ?? this.malformedPackets,
      lostPackets: lostPackets ?? this.lostPackets,
      duplicatePackets: duplicatePackets ?? this.duplicatePackets,
      lastReceivedTime: lastReceivedTime ?? this.lastReceivedTime,
    );
  }
}

/// Abstract contract for heart rate telemetry providers (Physical BLE & Simulator).
abstract class HeartRateSource {
  Stream<BleConnectionState> get connectionStateStream;
  Stream<List<DiscoveredBleDevice>> get discoveredDevicesStream;
  Stream<BlePacket> get packetStream;
  Stream<PacketDiagnostics> get diagnosticsStream;
  Stream<double> get opticalWaveformStream;

  BleConnectionState get currentState;
  PacketDiagnostics get currentDiagnostics;

  Future<void> startScan();
  Future<void> stopScan();
  Future<void> connect(String deviceId);
  Future<void> disconnect();

  bool get isSimulator;
  String get sourceLabel;

  void dispose();
}

final heartRateSourceProvider = Provider<HeartRateSource>((ref) {
  // Default to SimulatedHeartRateSource for offline development & tests.
  // Switchable to BleHeartRateSource when connecting to hardware.
  final source = SimulatedHeartRateSource();
  ref.onDispose(source.dispose);
  return source;
});
