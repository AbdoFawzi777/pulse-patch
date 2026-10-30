import 'package:flutter_test/flutter_test.dart';
import 'package:app/domain/signal/ble_packet.dart';

void main() {
  group('BlePacket SpO2 Field Verification', () {
    test('extracts SpO2 from byte 11 when within 70..100 range', () {
      final packet = BlePacket(
        protocolVersion: 1,
        contactDetected: true,
        motionSuspected: false,
        rawBpm: 72.5,
        quality: 95,
        deviceTimestampMs: 12000,
        sequenceNumber: 42,
        receivedAt: DateTime.now(),
        spo2: 98.0,
      );

      final bytes = packet.toBytes();
      expect(bytes[11], equals(98));

      final parsed = BlePacket.parse(bytes);
      expect(parsed, isNotNull);
      expect(parsed!.spo2, equals(98.0));
    });

    test('ignores invalid or 0x00 SpO2 byte (calculating state)', () {
      final packet = BlePacket(
        protocolVersion: 1,
        contactDetected: true,
        motionSuspected: false,
        rawBpm: 60.0,
        quality: 80,
        deviceTimestampMs: 5000,
        sequenceNumber: 1,
        receivedAt: DateTime.now(),
        spo2: null,
      );

      final bytes = packet.toBytes();
      expect(bytes[11], equals(0));

      final parsed = BlePacket.parse(bytes);
      expect(parsed, isNotNull);
      expect(parsed!.spo2, isNull);
    });
  });
}
