import 'ble_packet.dart';
import 'signal_constants.dart';

enum RejectReason {
  none,
  noContact,
  nullBpm,
  outOfRange,
  lowQuality,
  excessiveJump,
  motionDetected,
}

class GatedSample {
  const GatedSample({
    required this.packet,
    required this.isValid,
    required this.rejectReason,
    this.bpm,
  });

  final BlePacket packet;
  final bool isValid;
  final RejectReason rejectReason;
  final double? bpm;
}

/// Pure Dart validity gate for quality-filtering raw MAX30102 packets.
class ValidityGate {
  ValidityGate({
    this.minBpm = SignalConstants.minValidBpm,
    this.maxBpm = SignalConstants.maxValidBpm,
    this.minQuality = SignalConstants.minQualityThreshold,
    this.maxJump = SignalConstants.maxStepJumpBpm,
  });

  final double minBpm;
  final double maxBpm;
  final int minQuality;
  final double maxJump;

  double? _lastValidBpm;
  DateTime? _lastValidTime;

  /// Resets the gate's memory (e.g. at the start of a new session).
  void reset() {
    _lastValidBpm = null;
    _lastValidTime = null;
  }

  GatedSample evaluate(BlePacket packet) {
    if (!packet.contactDetected) {
      return GatedSample(
        packet: packet,
        isValid: false,
        rejectReason: RejectReason.noContact,
      );
    }

    final raw = packet.rawBpm;
    if (raw == null) {
      return GatedSample(
        packet: packet,
        isValid: false,
        rejectReason: RejectReason.nullBpm,
      );
    }

    if (raw < minBpm || raw > maxBpm) {
      return GatedSample(
        packet: packet,
        isValid: false,
        rejectReason: RejectReason.outOfRange,
      );
    }

    if (packet.quality < minQuality) {
      return GatedSample(
        packet: packet,
        isValid: false,
        rejectReason: RejectReason.lowQuality,
      );
    }

    // Step jump validation between consecutive seconds
    if (_lastValidBpm != null && _lastValidTime != null) {
      final elapsed = packet.receivedAt.difference(_lastValidTime!);
      // If elapsed is within 2.5 seconds, enforce jump limit
      if (elapsed.inMilliseconds < 2500) {
        final jump = (raw - _lastValidBpm!).abs();
        if (jump > maxJump) {
          return GatedSample(
            packet: packet,
            isValid: false,
            rejectReason: RejectReason.excessiveJump,
          );
        }
      }
    }

    _lastValidBpm = raw;
    _lastValidTime = packet.receivedAt;

    return GatedSample(
      packet: packet,
      isValid: true,
      rejectReason: RejectReason.none,
      bpm: raw,
    );
  }
}
