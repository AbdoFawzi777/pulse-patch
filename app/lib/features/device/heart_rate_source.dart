import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/session_record.dart';
import '../../domain/signal/ble_packet.dart';
import 'unified_heart_rate_source.dart';

enum BleConnectionState {
  bluetoothOff,
  permissionDenied,
  idle,
  scanning,
  connecting,
  bonding,
  discovering,
  checking,
  subscribing,
  connected,
  streaming,
  blocked,
  disconnected,
  reconnecting,
  noSensorData,
  timeout,
  failed,
}

enum BleDeviceCategory {
  pulsePatch('PulsePatch-C3', true),
  standardBle('Standard Heart Rate', true),
  genericBle('Generic BLE / UART', true),
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
    this.discoveredServices = const [],
    this.compatibilityStatus,
    this.gattErrorCode,
  });

  final String id;
  final String name;
  final int rssi;
  final BleDeviceCategory category;
  final List<String> advertisedServices;
  final List<String> discoveredServices;
  final String? compatibilityStatus;
  final int? gattErrorCode;

  bool get hasHeartRate =>
      advertisedServices.any((s) => s.toLowerCase().contains('180d')) ||
      discoveredServices.any((s) => s.toLowerCase().contains('180d'));

  bool get hasSpO2 =>
      advertisedServices.any((s) => s.toLowerCase().contains('1822')) ||
      discoveredServices.any((s) => s.toLowerCase().contains('1822'));

  bool get hasPulsePatch =>
      name.contains('PulsePatch') ||
      advertisedServices.any((s) => s.toLowerCase().contains('7243-4e64')) ||
      discoveredServices.any((s) => s.toLowerCase().contains('7243-4e64'));

  bool get isMiBand =>
      name.contains('Band 5') ||
      name.contains('Mi Smart') ||
      name.contains('Mi Band') ||
      advertisedServices.any(
        (s) =>
            s.toLowerCase().contains('fee0') ||
            s.toLowerCase().contains('fee1'),
      );

  bool get hasNordicUart =>
      advertisedServices.any((s) => s.toLowerCase().contains('6e40')) ||
      discoveredServices.any((s) => s.toLowerCase().contains('6e40'));

  bool get isCompatible =>
      hasHeartRate ||
      hasPulsePatch ||
      hasNordicUart ||
      isMiBand ||
      category.isCompatible;

  String get displayName {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == 'BLE Device ()' || trimmed == '()') {
      return 'Unnamed device';
    }
    return trimmed;
  }

  String get maskedId {
    if (id.length >= 17 && id.contains(':')) {
      final parts = id.split(':');
      if (parts.length == 6) {
        return '${parts[0]}:${parts[1]}:**:**:**:${parts[5]}';
      }
    }
    return id.length > 8
        ? '${id.substring(0, 4)}...${id.substring(id.length - 2)}'
        : id;
  }

  DiscoveredBleDevice copyWith({
    String? id,
    String? name,
    int? rssi,
    BleDeviceCategory? category,
    List<String>? advertisedServices,
    List<String>? discoveredServices,
    String? compatibilityStatus,
    int? gattErrorCode,
  }) {
    return DiscoveredBleDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      category: category ?? this.category,
      advertisedServices: advertisedServices ?? this.advertisedServices,
      discoveredServices: discoveredServices ?? this.discoveredServices,
      compatibilityStatus: compatibilityStatus ?? this.compatibilityStatus,
      gattErrorCode: gattErrorCode ?? this.gattErrorCode,
    );
  }
}

class PacketDiagnostics {
  const PacketDiagnostics({
    this.totalPackets = 0,
    this.malformedPackets = 0,
    this.lostPackets = 0,
    this.duplicatePackets = 0,
    this.packetRateHz = 0.0,
    this.lastReceivedTime,
  });

  final int totalPackets;
  final int malformedPackets;
  final int lostPackets;
  final int duplicatePackets;
  final double packetRateHz;
  final DateTime? lastReceivedTime;

  PacketDiagnostics copyWith({
    int? totalPackets,
    int? malformedPackets,
    int? lostPackets,
    int? duplicatePackets,
    double? packetRateHz,
    DateTime? lastReceivedTime,
  }) {
    return PacketDiagnostics(
      totalPackets: totalPackets ?? this.totalPackets,
      malformedPackets: malformedPackets ?? this.malformedPackets,
      lostPackets: lostPackets ?? this.lostPackets,
      duplicatePackets: duplicatePackets ?? this.duplicatePackets,
      packetRateHz: packetRateHz ?? this.packetRateHz,
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
  Future<DiscoveredBleDevice?> checkCompatibility(String deviceId);

  bool get isSimulator;
  String get sourceLabel;
  SessionSource get source;

  void dispose();
}

final heartRateSourceProvider = Provider<HeartRateSource>((ref) {
  try {
    return ref.watch(unifiedHeartRateSourceProvider);
  } catch (_) {
    final idle = IdleHeartRateSource();
    ref.onDispose(idle.dispose);
    return idle;
  }
});
