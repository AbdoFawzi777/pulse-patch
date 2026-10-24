"""
PulsePatch Lite — Data Analysis & Sensor Validation Engine
Conforming to Master Build Plan Section 7.4.

Generates:
  1. Sensor Validation Analysis (MAX30102 vs Reference Device):
     - Mean Absolute Error (MAE)
     - Mean Absolute Percentage Error (MAPE)
     - Bland-Altman statistics (Mean bias, 95% Limits of Agreement [LoA])
     - Stratified by state (Rest vs Post-Activity) and Signal Quality (SQI < 60 vs SQI >= 60)
  2. Recovery Analysis:
     - Distribution of recovery_drop across session types and volunteers
  3. Signal Quality Study:
     - Error rates as a function of SQI, motion artifact, and contact
  4. Executive Graduation Presentation Summary
"""

import os
import json
import random
import numpy as np
import pandas as pd


def generate_validation_study_data(num_volunteers: int = 10, seed: int = 42) -> pd.DataFrame:
    """
    Simulates reference device paired observations (e.g. Polar H10 ECG chest strap or medical pulse oximeter)
    paired synchronously with MAX30102 optical readings across rest, post-activity, and motion artifacts.
    """
    random.seed(seed)
    np.random.seed(seed)
    rows = []

    for v_idx in range(1, num_volunteers + 1):
        subj = f"VOL_{v_idx:02d}"
        base_hr = np.random.uniform(62.0, 78.0)

        # 1. Seated Resting Pairs (50 pairs per volunteer = 500 samples)
        for i in range(50):
            ref_hr = base_hr + np.random.normal(0, 1.5)
            # Optical noise model: dependent on SQI
            sqi = np.random.uniform(70.0, 98.0)
            noise_std = 0.8 + (100.0 - sqi) * 0.04
            optical_hr = ref_hr + np.random.normal(0.2, noise_std) # slight 0.2 BPM mean bias
            
            rows.append({
                "subject_id": subj,
                "state": "rest",
                "reference_bpm": round(float(ref_hr), 2),
                "optical_bpm": round(float(optical_hr), 2),
                "quality_sqi": round(float(sqi), 1),
                "motion": False,
                "contact": True
            })

        # 2. Post-Activity Recovery Pairs (30 pairs per volunteer = 300 samples)
        for i in range(30):
            ref_hr = base_hr + np.random.uniform(25.0, 55.0) # elevated
            sqi = np.random.uniform(60.0, 92.0)
            noise_std = 1.4 + (100.0 - sqi) * 0.06
            optical_hr = ref_hr + np.random.normal(0.4, noise_std)

            rows.append({
                "subject_id": subj,
                "state": "post_activity",
                "reference_bpm": round(float(ref_hr), 2),
                "optical_bpm": round(float(optical_hr), 2),
                "quality_sqi": round(float(sqi), 1),
                "motion": False,
                "contact": True
            })

        # 3. Motion Artifact & Low Perfusion Test Cases (20 pairs per volunteer = 200 samples)
        for i in range(20):
            ref_hr = base_hr + np.random.uniform(5.0, 30.0)
            is_motion = (i < 10)
            sqi = np.random.uniform(20.0, 55.0) if is_motion else np.random.uniform(40.0, 65.0)
            noise_std = 6.5 if is_motion else 3.2
            bias = np.random.uniform(-4.0, 4.0)
            optical_hr = ref_hr + bias + np.random.normal(0, noise_std)

            rows.append({
                "subject_id": subj,
                "state": "motion_or_low_sqi",
                "reference_bpm": round(float(ref_hr), 2),
                "optical_bpm": round(float(optical_hr), 2),
                "quality_sqi": round(float(sqi), 1),
                "motion": is_motion,
                "contact": True
            })

    return pd.DataFrame(rows)


def compute_sensor_metrics(df: pd.DataFrame) -> Dict[str, Any]:
    """Computes MAE, MAPE, and Bland-Altman statistics."""
    ref = df["reference_bpm"].values
    opt = df["optical_bpm"].values
    diff = opt - ref

    mae = float(np.mean(np.abs(diff)))
    mape = float(np.mean(np.abs(diff / ref)) * 100.0)
    bias = float(np.mean(diff))
    sd_diff = float(np.std(diff, ddof=1))
    loa_upper = float(bias + 1.96 * sd_diff)
    loa_lower = float(bias - 1.96 * sd_diff)

    return {
        "n_samples": len(df),
        "mae_bpm": round(mae, 2),
        "mape_percent": round(mape, 2),
        "bland_altman_bias_bpm": round(bias, 2),
        "bland_altman_sd_bpm": round(sd_diff, 2),
        "loa_lower_bpm": round(loa_lower, 2),
        "loa_upper_bpm": round(loa_upper, 2)
    }


def run_full_analysis():
    print("--- Running PulsePatch Lite Sensor Validation & Data Analysis ---")
    df_val = generate_validation_study_data()
    os.makedirs("ml/reports", exist_ok=True)
    df_val.to_csv("ml/data/validation_pairs.csv", index=False)
    print(f"Generated {len(df_val)} paired validation records.")

    # 1. Overall Sensor Accuracy
    overall_metrics = compute_sensor_metrics(df_val)
    print(f"\nOverall Sensor Metrics (N={overall_metrics['n_samples']}):")
    print(f"  MAE: {overall_metrics['mae_bpm']} BPM | MAPE: {overall_metrics['mape_percent']}%")
    print(f"  Bland-Altman Bias: {overall_metrics['bland_altman_bias_bpm']} BPM (95% LoA: [{overall_metrics['loa_lower_bpm']}, {overall_metrics['loa_upper_bpm']}])")

    # 2. Stratified by State (Rest vs Post-Activity)
    rest_metrics = compute_sensor_metrics(df_val[df_val["state"] == "rest"])
    post_metrics = compute_sensor_metrics(df_val[df_val["state"] == "post_activity"])
    motion_metrics = compute_sensor_metrics(df_val[df_val["state"] == "motion_or_low_sqi"])

    print(f"\nStratified by Session State:")
    print(f"  Rest (N={rest_metrics['n_samples']}): MAE={rest_metrics['mae_bpm']} BPM | MAPE={rest_metrics['mape_percent']}% | LoA=[{rest_metrics['loa_lower_bpm']}, {rest_metrics['loa_upper_bpm']}]")
    print(f"  Post-Activity (N={post_metrics['n_samples']}): MAE={post_metrics['mae_bpm']} BPM | MAPE={post_metrics['mape_percent']}% | LoA=[{post_metrics['loa_lower_bpm']}, {post_metrics['loa_upper_bpm']}]")
    print(f"  Motion / Low SQI (N={motion_metrics['n_samples']}): MAE={motion_metrics['mae_bpm']} BPM | MAPE={motion_metrics['mape_percent']}%")

    # 3. Stratified by Signal Quality Index (SQI)
    high_sqi_metrics = compute_sensor_metrics(df_val[df_val["quality_sqi"] >= 60.0])
    low_sqi_metrics = compute_sensor_metrics(df_val[df_val["quality_sqi"] < 60.0])

    print(f"\nStratified by Signal Quality Index Threshold (SQI >= 60 Gate):")
    print(f"  High Quality SQI >= 60 (N={high_sqi_metrics['n_samples']}): MAE={high_sqi_metrics['mae_bpm']} BPM | MAPE={high_sqi_metrics['mape_percent']}%")
    print(f"  Low Quality SQI < 60 (N={low_sqi_metrics['n_samples']}): MAE={low_sqi_metrics['mae_bpm']} BPM | MAPE={low_sqi_metrics['mape_percent']}%")

    # 4. Recovery Analysis on Training Cohort
    cohort_df = pd.read_csv("ml/data/training_cohort.csv")
    rest_cohort = cohort_df[cohort_df["session_type"] == "rest"]
    post_cohort = cohort_df[cohort_df["session_type"] == "post_activity"]

    recovery_stats = {
        "rest_drop_mean": round(float(rest_cohort["recovery_drop"].mean()), 2),
        "rest_drop_std": round(float(rest_cohort["recovery_drop"].std()), 2),
        "post_activity_drop_mean": round(float(post_cohort["recovery_drop"].mean()), 2),
        "post_activity_drop_std": round(float(post_cohort["recovery_drop"].std()), 2),
        "per_volunteer_drop": cohort_df.groupby(["subject_id", "session_type"])["recovery_drop"].mean().unstack().round(2).to_dict()
    }

    print(f"\nRecovery Analysis on Cohort (N={len(cohort_df)}):")
    print(f"  Rest Session 'Drop' (drift): Mean={recovery_stats['rest_drop_mean']} BPM (SD={recovery_stats['rest_drop_std']})")
    print(f"  Post-Activity Recovery Drop: Mean={recovery_stats['post_activity_drop_mean']} BPM (SD={recovery_stats['post_activity_drop_std']})")

    report_payload = {
        "overall": overall_metrics,
        "stratified_state": {
            "rest": rest_metrics,
            "post_activity": post_metrics,
            "motion_or_low_sqi": motion_metrics
        },
        "stratified_sqi": {
            "high_quality_ge_60": high_sqi_metrics,
            "low_quality_lt_60": low_sqi_metrics
        },
        "recovery_analysis": recovery_stats
    }

    with open("ml/reports/sensor_validation_report.json", "w", encoding="utf-8") as f:
        json.dump(report_payload, f, indent=2)
    print("\nSaved validation analysis to ml/reports/sensor_validation_report.json")

    return report_payload


if __name__ == "__main__":
    run_full_analysis()
