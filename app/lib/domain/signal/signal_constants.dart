/// Signal processing and validity gating named constants.
class SignalConstants {
  const SignalConstants._();

  /// Minimum physiologically plausible heart rate.
  static const double minValidBpm = 30.0;

  /// Maximum physiologically plausible heart rate.
  static const double maxValidBpm = 220.0;

  /// Minimum MAX30102 signal quality score (0–100) required to pass gate.
  static const int minQualityThreshold = 60;

  /// Maximum allowed BPM jump between consecutive seconds before rejection.
  static const double maxStepJumpBpm = 25.0;

  /// Window size for the median filter to suppress transient spikes.
  static const int medianFilterWindowSize = 5;

  /// Number of consecutive valid samples required before displaying BPM in UI.
  static const int warmupConsecutiveValidSamples = 5;

  /// Maximum allowed duration without a valid sample before hiding live BPM.
  static const Duration hideDelay = Duration(seconds: 3);

  /// Minimum session duration required for statistical / AI feature extraction.
  static const Duration minAnalyzableSessionDuration = Duration(seconds: 30);

  /// Post-activity recovery drop analysis duration requirement (start_hr vs 55-65s window).
  static const Duration minRecoveryAnalysisDuration = Duration(seconds: 70);
}
