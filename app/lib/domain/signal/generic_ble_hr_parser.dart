import 'dart:convert';
import 'ble_packet.dart';

/// Supported wire formats for generic BLE heart-rate stream.
enum GenericBleFormat {
  uint8('uint8', 'uint8 BPM'),
  uint16Le('uint16_le', 'uint16 little-endian BPM'),
  uint16x10('uint16_x10', 'uint16 BPM x10 (e.g. 720 = 72.0)'),
  asciiRegex('ascii_regex', 'ASCII text line (e.g. "BPM:72")');

  const GenericBleFormat(this.code, this.label);
  final String code;
  final String label;

  static GenericBleFormat fromString(String val) {
    for (final f in GenericBleFormat.values) {
      if (f.code == val || f.name == val) return f;
    }
    return GenericBleFormat.uint8;
  }
}

/// Saved mapping for a generic BLE device.
class GenericBleMapping {
  const GenericBleMapping({
    required this.deviceId,
    required this.serviceUuid,
    required this.characteristicUuid,
    this.format = GenericBleFormat.uint8,
    this.customRegex = r'(\d{2,3})',
  });

  final String deviceId;
  final String serviceUuid;
  final String characteristicUuid;
  final GenericBleFormat format;
  final String customRegex;

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'serviceUuid': serviceUuid,
    'characteristicUuid': characteristicUuid,
    'format': format.code,
    'customRegex': customRegex,
  };

  factory GenericBleMapping.fromJson(Map<String, dynamic> json) =>
      GenericBleMapping(
        deviceId: json['deviceId'] as String? ?? '',
        serviceUuid: json['serviceUuid'] as String? ?? '',
        characteristicUuid: json['characteristicUuid'] as String? ?? '',
        format: GenericBleFormat.fromString(
          json['format'] as String? ?? 'uint8',
        ),
        customRegex: json['customRegex'] as String? ?? r'(\d{2,3})',
      );
}

/// Parser for generic BLE heart-rate stream with 30-220 BPM validity gate.
class GenericBleHrParser {
  static const double minBpm = 30.0;
  static const double maxBpm = 220.0;

  static BlePacket? parse(
    List<int> bytes, {
    required GenericBleFormat format,
    String customRegex = r'(\d{2,3})',
    DateTime? receivedAt,
    int sequenceNumber = 0,
    double? lastBpm,
    DateTime? lastSampleTime,
  }) {
    if (bytes.isEmpty) return null;
    final now = receivedAt ?? DateTime.now();
    double? rawBpm;

    switch (format) {
      case GenericBleFormat.uint8:
        rawBpm = bytes[0].toDouble();
        break;

      case GenericBleFormat.uint16Le:
        if (bytes.length < 2) return null;
        rawBpm = (bytes[0] | (bytes[1] << 8)).toDouble();
        break;

      case GenericBleFormat.uint16x10:
        if (bytes.length < 2) return null;
        final rawVal = (bytes[0] | (bytes[1] << 8)).toDouble();
        rawBpm = rawVal / 10.0;
        break;

      case GenericBleFormat.asciiRegex:
        try {
          final text = utf8.decode(bytes, allowMalformed: true).trim();
          final reg = RegExp(
            customRegex.isNotEmpty ? customRegex : r'(\d{2,3})',
          );
          final match = reg.firstMatch(text);
          if (match != null && match.groupCount >= 1) {
            rawBpm = double.tryParse(match.group(1)!);
          } else {
            rawBpm = double.tryParse(text);
          }
        } catch (_) {
          return null;
        }
        break;
    }

    if (rawBpm == null) return null;

    // 30 - 220 BPM validity gate
    if (rawBpm < minBpm || rawBpm > maxBpm) {
      return null;
    }

    // Synthesize RR interval if possible
    List<double>? rrIntervals;
    if (lastBpm != null && lastSampleTime != null) {
      final elapsed = now.difference(lastSampleTime).inMilliseconds.toDouble();
      if (elapsed > 250 && elapsed < 2000) {
        rrIntervals = [elapsed];
      }
    }
    rrIntervals ??= [60000.0 / rawBpm];

    return BlePacket(
      protocolVersion: 1,
      contactDetected: true,
      motionSuspected: false,
      rawBpm: rawBpm,
      quality: 90,
      deviceTimestampMs: now.millisecondsSinceEpoch,
      sequenceNumber: sequenceNumber,
      receivedAt: now,
      isQualityEstimated: true,
      rrIntervalsMs: rrIntervals,
    );
  }
}
