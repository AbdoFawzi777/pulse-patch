import 'dart:convert';
import 'package:app/domain/signal/generic_ble_hr_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GenericBleHrParser Tests', () {
    test('uint8 format parses valid BPM within 30-220 gate', () {
      final packet = GenericBleHrParser.parse([
        72,
      ], format: GenericBleFormat.uint8);
      expect(packet, isNotNull);
      expect(packet!.rawBpm, 72.0);
    });

    test('uint8 rejects BPM outside 30-220 validity gate', () {
      final low = GenericBleHrParser.parse([
        25,
      ], format: GenericBleFormat.uint8);
      expect(low, isNull);

      final high = GenericBleHrParser.parse([
        225,
      ], format: GenericBleFormat.uint8);
      expect(high, isNull);
    });

    test('uint16Le format parses little-endian integer BPM', () {
      // 80 BPM -> 0x0050 -> [0x50, 0x00]
      final packet = GenericBleHrParser.parse([
        0x50,
        0x00,
      ], format: GenericBleFormat.uint16Le);
      expect(packet, isNotNull);
      expect(packet!.rawBpm, 80.0);
    });

    test('uint16Le rejects insufficient bytes', () {
      final packet = GenericBleHrParser.parse([
        0x50,
      ], format: GenericBleFormat.uint16Le);
      expect(packet, isNull);
    });

    test('uint16x10 format parses 0.1 BPM precision', () {
      // 745 -> 74.5 BPM -> 745 = 0x02E9 -> [0xE9, 0x02]
      final packet = GenericBleHrParser.parse([
        0xE9,
        0x02,
      ], format: GenericBleFormat.uint16x10);
      expect(packet, isNotNull);
      expect(packet!.rawBpm, closeTo(74.5, 0.01));
    });

    test('asciiRegex format parses plain numbers and tagged strings', () {
      final p1 = GenericBleHrParser.parse(
        utf8.encode('78\n'),
        format: GenericBleFormat.asciiRegex,
      );
      expect(p1, isNotNull);
      expect(p1!.rawBpm, 78.0);

      final p2 = GenericBleHrParser.parse(
        utf8.encode('BPM:84'),
        format: GenericBleFormat.asciiRegex,
        customRegex: r'BPM:(\d+)',
      );
      expect(p2, isNotNull);
      expect(p2!.rawBpm, 84.0);

      final p3 = GenericBleHrParser.parse(
        utf8.encode('HR=115;STATUS=OK'),
        format: GenericBleFormat.asciiRegex,
        customRegex: r'HR=(\d+)',
      );
      expect(p3, isNotNull);
      expect(p3!.rawBpm, 115.0);
    });

    test('asciiRegex rejects non-numeric or out-of-range lines', () {
      final p1 = GenericBleHrParser.parse(
        utf8.encode('NO_DATA'),
        format: GenericBleFormat.asciiRegex,
      );
      expect(p1, isNull);

      final p2 = GenericBleHrParser.parse(
        utf8.encode('BPM:12'),
        format: GenericBleFormat.asciiRegex,
        customRegex: r'BPM:(\d+)',
      );
      expect(p2, isNull); // 12 < 30
    });

    test('GenericBleMapping json serialization round-trip', () {
      const mapping = GenericBleMapping(
        deviceId: 'AA:BB:CC:DD:EE:FF',
        serviceUuid: '6e400001-b5a3-f393-e0a9-e50e24dcca9e',
        characteristicUuid: '6e400003-b5a3-f393-e0a9-e50e24dcca9e',
        format: GenericBleFormat.uint16Le,
        customRegex: r'(\d+)',
      );
      final json = mapping.toJson();
      final restored = GenericBleMapping.fromJson(json);

      expect(restored.deviceId, mapping.deviceId);
      expect(restored.serviceUuid, mapping.serviceUuid);
      expect(restored.characteristicUuid, mapping.characteristicUuid);
      expect(restored.format, GenericBleFormat.uint16Le);
    });
  });
}
