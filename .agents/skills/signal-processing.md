# Signal Processing & Statistics Playbook

**Role:** Signal and Statistics Engineer  
**Objective:** Pure Dart and Python implementation of validity gating, signal smoothing, feature extraction, and recovery analysis, validated by shared test vectors.

## Validity Gating Rules (Phase 5)
1. **Range Validation:** Accept BPM between 30.0 and 220.0 only.
2. **Quality Gate:** MAX30102 signal quality score $\ge 60$ (or agreed threshold).
3. **Jump Limit:** Reject step jumps $> 25\text{ BPM}$ between consecutive seconds.
4. **Smoothing:** 5-sample median filter to remove transient optical spikes.
5. **Warm-up Gate:** Require 5 consecutive valid samples before presenting live BPM to the UI.
6. **Stale/Drop Gate:** If no valid sample arrives within 3.0 seconds, blank/hide the live number.

## Shared Feature Definitions (Dart & Python)
- `mean_hr`: Sample mean of all valid BPM samples.
- `std_hr`: Sample standard deviation of valid BPM samples ($N-1$ degrees of freedom).
- `start_hr`: Median BPM in first 10 seconds of valid data.
- `end_hr`: Median BPM in final 10 seconds of valid data.
- `recovery_drop`:
  - For post-activity sessions ($\ge 70\text{ s}$ total duration): Median of first 10 s minus median of window $[55\text{ s}, 65\text{ s}]$.
  - For resting sessions: `start_hr - end_hr`.
  - If insufficient valid samples in window: `null`, labeled `Insufficient data for AI`.
- `variability_est`: Standard deviation of successive differences (SDSD/RMSSD) of detected pulse intervals (in milliseconds).

## Parity Contract
- All algorithms must be implemented in both Dart (`app/lib/domain/signal/`) and Python (`ml/src/features.py`).
- Shared golden test vectors (`test_vectors.json`) executed in both test suites; maximum allowed tolerance: $10^{-5}$.
