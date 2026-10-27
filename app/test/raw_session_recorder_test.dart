import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/domain/signal/ble_packet.dart';
import 'package:app/features/diagnostics/raw_session_recorder.dart';

void main() {
  group('RawSessionRecorder Tests', () {
    test('initializes and records packets in memory CSV format', () async {
      final recorder = RawSessionRecorder();
      expect(recorder.isRecording, isFalse);
      expect(recorder.packetCount, equals(0));

      await recorder.start();
      expect(recorder.isRecording, isTrue);
      expect(recorder.packetCount, equals(1)); // Header row

      final rawBytes = Uint8List.fromList([
        0x01, 0x01, // Version 1, contact=true
        0x50, 0x03, // 848 -> 84.8 BPM
        0x5A, // SQI 90
        0x10, 0x27, 0x00, 0x00, // 10000 ms
        0x01, 0x00, // Seq 1
        0x00, // reserved
      ]);
      final packet = BlePacket.parse(rawBytes);

      final now = DateTime(2026, 10, 27, 12, 0, 0);
      recorder.recordPacket(
        rawBytes: rawBytes,
        parsed: packet,
        receivedAt: now,
      );

      expect(recorder.packetCount, equals(2));
      final csv = await recorder.stop();
      expect(recorder.isRecording, isFalse);

      final lines = csv.split('\n');
      expect(lines.length, equals(2));
      expect(lines[0], equals('hex,receivedAt,deviceTimestampMs,seq,bpm,sqi,flags'));
      expect(lines[1], contains('010150035A10270000010000'));
      expect(lines[1], contains('10000,1,84.8,90,1'));
    });
  });
}
