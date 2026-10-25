import 'dart:async';
import 'dart:math' as math;
import '../entities/pulse_sample.dart';
import '../entities/session_record.dart';
import '../entities/session_stats_record.dart';
import 'ble_packet.dart';
import 'signal_smoother.dart';
import 'validity_gate.dart';

enum SessionRecorderState {
  preparing,
  waitingForSignal,
  measuring,
  paused,
  completed,
  discarded,
}

class RecorderSnapshot {
  const RecorderSnapshot({
    required this.state,
    required this.sessionType,
    required this.targetDuration,
    required this.elapsed,
    this.currentDisplayBpm,
    this.currentQuality = 0,
    required this.isContactDetected,
    required this.recordedSampleCount,
    required this.validSampleCount,
    this.finalStats,
  });

  final SessionRecorderState state;
  final SessionType sessionType;
  final Duration targetDuration;
  final Duration elapsed;
  final int? currentDisplayBpm;
  final int currentQuality;
  final bool isContactDetected;
  final int recordedSampleCount;
  final int validSampleCount;
  final SessionStatsRecord? finalStats;

  double get progress {
    if (targetDuration.inMilliseconds == 0) return 0.0;
    return (elapsed.inMilliseconds / targetDuration.inMilliseconds).clamp(
      0.0,
      1.0,
    );
  }
}

/// Pure Dart session recorder managing the complete measurement pipeline and state machine.
class SessionRecorder {
  SessionRecorder({
    required this.sessionId,
    this.sessionType = SessionType.rest,
    this.targetDuration = const Duration(seconds: 60),
    this.source = SessionSource.simulator,
    this.appVersion = '1.0.0',
    ValidityGate? gate,
    SignalSmoother? smoother,
  }) : _gate = gate ?? ValidityGate(),
       _smoother = smoother ?? SignalSmoother();

  final String sessionId;
  final SessionType sessionType;
  final Duration targetDuration;
  final SessionSource source;
  final String appVersion;

  final ValidityGate _gate;
  final SignalSmoother _smoother;

  final List<PulseSample> _samples = [];
  final _snapshotController = StreamController<RecorderSnapshot>.broadcast();

  SessionRecorderState _state = SessionRecorderState.preparing;
  DateTime? _startedAt;
  DateTime? _endedAt;
  Duration _elapsed = Duration.zero;
  DateTime? _lastTickTime;
  int? _currentDisplayBpm;
  int _currentQuality = 0;
  bool _isContactDetected = false;
  SessionStatsRecord? _finalStats;

  Stream<RecorderSnapshot> get snapshotStream => _snapshotController.stream;
  SessionRecorderState get state => _state;
  RecorderSnapshot get currentSnapshot => _buildSnapshot();
  List<PulseSample> get samples => List.unmodifiable(_samples);
  DateTime? get startedAt => _startedAt;
  DateTime? get endedAt => _endedAt;
  SessionStatsRecord? get finalStats => _finalStats;

  void start() {
    if (_state != SessionRecorderState.preparing) return;
    _startedAt = DateTime.now();
    _lastTickTime = _startedAt;
    _state = SessionRecorderState.waitingForSignal;
    _gate.reset();
    _smoother.reset();
    _notify();
  }

  void pause() {
    if (_state == SessionRecorderState.measuring) {
      _state = SessionRecorderState.paused;
      _notify();
    }
  }

  void resume() {
    if (_state == SessionRecorderState.paused) {
      _lastTickTime = DateTime.now();
      _state = SessionRecorderState.measuring;
      _notify();
    }
  }

  void stopAndSave() {
    if (_state == SessionRecorderState.measuring ||
        _state == SessionRecorderState.paused ||
        _state == SessionRecorderState.waitingForSignal) {
      _completeSession();
    }
  }

  void discard() {
    _state = SessionRecorderState.discarded;
    _notify();
  }

  /// Processes an incoming raw packet through validity gate and smoother.
  void processPacket(BlePacket packet) {
    if (_state != SessionRecorderState.waitingForSignal &&
        _state != SessionRecorderState.measuring) {
      return;
    }

    final now = packet.receivedAt;
    _isContactDetected = packet.contactDetected;
    _currentQuality = packet.quality;

    final gated = _gate.evaluate(packet);
    final smoothed = _smoother.process(gated, now);
    _currentDisplayBpm = smoothed.displayBpm;

    // Transition from waitingForSignal to measuring once contact and samples flow
    if (_state == SessionRecorderState.waitingForSignal &&
        packet.contactDetected &&
        smoothed.displayBpm != null) {
      _state = SessionRecorderState.measuring;
      _lastTickTime = now;
    }

    // Accumulate elapsed duration during active measuring
    if (_state == SessionRecorderState.measuring && _lastTickTime != null) {
      final delta = now.difference(_lastTickTime!);
      _elapsed += delta;
      _lastTickTime = now;
    }

    final tMs = _startedAt != null
        ? now.difference(_startedAt!).inMilliseconds
        : packet.deviceTimestampMs;

    _samples.add(
      PulseSample(
        sessionId: sessionId,
        tMs: tMs,
        bpm: gated.bpm,
        quality: packet.quality,
        isValid: gated.isValid,
        spo2: packet.spo2,
      ),
    );

    // Auto-complete if target duration reached
    if (_elapsed >= targetDuration) {
      _completeSession();
      return;
    }

    _notify();
  }

  void _completeSession() {
    _endedAt = DateTime.now();
    _state = SessionRecorderState.completed;
    _finalStats = computeStats();
    _notify();
  }

  /// Computes statistical feature vectors matching Section 6 of the Master Build Plan.
  SessionStatsRecord computeStats() {
    final validSamples = _samples
        .where((s) => s.isValid && s.bpm != null)
        .toList();

    if (validSamples.isEmpty) {
      return SessionStatsRecord(
        sessionId: sessionId,
        meanHr: 0.0,
        stdHr: 0.0,
        minHr: 0.0,
        maxHr: 0.0,
        startHr: 0.0,
        endHr: 0.0,
        recoveryDrop: null,
        pulseIntervalMs: null,
        variabilityEstMs: null,
        validSampleCount: 0,
        totalDurationSeconds: _elapsed.inSeconds,
      );
    }

    final bpms = validSamples.map((s) => s.bpm!).toList();
    final mean = bpms.reduce((a, b) => a + b) / bpms.length;

    double std = 0.0;
    if (bpms.length > 1) {
      final variance =
          bpms.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) /
          (bpms.length - 1);
      std = math.sqrt(variance);
    }

    final minBpm = bpms.reduce(math.min);
    final maxBpm = bpms.reduce(math.max);

    // start_hr: median of valid BPM in first 10 seconds of valid data
    final first10sSamples = validSamples
        .where((s) => s.tMs <= 10000)
        .map((s) => s.bpm!)
        .toList();
    final startHr = _medianOf(
      first10sSamples.isNotEmpty
          ? first10sSamples
          : bpms.sublist(0, math.min(10, bpms.length)),
    );

    // end_hr: median of valid BPM in last 10 seconds of valid data
    final maxTMs = validSamples.last.tMs;
    final last10sSamples = validSamples
        .where((s) => s.tMs >= (maxTMs - 10000))
        .map((s) => s.bpm!)
        .toList();
    final endHr = _medianOf(
      last10sSamples.isNotEmpty
          ? last10sSamples
          : bpms.sublist(math.max(0, bpms.length - 10)),
    );

    // recovery_drop:
    // For postActivity >= 70s: median of first 10s minus median of window 55s-65s
    // For rest: start_hr - end_hr
    double? recoveryDrop;
    if (sessionType == SessionType.postActivity) {
      if (_elapsed.inSeconds >= 70) {
        final recoveryWindowSamples = validSamples
            .where((s) => s.tMs >= 55000 && s.tMs <= 65000)
            .map((s) => s.bpm!)
            .toList();
        if (recoveryWindowSamples.isNotEmpty) {
          recoveryDrop = startHr - _medianOf(recoveryWindowSamples);
        }
      }
    } else {
      recoveryDrop = startHr - endHr;
    }

    final pulseInterval = mean > 0 ? (60000.0 / mean) : null;

    // Variability statistic (SDSD / RMSSD of successive pulse intervals)
    double? variabilityEst;
    if (bpms.length > 2) {
      final intervals = bpms.map((b) => 60000.0 / b).toList();
      final diffs = <double>[];
      for (int i = 0; i < intervals.length - 1; i++) {
        diffs.add(intervals[i + 1] - intervals[i]);
      }
      final meanDiff = diffs.reduce((a, b) => a + b) / diffs.length;
      final varianceDiff =
          diffs.map((d) => math.pow(d - meanDiff, 2)).reduce((a, b) => a + b) /
          diffs.length;
      variabilityEst = math.sqrt(varianceDiff);
    }

    final spo2Samples = validSamples
        .where((s) => s.spo2 != null)
        .map((s) => s.spo2!)
        .toList();
    final avgSpo2 = spo2Samples.isNotEmpty
        ? spo2Samples.reduce((a, b) => a + b) / spo2Samples.length
        : null;

    return SessionStatsRecord(
      sessionId: sessionId,
      meanHr: mean,
      stdHr: std,
      minHr: minBpm,
      maxHr: maxBpm,
      startHr: startHr,
      endHr: endHr,
      recoveryDrop: recoveryDrop,
      pulseIntervalMs: pulseInterval,
      variabilityEstMs: variabilityEst,
      validSampleCount: validSamples.length,
      totalDurationSeconds: _elapsed.inSeconds,
      avgSpo2: avgSpo2,
    );
  }

  double _medianOf(List<double> values) {
    if (values.isEmpty) return 0.0;
    final sorted = List<double>.from(values)..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length % 2 == 1) {
      return sorted[middle];
    } else {
      return (sorted[middle - 1] + sorted[middle]) / 2.0;
    }
  }

  RecorderSnapshot _buildSnapshot() {
    return RecorderSnapshot(
      state: _state,
      sessionType: sessionType,
      targetDuration: targetDuration,
      elapsed: _elapsed,
      currentDisplayBpm: _currentDisplayBpm,
      currentQuality: _currentQuality,
      isContactDetected: _isContactDetected,
      recordedSampleCount: _samples.length,
      validSampleCount: _samples.where((s) => s.isValid).length,
      finalStats: _finalStats,
    );
  }

  void _notify() {
    if (!_snapshotController.isClosed) {
      _snapshotController.add(_buildSnapshot());
    }
  }

  void dispose() {
    _snapshotController.close();
  }
}
