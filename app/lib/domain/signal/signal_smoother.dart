import 'signal_constants.dart';
import 'validity_gate.dart';

class SmoothedOutput {
  const SmoothedOutput({
    this.displayBpm,
    this.smoothedBpm,
    required this.consecutiveValidSamples,
    required this.isWarmingUp,
    required this.isStale,
  });

  final int? displayBpm;
  final double? smoothedBpm;
  final int consecutiveValidSamples;
  final bool isWarmingUp;
  final bool isStale;
}

/// Pure Dart signal smoother implementing 5-sample median filter, warm-up, and hide gating.
class SignalSmoother {
  SignalSmoother({
    this.windowSize = SignalConstants.medianFilterWindowSize,
    this.requiredWarmupSamples = SignalConstants.warmupConsecutiveValidSamples,
    this.hideDelay = SignalConstants.hideDelay,
  });

  final int windowSize;
  final int requiredWarmupSamples;
  final Duration hideDelay;

  final List<double> _window = [];
  int _consecutiveValidSamples = 0;
  DateTime? _lastValidSampleTime;

  void reset() {
    _window.clear();
    _consecutiveValidSamples = 0;
    _lastValidSampleTime = null;
  }

  SmoothedOutput process(GatedSample sample, DateTime now) {
    if (sample.isValid && sample.bpm != null) {
      _consecutiveValidSamples++;
      _lastValidSampleTime = now;

      _window.add(sample.bpm!);
      if (_window.length > windowSize) {
        _window.removeAt(0);
      }
    } else {
      _consecutiveValidSamples = 0;
    }

    final isStale =
        _lastValidSampleTime == null ||
        now.difference(_lastValidSampleTime!) > hideDelay;

    final isWarmingUp = _consecutiveValidSamples < requiredWarmupSamples;

    if (isStale || isWarmingUp || _window.isEmpty) {
      return SmoothedOutput(
        displayBpm: null,
        smoothedBpm: null,
        consecutiveValidSamples: _consecutiveValidSamples,
        isWarmingUp: isWarmingUp,
        isStale: isStale,
      );
    }

    // Compute median of sliding window
    final sorted = List<double>.from(_window)..sort();
    final median = sorted[sorted.length ~/ 2];

    return SmoothedOutput(
      displayBpm: median.round(),
      smoothedBpm: median,
      consecutiveValidSamples: _consecutiveValidSamples,
      isWarmingUp: false,
      isStale: false,
    );
  }
}
