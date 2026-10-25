import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/preferences_repository.dart';
import '../../domain/entities/session_record.dart';
import '../../domain/signal/ble_packet.dart';
import 'simulated_heart_rate_source.dart';
import 'unified_heart_rate_source.dart';

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

enum BleDeviceCategory {
  pulsePatch('PulsePatch-C3', true),
  standardBle('Standard Heart Rate', true),
  miBand('Mi Smart Band 5', true),
  unknown('Other Bluetooth Device', false);

  const BleDeviceCategory(this.label, this.isCompatible);
  final String label;
  final bool isCompatible;
}

class DiscoveredBleDevice {
  const DiscoveredBleDevice({
    required this.id,
    required this.name,
    required this.rssi,
    this.category = BleDeviceCategory.unknown,
    this.advertisedServices = const [],
  });

  final String id;
  final String name;
  final int rssi;
  final BleDeviceCategory category;
  final List<String> advertisedServices;

  bool get isCompatible => category.isCompatible;
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
  SessionSource get source;

  void dispose();
}

final heartRateSourceProvider = Provider<HeartRateSource>((ref) {
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    final source = UnifiedHeartRateSource(prefs: prefs);
    ref.onDispose(source.dispose);
    return source;
  } catch (_) {
    final source = SimulatedHeartRateSource();
    ref.onDispose(source.dispose);
    return source;
  }
});
