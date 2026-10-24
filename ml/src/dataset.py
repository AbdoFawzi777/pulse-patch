"""
PulsePatch Lite — Dataset Pipeline & Synthetic Cohort Protocol
Conforming to Master Build Plan Section 7.1 and 7.2.

Features:
  - mean_hr
  - std_hr
  - start_hr
  - end_hr
  - recovery_drop
Metadata:
  - subject_id (anonymous volunteer code)
  - session_id
  - session_type (rest / post_activity)
  - quality_mean
  - source ('synthetic' or 'device' or 'public')
  - label (0: Typical pattern, 1: Different pattern)
"""

import os
import csv
import random
import math
from typing import List, Dict, Any, Tuple


def generate_synthetic_cohort(
    num_volunteers: int = 10,
    sessions_per_volunteer: int = 16,
    seed: int = 42
) -> List[Dict[str, Any]]:
    """
    Generates a reproducible volunteer cohort dataset following the
    educational resting and post-activity recovery protocol.
    Every row is explicitly labeled source='synthetic'.
    """
    random.seed(seed)
    records = []

    for v_idx in range(1, num_volunteers + 1):
        subject_id = f"VOL_{v_idx:02d}"
        # Baseline resting HR for this volunteer (between 58 and 82 BPM)
        v_resting_baseline = random.uniform(60.0, 78.0)
        v_hrv_baseline = random.uniform(2.5, 4.8)

        # 8 resting sessions, 8 post-activity sessions per volunteer
        half_sessions = sessions_per_volunteer // 2

        # 1. Resting Sessions (seated rest, 2-3 mins)
        for s_idx in range(1, half_sessions + 1):
            session_id = f"{subject_id}_REST_{s_idx:02d}"
            
            # 85% typical resting sessions, 15% atypical (e.g. caffeine, stress, anomalous fluctuation)
            is_atypical = (random.random() < 0.15)
            
            if not is_atypical:
                # Typical resting: steady HR near baseline, low variance, negligible recovery drop
                mean_hr = v_resting_baseline + random.gauss(0.0, 2.0)
                std_hr = v_hrv_baseline + random.gauss(0.0, 0.5)
                start_hr = mean_hr + random.gauss(0.0, 1.5)
                end_hr = mean_hr + random.gauss(0.0, 1.5)
                recovery_drop = start_hr - end_hr
                label = 0 # Typical pattern
            else:
                # Atypical resting: elevated rate or high fluctuation
                mean_hr = v_resting_baseline + random.uniform(14.0, 25.0)
                std_hr = v_hrv_baseline * random.uniform(2.2, 3.5)
                start_hr = mean_hr + random.gauss(2.0, 3.0)
                end_hr = mean_hr - random.gauss(1.0, 2.0)
                recovery_drop = start_hr - end_hr
                label = 1 # Different pattern

            quality = random.uniform(75.0, 96.0)

            records.append({
                "subject_id": subject_id,
                "session_id": session_id,
                "session_type": "rest",
                "mean_hr": round(mean_hr, 2),
                "std_hr": round(std_hr, 2),
                "start_hr": round(start_hr, 2),
                "end_hr": round(end_hr, 2),
                "recovery_drop": round(recovery_drop, 2),
                "quality_mean": round(quality, 1),
                "source": "synthetic",
                "label": label,
                "label_name": "Typical pattern" if label == 0 else "Different pattern"
            })

        # 2. Post-Activity Sessions (1 min step test / brisk stairs + 2 min seated recovery)
        for s_idx in range(1, half_sessions + 1):
            session_id = f"{subject_id}_POST_{s_idx:02d}"

            # Post-activity exercise elevates starting HR
            elevated_start = v_resting_baseline + random.uniform(42.0, 68.0) # 105 - 146 BPM
            
            # 80% typical physiological recovery, 20% blunted / atypical recovery
            is_atypical = (random.random() < 0.20)

            if not is_atypical:
                # Typical autonomic recovery: substantial drop in 60s (14 to 36 BPM drop)
                recovery_drop = random.uniform(16.0, 34.0)
                end_hr = elevated_start - recovery_drop - random.uniform(4.0, 10.0)
                mean_hr = (elevated_start + end_hr) / 2.0 + random.gauss(0.0, 3.0)
                std_hr = random.uniform(8.0, 15.0) # Elevated variance during dynamic decline
                label = 0 # Typical pattern
            else:
                # Different pattern: delayed / blunted drop (< 8 BPM drop)
                recovery_drop = random.uniform(1.0, 7.5)
                end_hr = elevated_start - recovery_drop - random.uniform(0.0, 3.0)
                mean_hr = (elevated_start + end_hr) / 2.0 + random.gauss(0.0, 2.0)
                std_hr = random.uniform(3.0, 7.0)
                label = 1 # Different pattern

            start_hr = elevated_start
            quality = random.uniform(70.0, 92.0)

            records.append({
                "subject_id": subject_id,
                "session_id": session_id,
                "session_type": "post_activity",
                "mean_hr": round(mean_hr, 2),
                "std_hr": round(std_hr, 2),
                "start_hr": round(start_hr, 2),
                "end_hr": round(end_hr, 2),
                "recovery_drop": round(recovery_drop, 2),
                "quality_mean": round(quality, 1),
                "source": "synthetic",
                "label": label,
                "label_name": "Typical pattern" if label == 0 else "Different pattern"
            })

    return records


def save_dataset_csv(records: List[Dict[str, Any]], filepath: str):
    """Saves records to CSV."""
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    fields = [
        "subject_id", "session_id", "session_type",
        "mean_hr", "std_hr", "start_hr", "end_hr", "recovery_drop",
        "quality_mean", "source", "label", "label_name"
    ]
    with open(filepath, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        writer.writerows(records)
    print(f"Saved {len(records)} records to {filepath}")


def load_dataset_csv(filepath: str) -> List[Dict[str, Any]]:
    """Loads records from CSV."""
    records = []
    with open(filepath, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for r in reader:
            records.append({
                "subject_id": r["subject_id"],
                "session_id": r["session_id"],
                "session_type": r["session_type"],
                "mean_hr": float(r["mean_hr"]),
                "std_hr": float(r["std_hr"]),
                "start_hr": float(r["start_hr"]),
                "end_hr": float(r["end_hr"]),
                "recovery_drop": float(r["recovery_drop"]),
                "quality_mean": float(r["quality_mean"]),
                "source": r["source"],
                "label": int(r["label"]),
                "label_name": r["label_name"]
            })
    return records


if __name__ == "__main__":
    out_path = "ml/data/training_cohort.csv"
    cohort = generate_synthetic_cohort(num_volunteers=10, sessions_per_volunteer=16)
    save_dataset_csv(cohort, out_path)
    print(f"Generated cohort summary:")
    print(f"  Total volunteers: 10 (VOL_01 - VOL_10)")
    print(f"  Total sessions: {len(cohort)}")
    typical_count = sum(1 for r in cohort if r["label"] == 0)
    diff_count = sum(1 for r in cohort if r["label"] == 1)
    print(f"  Class balance: {typical_count} Typical ({typical_count/len(cohort)*100:.1f}%), {diff_count} Different ({diff_count/len(cohort)*100:.1f}%)")
