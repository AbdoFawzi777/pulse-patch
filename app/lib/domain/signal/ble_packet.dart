import 'dart:typed_data';

/// Defensive BLE packet parser matching the 12-byte GATT contract.
class BlePacket {
  const BlePacket({
    required this.protocolVersion,
    required this.contactDetected,
    required this.motionSuspected,
    required this.rawBpm,
    required this.quality,
    required this.deviceTimestampMs,
    required this.sequenceNumber,
    required this.receivedAt,
    this.spo2,
    this.isQualityEstimated = false,
    this.rrIntervalsMs,
  });

  final int protocolVersion;
  final bool contactDetected;
  final bool motionSuspected;
  final double? rawBpm; // Null if 0xFFFF (calculating/invalid)
  final int quality; // 0 to 100
  final int deviceTimestampMs;
  final int sequenceNumber;
  final DateTime receivedAt;
  final double? spo2; // Optional SpO2 reported by device (e.g. 98.0%)
  final bool
  isQualityEstimated; // True if calculated from continuity/jump limits
  final List<double>? rrIntervalsMs; // Optional RR intervals in ms

  static const int expectedPacketLength = 12;
  static const int currentProtocolVersion = 1;

  /// Parses raw byte payload defensively. Returns null if malformed.
  static BlePacket? parse(List<int> rawBytes, {DateTime? receivedAt}) {
    if (rawBytes.length != expectedPacketLength) {
      return null;
    }

    final data = ByteData.sublistView(Uint8List.fromList(rawBytes));

    final version = data.getUint8(0);
    if (version != currentProtocolVersion) {
      return null;
    }

    final flags = data.getUint8(1);
    final contact = (flags & 0x01) != 0;
    final motion = (flags & 0x02) != 0;

    final bpmTimes10 = data.getUint16(2, Endian.little);
    double? bpm;
    if (bpmTimes10 != 0xFFFF) {
      bpm = bpmTimes10 / 10.0;
    }

    final quality = data.getUint8(4).clamp(0, 100);
    final timestampMs = data.getUint32(5, Endian.little);
    final sequence = data.getUint16(9, Endian.little);
    final rawSpo2 = data.getUint8(11);
    final double? spo2 = (rawSpo2 >= 70 && rawSpo2 <= 100) ? rawSpo2.toDouble() : null;

    return BlePacket(
      protocolVersion: version,
      contactDetected: contact,
      motionSuspected: motion,
      rawBpm: bpm,
      quality: quality,
      deviceTimestampMs: timestampMs,
      sequenceNumber: sequence,
      receivedAt: receivedAt ?? DateTime.now(),
      spo2: spo2,
    );
  }

  /// Encodes this packet into a 12-byte little-endian payload (used by simulator and firmware verification).
  Uint8List toBytes() {
    final buffer = Uint8List(expectedPacketLength);
    final data = ByteData.sublistView(buffer);

    data.setUint8(0, protocolVersion);

    int flags = 0;
    if (contactDetected) flags |= 0x01;
    if (motionSuspected) flags |= 0x02;
    data.setUint8(1, flags);

    if (rawBpm != null) {
      data.setUint16(2, (rawBpm! * 10).round().clamp(0, 65534), Endian.little);
    } else {
      data.setUint16(2, 0xFFFF, Endian.little);
    }

    data.setUint8(4, quality.clamp(0, 100));
    data.setUint32(5, deviceTimestampMs, Endian.little);
    data.setUint16(9, sequenceNumber & 0xFFFF, Endian.little);
    if (spo2 != null && spo2! >= 70 && spo2! <= 100) {
      data.setUint8(11, spo2!.round().clamp(70, 100));
    } else {
      data.setUint8(11, 0); // calculating / uncalibrated
    }

    return buffer;
  }
}
