import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/domain/entities/session_record.dart';
import 'package:app/domain/signal/ble_packet.dart';
import 'package:app/features/device/heart_rate_source.dart';
import 'package:app/features/device/mi_band_5_source.dart';
import 'package:app/features/device/pulse_patch_source.dart';
import 'package:app/features/device/simulated_heart_rate_source.dart';
import 'package:app/features/device/standard_ble_heart_rate_source.dart';

void main() {
  group('Phase 4 BLE Layer - BlePacket Defensive Parser', () {
    test('Parses valid 12-byte little-endian packet accurately', () {
      final buffer = Uint8List(12);
      final byteData = ByteData.sublistView(buffer);

      byteData.setUint8(0, 1); // Protocol version 1
      byteData.setUint8(1, 0x01); // contactDetected = true, motion = false
      byteData.setUint16(2, 742, Endian.little); // 74.2 BPM
      byteData.setUint8(4, 95); // Quality 95
      byteData.setUint32(5, 54321, Endian.little); // timestamp
      byteData.setUint16(9, 42, Endian.little); // sequence 42

      final packet = BlePacket.parse(buffer);
      expect(packet, isNotNull);
      expect(packet!.protocolVersion, 1);
      expect(packet.contactDetected, isTrue);
      expect(packet.motionSuspected, isFalse);
      expect(packet.rawBpm, 74.2);
      expect(packet.quality, 95);
      expect(packet.deviceTimestampMs, 54321);
      expect(packet.sequenceNumber, 42);
    });

    test('Parses 0xFFFF as null rawBpm (calculating state)', () {
      final buffer = Uint8List(12);
      final byteData = ByteData.sublistView(buffer);

      byteData.setUint8(0, 1);
      byteData.setUint8(1, 0);
      byteData.setUint16(2, 0xFFFF, Endian.little);
      byteData.setUint8(4, 50);
      byteData.setUint32(5, 1000, Endian.little);
      byteData.setUint16(9, 1, Endian.little);

      final packet = BlePacket.parse(buffer);
      expect(packet, isNotNull);
      expect(packet!.rawBpm, isNull);
    });

    test('Rejects malformed packets with invalid length or version', () {
      expect(BlePacket.parse([1, 2, 3]), isNull);
      expect(BlePacket.parse(List.filled(14, 0)), isNull);

      final wrongVersion = Uint8List(12);
      wrongVersion[0] = 99; // Unknown version
      expect(BlePacket.parse(wrongVersion), isNull);
    });

    test('Packet toBytes round-trips through parse accurately', () {
      final original = BlePacket(
        protocolVersion: 1,
        contactDetected: true,
        motionSuspected: true,
        rawBpm: 81.5,
        quality: 88,
        deviceTimestampMs: 123456,
        sequenceNumber: 777,
        receivedAt: DateTime.now(),
      );

      final encoded = original.toBytes();
      expect(encoded.length, 12);

      final parsed = BlePacket.parse(encoded);
      expect(parsed, isNotNull);
      expect(parsed!.protocolVersion, original.protocolVersion);
      expect(parsed.contactDetected, isTrue);
      expect(parsed.motionSuspected, isTrue);
      expect(parsed.rawBpm, 81.5);
      expect(parsed.quality, 88);
      expect(parsed.deviceTimestampMs, 123456);
      expect(parsed.sequenceNumber, 777);
    });
  });

  group('Phase 4 BLE Layer - SimulatedHeartRateSource', () {
    late SimulatedHeartRateSource simSource;

    setUp(() {
      simSource = SimulatedHeartRateSource(baseBpm: 74.0);
    });

    tearDown(() {
      simSource.dispose();
    });

    test('Reports simulator identity and label truthfully', () {
      expect(simSource.isSimulator, isTrue);
      expect(simSource.sourceLabel, 'Simulator');
      expect(simSource.currentState, BleConnectionState.idle);
    });

    test('Scanning emits simulated PulsePatch devices', () async {
      final devicesFuture = simSource.discoveredDevicesStream.first;
      await simSource.startScan();
      expect(simSource.currentState, BleConnectionState.scanning);

      final devices = await devicesFuture;
      expect(devices.isNotEmpty, isTrue);
      expect(devices.first.name.contains('PulsePatch'), isTrue);

      await simSource.stopScan();
      expect(simSource.currentState, BleConnectionState.idle);
    });

    test('Connection emits valid packets and optical waveforms', () async {
      await simSource.connect('SIM-C3-01');
      expect(simSource.currentState, BleConnectionState.connected);

      final packet = await simSource.packetStream.first;
      expect(packet.rawBpm, inInclusiveRange(70.0, 78.0));
      expect(packet.quality, greaterThanOrEqualTo(90));
      expect(packet.contactDetected, isTrue);

      final waveformPoint = await simSource.opticalWaveformStream.first;
      expect(waveformPoint, inInclusiveRange(0.0, 1.0));

      await simSource.disconnect();
      expect(simSource.currentState, BleConnectionState.disconnected);
    });
  });

  group('Phase 4 BLE Layer - Source Adapters & Categorization', () {
    test(
      'StandardBleHeartRateSource exposes correct source enum and labels',
      () {
        final stdSource = StandardBleHeartRateSource(
          customDeviceName: 'Polar H10',
        );
        expect(stdSource.source, SessionSource.standardBle);
        expect(stdSource.sourceLabel, 'Polar H10');
        expect(stdSource.isSimulator, isFalse);
        expect(stdSource.currentState, BleConnectionState.idle);
        stdSource.dispose();
      },
    );

    test('MiBand5Source exposes correct source enum and labels', () {
      final bandSource = MiBand5Source();
      expect(bandSource.source, SessionSource.miBand5);
      expect(bandSource.sourceLabel, 'Mi Smart Band 5');
      expect(bandSource.isSimulator, isFalse);
      expect(bandSource.currentState, BleConnectionState.idle);
      bandSource.dispose();
    });

    test('PulsePatchSource exposes correct source enum and labels', () {
      final patchSource = PulsePatchSource();
      expect(patchSource.source, SessionSource.pulsepatch);
      expect(patchSource.sourceLabel, 'PulsePatch-C3');
      expect(patchSource.isSimulator, isFalse);
      expect(patchSource.currentState, BleConnectionState.idle);
      patchSource.dispose();
    });

    test('DiscoveredBleDevice accurately classifies device categories', () {
      const patchDev = DiscoveredBleDevice(
        id: 'dev-1',
        name: 'PulsePatch-C3',
        rssi: -50,
        category: BleDeviceCategory.pulsePatch,
      );
      expect(patchDev.isCompatible, isTrue);

      const bandDev = DiscoveredBleDevice(
        id: 'dev-2',
        name: 'Mi Smart Band 5',
        rssi: -65,
        category: BleDeviceCategory.miBand,
      );
      expect(bandDev.isCompatible, isTrue);

      const polarDev = DiscoveredBleDevice(
        id: 'dev-3',
        name: 'Polar H10',
        rssi: -70,
        category: BleDeviceCategory.standardBle,
      );
      expect(polarDev.isCompatible, isTrue);

      const speakerDev = DiscoveredBleDevice(
        id: 'dev-4',
        name: 'JBL Flip',
        rssi: -80,
        category: BleDeviceCategory.unknown,
      );
      expect(speakerDev.isCompatible, isFalse);
    });
  });
}
