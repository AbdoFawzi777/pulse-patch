"""
PulsePatch Lite — Shared Feature Extractor (Python Implementation)
Strictly synchronized with app/lib/domain/signal/feature_extractor.dart
Features:
  1. mean_hr
  2. std_hr
  3. start_hr
  4. end_hr
  5. recovery_drop
Optional variability features:
  - pulse_interval_ms
  - variability_est_ms
"""

import math
from typing import List, Dict, Any, Optional, Tuple


def compute_median(values: List[float]) -> float:
    """Computes median matching Dart _computeMedian implementation."""
    if not values:
        return 0.0
    sorted_vals = sorted(values)
    n = len(sorted_vals)
    mid = n // 2
    if n % 2 == 1:
        return sorted_vals[mid]
    else:
        return (sorted_vals[mid - 1] + sorted_vals[mid]) / 2.0


def extract_features(
    samples: List[Dict[str, Any]],
    session_type: str = "rest",
    min_valid_seconds: int = 30,
    min_recovery_duration: int = 70
) -> Dict[str, Any]:
    """
    Extracts features from raw time-series samples.
    Each sample dict must contain:
      - 't_sec' (or 't_ms')
      - 'bpm' (float or None)
      - 'quality' (int 0-100)
      - 'is_valid' (bool)
    """
    # Filter valid samples
    valid_samples = [
        s for s in samples
        if s.get("is_valid", False) and s.get("bpm") is not None
    ]

    if not valid_samples:
        return {
            "is_analyzable": False,
            "valid_sample_count": 0,
            "total_duration_seconds": 0,
            "mean_hr": None,
            "std_hr": None,
            "start_hr": None,
            "end_hr": None,
            "recovery_drop": None,
            "pulse_interval_ms": None,
            "variability_est_ms": None,
        }

    # Determine timing in milliseconds
    def get_t_ms(s):
        if "t_ms" in s:
            return s["t_ms"]
        return int(s.get("t_sec", 0) * 1000)

    first_t_ms = get_t_ms(valid_samples[0])
    last_t_ms = get_t_ms(valid_samples[-1])
    total_duration = (last_t_ms - first_t_ms) // 1000

    if len(valid_samples) < min_valid_seconds:
        return {
            "is_analyzable": False,
            "valid_sample_count": len(valid_samples),
            "total_duration_seconds": total_duration,
            "mean_hr": None,
            "std_hr": None,
            "start_hr": None,
            "end_hr": None,
            "recovery_drop": None,
            "pulse_interval_ms": None,
            "variability_est_ms": None,
        }

    bpms = [float(s["bpm"]) for s in valid_samples]
    n = len(bpms)

    # 1. mean_hr
    mean_hr = sum(bpms) / n

    # 2. std_hr (sample std with N-1 degrees of freedom)
    if n > 1:
        variance = sum((x - mean_hr) ** 2 for x in bpms) / (n - 1)
        std_hr = math.sqrt(variance)
    else:
        std_hr = 0.0

    # 3. start_hr: median of valid BPM in first 10 seconds of valid data
    start_samples = [
        float(s["bpm"]) for s in valid_samples
        if get_t_ms(s) <= first_t_ms + 10000
    ]
    start_hr = compute_median(start_samples) if start_samples else mean_hr

    # 4. end_hr: median of valid BPM in last 10 seconds of valid data
    end_samples = [
        float(s["bpm"]) for s in valid_samples
        if get_t_ms(s) >= last_t_ms - 10000
    ]
    end_hr = compute_median(end_samples) if end_samples else mean_hr

    # 5. recovery_drop
    recovery_drop = None
    if session_type == "post_activity":
        if total_duration >= min_recovery_duration:
            window_samples = [
                float(s["bpm"]) for s in valid_samples
                if first_t_ms + 55000 <= get_t_ms(s) <= first_t_ms + 65000
            ]
            if len(window_samples) >= 3:
                window_60_median = compute_median(window_samples)
                recovery_drop = start_hr - window_60_median
    else:
        # For resting session: start_hr - end_hr
        recovery_drop = start_hr - end_hr

    # 6. Pulse interval and variability estimate
    intervals = [60000.0 / b for b in bpms]
    pulse_interval_ms = sum(intervals) / len(intervals)

    variability_est_ms = None
    if len(intervals) > 2:
        diffs = [intervals[i + 1] - intervals[i] for i in range(len(intervals) - 1)]
        mean_diff = sum(diffs) / len(diffs)
        diff_var = sum((d - mean_diff) ** 2 for d in diffs) / (len(diffs) - 1)
        variability_est_ms = math.sqrt(diff_var)

    return {
        "is_analyzable": True,
        "valid_sample_count": len(valid_samples),
        "total_duration_seconds": total_duration,
        "mean_hr": mean_hr,
        "std_hr": std_hr,
        "start_hr": start_hr,
        "end_hr": end_hr,
        "recovery_drop": recovery_drop,
        "pulse_interval_ms": pulse_interval_ms,
        "variability_est_ms": variability_est_ms,
    }


def verify_test_vectors(test_vectors_path: str) -> bool:
    """Verifies Python extractor parity against app/test/test_vectors.json."""
    import json
    with open(test_vectors_path, "r", encoding="utf-8") as f:
        vectors = json.load(f)

    all_passed = True
    print(f"Loaded {len(vectors)} test vectors from {test_vectors_path}...")

    for v in vectors:
        name = v["name"]
        protocol = v.get("protocol", "rest")
        samples = v["samples"]
        expected = v["expected"]

        actual = extract_features(samples, session_type="post_activity" if protocol == "exercise" else "rest")

        if actual["is_analyzable"] != expected["is_analyzable"]:
            print(f"[FAIL] {name}: is_analyzable mismatch. Expected {expected['is_analyzable']}, got {actual['is_analyzable']}")
            all_passed = False
            continue

        if not expected["is_analyzable"]:
            print(f"[PASS] {name}: Correctly flagged non-analyzable.")
            continue

        for metric in ["mean_hr", "std_hr", "start_hr", "end_hr", "recovery_drop"]:
            exp_val = expected.get(metric)
            act_val = actual.get(metric)
            if exp_val is None:
                if act_val is not None:
                    print(f"[FAIL] {name}: {metric} expected None, got {act_val}")
                    all_passed = False
            else:
                if act_val is None or abs(exp_val - act_val) > 1e-4:
                    print(f"[FAIL] {name}: {metric} mismatch. Expected {exp_val}, got {act_val}")
                    all_passed = False

        if all_passed:
            print(f"[PASS] {name}: Parity verified with Dart test vector.")

    return all_passed


if __name__ == "__main__":
    import sys
    path = "app/test/test_vectors.json" if len(sys.argv) < 2 else sys.argv[1]
    ok = verify_test_vectors(path)
    if not ok:
        sys.exit(1)
    print("All shared test vectors passed parity check successfully!")
