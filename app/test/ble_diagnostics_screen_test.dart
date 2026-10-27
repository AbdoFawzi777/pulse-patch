import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/domain/signal/ble_packet.dart';
import 'package:app/features/diagnostics/ble_diagnostics_screen.dart';

void main() {
  group('BleDiagnosticsScreen Widget Tests', () {
    testWidgets('renders diagnostic banner and empty state cleanly', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: BleDiagnosticsScreen()),
      );

      expect(find.text('BLE Diagnostics'), findsOneWidget);
      expect(
        find.text('DIAGNOSTIC ONLY — Hardware Bring-Up & Telemetry'),
        findsOneWidget,
      );
      expect(find.text('Device & GATT Link'), findsOneWidget);
      expect(find.text('Packet Stream Telemetry'), findsOneWidget);
      expect(find.text('No packet received'), findsOneWidget);
      expect(
        find.text(
          'No packet decoded yet. Connect device and start measurement.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders decoded packet fields and raw hex correctly', (
      tester,
    ) async {
      final sampleBytes = Uint8List.fromList([
        0x01, 0x01, // Version 1, contact=true
        0x48, 0x03, // 840 -> 84.0 BPM
        0x5F, // SQI 95%
        0xE8, 0x03, 0x00, 0x00, // 1000 ms
        0x0C, 0x00, // seq 12
        0x00, // reserved
      ]);
      final packet = BlePacket.parse(sampleBytes);

      await tester.pumpWidget(
        MaterialApp(
          home: BleDiagnosticsScreen(
            lastRawBytes: sampleBytes,
            parsedPacket: packet,
            packetsPerSecond: 1.0,
            sequenceGaps: 0,
            parseRejects: 0,
            rssi: -58,
          ),
        ),
      );

      expect(find.text('01 01 48 03 5F E8 03 00 00 0C 00 00'), findsOneWidget);
      expect(find.text('84.0 BPM'), findsOneWidget);
      expect(find.text('95%'), findsOneWidget);
      expect(find.text('#12'), findsOneWidget);
      expect(find.text('1000 ms'), findsOneWidget);
      expect(find.text('-58 dBm'), findsOneWidget);
    });
  });
}
