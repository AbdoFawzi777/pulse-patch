import 'dart:typed_data';
import 'ble_packet.dart';

/// Defensive parser for Bluetooth SIG Heart Rate Measurement Characteristic (0x2A37).
/// Implements full specification: 8-bit & 16-bit BPM, sensor contact bits,
/// energy expended offset handling, and optional RR-intervals.
class StandardBleHrParser {
  const StandardBleHrParser._();

  static const int minPacketLength = 2;

  /// Parses raw byte payload from characteristic 0x2A37 into a BlePacket.
  /// Computes estimated quality based on sensor contact, packet continuity, and rate jump limits.
  static BlePacket? parse(
    List<int> rawBytes, {
    DateTime? receivedAt,
    int? sequenceNumber,
    double? lastBpm,
    DateTime? lastSampleTime,
  }) {
    if (rawBytes.length < minPacketLength) {
      return null;
    }

    final now = receivedAt ?? DateTime.now();
    final data = ByteData.sublistView(Uint8List.fromList(rawBytes));
    final flags = data.getUint8(0);

    // Bit 0: Heart Rate Value Format (0 = UINT8, 1 = UINT16)
    final is16Bit = (flags & 0x01) != 0;
    int offset = 1;

    final double bpm;
    if (is16Bit) {
      if (rawBytes.length < offset + 2) return null;
      bpm = data.getUint16(offset, Endian.little).toDouble();
      offset += 2;
    } else {
      bpm = data.getUint8(offset).toDouble();
      offset += 1;
    }

    // Bits 1-2: Sensor Contact Status
    // Bit 1: Sensor Contact Supported (1 = supported, 0 = not supported)
    // Bit 2: Sensor Contact Detected (1 = contact detected, 0 = not detected)
    final bool contactSupported = (flags & 0x02) != 0;
    final bool contactDetected;
    if (contactSupported) {
      contactDetected = (flags & 0x04) != 0;
    } else {
      // If sensor contact is not supported by peripheral, assume valid contact
      contactDetected = true;
    }

    // Bit 3: Energy Expended Status (1 = UINT16 present in next 2 bytes)
    final hasEnergyExpended = (flags & 0x08) != 0;
    if (hasEnergyExpended && rawBytes.length >= offset + 2) {
      offset += 2; // skip energy expended
    }

    // Bit 4: RR-Interval Status (1 = one or more UINT16 values present)
    final hasRrIntervals = (flags & 0x10) != 0;
    List<double>? rrIntervals;
    if (hasRrIntervals && rawBytes.length >= offset + 2) {
      final rrList = <double>[];
      while (offset + 2 <= rawBytes.length) {
        final raw16 = data.getUint16(offset, Endian.little);
        // RR units are 1/1024 of a second -> convert to milliseconds
        final rrMs = (raw16 * 1000.0) / 1024.0;
        rrList.add(rrMs);
        offset += 2;
      }
      if (rrList.isNotEmpty) {
        rrIntervals = rrList;
      }
    }

    // Estimate Quality (0-100) since standard 0x2A37 peripheral lacks MAX30102 hardware SQI
    final int estimatedQuality = _calculateEstimatedQuality(
      contactDetected: contactDetected,
      bpm: bpm,
      lastBpm: lastBpm,
      currentTime: now,
      lastSampleTime: lastSampleTime,
    );

    return BlePacket(
      protocolVersion: 1,
      contactDetected: contactDetected,
      motionSuspected: false,
      rawBpm: (bpm > 0 && bpm < 255) ? bpm : null,
      quality: estimatedQuality,
      deviceTimestampMs: now.millisecondsSinceEpoch,
      sequenceNumber: sequenceNumber ?? 0,
      receivedAt: now,
      isQualityEstimated: true,
      rrIntervalsMs: rrIntervals,
    );
  }

  /// Calculates derived quality (0-100) from sensor contact, continuity, and jump limits.
  static int _calculateEstimatedQuality({
    required bool contactDetected,
    required double bpm,
    double? lastBpm,
    required DateTime currentTime,
    DateTime? lastSampleTime,
  }) {
    if (!contactDetected || bpm <= 0 || bpm > 240) {
      return 0;
    }

    double continuityScore = 100.0;
    if (lastSampleTime != null) {
      final deltaMs = currentTime.difference(lastSampleTime).inMilliseconds;
      if (deltaMs > 3000) {
        continuityScore = 40.0;
      } else if (deltaMs > 2000) {
        continuityScore = 70.0;
      } else if (deltaMs < 400) {
        // Unusually rapid packet rate
        continuityScore = 80.0;
      }
    }

    double stabilityScore = 100.0;
    if (lastBpm != null) {
      final diff = (bpm - lastBpm).abs();
      if (diff > 25.0) {
        stabilityScore = 30.0;
      } else if (diff > 15.0) {
        stabilityScore = 60.0;
      } else if (diff > 8.0) {
        stabilityScore = 85.0;
      }
    }

    final quality = (continuityScore * 0.5 + stabilityScore * 0.5).round();
    return quality.clamp(0, 100);
  }
}
