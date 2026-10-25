import 'package:flutter_test/flutter_test.dart';
import 'package:app/domain/signal/standard_ble_hr_parser.dart';

void main() {
  group('Standard BLE 0x2A37 Parser Tests', () {
    test('Parses 8-bit BPM correctly with contact supported and detected', () {
      // Flags: bit 0 = 0 (UINT8), bit 1 = 1 (contact supported), bit 2 = 1 (contact detected)
      // Flags byte: 0x06 (0b00000110)
      // BPM byte: 75 (0x4B)
      final raw = [0x06, 75];
      final packet = StandardBleHrParser.parse(raw);

      expect(packet, isNotNull);
      expect(packet!.rawBpm, 75.0);
      expect(packet.contactDetected, isTrue);
      expect(packet.isQualityEstimated, isTrue);
      expect(packet.quality, inInclusiveRange(70, 100));
      expect(packet.rrIntervalsMs, isNull);
    });

    test('Parses 16-bit BPM correctly', () {
      // Flags: bit 0 = 1 (UINT16), bit 1 = 1 (contact supported), bit 2 = 1 (contact detected)
      // Flags byte: 0x07 (0b00000111)
      // BPM uint16 little-endian: 180 (0x00B4) -> [0xB4, 0x00]
      final raw = [0x07, 0xB4, 0x00];
      final packet = StandardBleHrParser.parse(raw);

      expect(packet, isNotNull);
      expect(packet!.rawBpm, 180.0);
      expect(packet.contactDetected, isTrue);
    });

    test('Parses contact NOT detected flag and yields quality 0', () {
      // Flags: bit 0 = 0 (UINT8), bit 1 = 1 (contact supported), bit 2 = 0 (contact NOT detected)
      // Flags byte: 0x02 (0b00000010)
      // BPM byte: 72
      final raw = [0x02, 72];
      final packet = StandardBleHrParser.parse(raw);

      expect(packet, isNotNull);
      expect(packet!.contactDetected, isFalse);
      expect(packet.quality, 0);
    });

    test('Assumes contact detected when contact feature is not supported', () {
      // Flags: bit 0 = 0 (UINT8), bit 1 = 0 (contact not supported)
      // Flags byte: 0x00
      // BPM byte: 68
      final raw = [0x00, 68];
      final packet = StandardBleHrParser.parse(raw);

      expect(packet, isNotNull);
      expect(packet!.contactDetected, isTrue);
      expect(packet.quality, greaterThan(0));
    });

    test('Skips Energy Expended field and parses RR intervals accurately', () {
      // Flags:
      // bit 0 = 0 (UINT8)
      // bit 1 = 0 (contact not supported)
      // bit 3 = 1 (energy expended present) -> +0x08
      // bit 4 = 1 (RR intervals present) -> +0x10
      // Flags: 0x18 (0b00011000)
      // BPM: 80
      // Energy Expended uint16: 250 kJ -> [0xFA, 0x00]
      // RR Interval 1: 1024 (exactly 1.0 second = 1000.0 ms) -> [0x00, 0x04] (0x0400 = 1024)
      // RR Interval 2: 819 (approx 800 ms = 819.2) -> [0x33, 0x03] (0x0333 = 819)
      final raw = [0x18, 80, 0xFA, 0x00, 0x00, 0x04, 0x33, 0x03];
      final packet = StandardBleHrParser.parse(raw);

      expect(packet, isNotNull);
      expect(packet!.rawBpm, 80.0);
      expect(packet.rrIntervalsMs, isNotNull);
      expect(packet.rrIntervalsMs!.length, 2);
      expect(packet.rrIntervalsMs![0], closeTo(1000.0, 0.5));
      expect(packet.rrIntervalsMs![1], closeTo(799.8, 1.0));
    });

    test('Defensively rejects malformed or truncated byte arrays', () {
      // Empty
      expect(StandardBleHrParser.parse([]), isNull);
      // Single byte (flags only, missing BPM)
      expect(StandardBleHrParser.parse([0x00]), isNull);
      // 16-bit flag set but only 1 BPM byte supplied
      expect(StandardBleHrParser.parse([0x01, 70]), isNull);
    });

    test('Estimates quality degradation during sudden rate jumps and delay', () {
      final t0 = DateTime(2026, 10, 25, 12, 0, 0);
      final p0 = StandardBleHrParser.parse([0x00, 70], receivedAt: t0);
      expect(p0!.quality, 100);

      // Packet with huge rate jump (70 -> 120 = jump of 50 BPM) after 4 seconds
      final t1 = t0.add(const Duration(seconds: 4));
      final p1 = StandardBleHrParser.parse(
        [0x00, 120],
        receivedAt: t1,
        lastBpm: 70.0,
        lastSampleTime: t0,
      );

      expect(p1!.quality, lessThan(50));
    });
  });
}
