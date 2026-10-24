import 'package:flutter_test/flutter_test.dart';
import 'package:app/domain/entities/session_record.dart';
import 'package:app/domain/signal/ble_packet.dart';
import 'package:app/domain/signal/session_recorder.dart';
import 'package:app/domain/signal/signal_smoother.dart';
import 'package:app/domain/signal/validity_gate.dart';

void main() {
  group('Phase 5 Measurement Engine - ValidityGate Unit Tests', () {
    late ValidityGate gate;

    setUp(() {
      gate = ValidityGate();
    });

    test('Rejects sample when finger contact is not detected', () {
      final packet = BlePacket(
        protocolVersion: 1,
        contactDetected: false,
        motionSuspected: false,
        rawBpm: 74.0,
        quality: 90,
        deviceTimestampMs: 1000,
        sequenceNumber: 1,
        receivedAt: DateTime.now(),
      );

      final result = gate.evaluate(packet);
      expect(result.isValid, isFalse);
      expect(result.rejectReason, RejectReason.noContact);
    });

    test('Rejects BPM outside valid range (30 to 220)', () {
      final lowPacket = BlePacket(
        protocolVersion: 1,
        contactDetected: true,
        motionSuspected: false,
        rawBpm: 25.0,
        quality: 90,
        deviceTimestampMs: 1000,
        sequenceNumber: 1,
        receivedAt: DateTime.now(),
      );
      expect(gate.evaluate(lowPacket).rejectReason, RejectReason.outOfRange);

      final highPacket = BlePacket(
        protocolVersion: 1,
        contactDetected: true,
        motionSuspected: false,
        rawBpm: 235.0,
        quality: 90,
        deviceTimestampMs: 2000,
        sequenceNumber: 2,
        receivedAt: DateTime.now(),
      );
      expect(gate.evaluate(highPacket).rejectReason, RejectReason.outOfRange);
    });

    test('Rejects sample with quality lower than 60 threshold', () {
      final packet = BlePacket(
        protocolVersion: 1,
        contactDetected: true,
        motionSuspected: false,
        rawBpm: 75.0,
        quality: 45,
        deviceTimestampMs: 1000,
        sequenceNumber: 1,
        receivedAt: DateTime.now(),
      );

      final result = gate.evaluate(packet);
      expect(result.isValid, isFalse);
      expect(result.rejectReason, RejectReason.lowQuality);
    });

    test('Rejects step jumps exceeding 25 BPM in consecutive seconds', () {
      final t0 = DateTime.now();
      final p1 = BlePacket(
        protocolVersion: 1,
        contactDetected: true,
        motionSuspected: false,
        rawBpm: 70.0,
        quality: 90,
        deviceTimestampMs: 1000,
        sequenceNumber: 1,
        receivedAt: t0,
      );
      expect(gate.evaluate(p1).isValid, isTrue);

      final p2 = BlePacket(
        protocolVersion: 1,
        contactDetected: true,
        motionSuspected: false,
        rawBpm: 105.0, // jump = 35 BPM > 25 limit
        quality: 90,
        deviceTimestampMs: 2000,
        sequenceNumber: 2,
        receivedAt: t0.add(const Duration(seconds: 1)),
      );
      final r2 = gate.evaluate(p2);
      expect(r2.isValid, isFalse);
      expect(r2.rejectReason, RejectReason.excessiveJump);
    });
  });

  group('Phase 5 Measurement Engine - SignalSmoother Unit Tests', () {
    late SignalSmoother smoother;

    setUp(() {
      smoother = SignalSmoother();
    });

    test(
      'Warmup requires 5 consecutive valid samples before displaying BPM',
      () {
        final t0 = DateTime.now();

        for (int i = 0; i < 4; i++) {
          final sample = GatedSample(
            packet: BlePacket(
              protocolVersion: 1,
              contactDetected: true,
              motionSuspected: false,
              rawBpm: 72.0,
              quality: 90,
              deviceTimestampMs: i * 1000,
              sequenceNumber: i,
              receivedAt: t0.add(Duration(seconds: i)),
            ),
            isValid: true,
            rejectReason: RejectReason.none,
            bpm: 72.0,
          );

          final out = smoother.process(sample, t0.add(Duration(seconds: i)));
          expect(out.isWarmingUp, isTrue);
          expect(out.displayBpm, isNull);
        }

        // 5th sample
        final sample5 = GatedSample(
          packet: BlePacket(
            protocolVersion: 1,
            contactDetected: true,
            motionSuspected: false,
            rawBpm: 74.0,
            quality: 90,
            deviceTimestampMs: 4000,
            sequenceNumber: 4,
            receivedAt: t0.add(const Duration(seconds: 4)),
          ),
          isValid: true,
          rejectReason: RejectReason.none,
          bpm: 74.0,
        );

        final out5 = smoother.process(
          sample5,
          t0.add(const Duration(seconds: 4)),
        );
        expect(out5.isWarmingUp, isFalse);
        expect(out5.displayBpm, isNotNull);
      },
    );

    test('Hides display BPM after 3 seconds without valid sample', () {
      final t0 = DateTime.now();

      // Send 5 valid samples
      for (int i = 0; i < 5; i++) {
        smoother.process(
          GatedSample(
            packet: BlePacket(
              protocolVersion: 1,
              contactDetected: true,
              motionSuspected: false,
              rawBpm: 72.0,
              quality: 90,
              deviceTimestampMs: i * 1000,
              sequenceNumber: i,
              receivedAt: t0.add(Duration(seconds: i)),
            ),
            isValid: true,
            rejectReason: RejectReason.none,
            bpm: 72.0,
          ),
          t0.add(Duration(seconds: i)),
        );
      }

      // Check after 3.5 seconds
      final staleSample = GatedSample(
        packet: BlePacket(
          protocolVersion: 1,
          contactDetected: false,
          motionSuspected: false,
          rawBpm: null,
          quality: 0,
          deviceTimestampMs: 8000,
          sequenceNumber: 8,
          receivedAt: t0.add(const Duration(milliseconds: 8000)),
        ),
        isValid: false,
        rejectReason: RejectReason.noContact,
      );

      final staleOut = smoother.process(
        staleSample,
        t0.add(const Duration(milliseconds: 8000)),
      );
      expect(staleOut.isStale, isTrue);
      expect(staleOut.displayBpm, isNull);
    });
  });

  group('Phase 5 Measurement Engine - SessionRecorder State Machine Tests', () {
    test('Transitions from preparing to measuring and completes session', () {
      final recorder = SessionRecorder(
        sessionId: 'test-session-rec',
        sessionType: SessionType.rest,
        targetDuration: const Duration(seconds: 5),
      );

      expect(recorder.state, SessionRecorderState.preparing);
      recorder.start();
      expect(recorder.state, SessionRecorderState.waitingForSignal);

      final t0 = DateTime.now();
      // Feed 5 valid packets to satisfy warmup
      for (int i = 0; i < 5; i++) {
        recorder.processPacket(
          BlePacket(
            protocolVersion: 1,
            contactDetected: true,
            motionSuspected: false,
            rawBpm: 74.0 + (i % 2),
            quality: 90,
            deviceTimestampMs: i * 1000,
            sequenceNumber: i,
            receivedAt: t0.add(Duration(seconds: i)),
          ),
        );
      }

      // Should have transitioned to measuring or completed
      expect(
        recorder.state == SessionRecorderState.measuring ||
            recorder.state == SessionRecorderState.completed,
        isTrue,
      );

      recorder.stopAndSave();
      expect(recorder.state, SessionRecorderState.completed);
      expect(recorder.finalStats, isNotNull);
      expect(recorder.finalStats!.validSampleCount, 5);
      expect(recorder.finalStats!.meanHr, inInclusiveRange(74.0, 75.0));
      expect(recorder.finalStats!.startHr, inInclusiveRange(74.0, 75.0));
    });

    test('Correctly computes recovery drop for resting session', () {
      final recorder = SessionRecorder(
        sessionId: 'test-rest-drop',
        sessionType: SessionType.rest,
      );
      recorder.start();

      final t0 = DateTime.now();
      // Start with 80 BPM, end with 70 BPM
      for (int i = 0; i < 15; i++) {
        final bpm = i < 8 ? 80.0 : 70.0;
        recorder.processPacket(
          BlePacket(
            protocolVersion: 1,
            contactDetected: true,
            motionSuspected: false,
            rawBpm: bpm,
            quality: 90,
            deviceTimestampMs: i * 1000,
            sequenceNumber: i,
            receivedAt: t0.add(Duration(seconds: i)),
          ),
        );
      }

      final stats = recorder.computeStats();
      expect(stats.startHr, 80.0);
      expect(stats.endHr, 70.0);
      expect(stats.recoveryDrop, 10.0); // start_hr - end_hr
    });
  });
}
