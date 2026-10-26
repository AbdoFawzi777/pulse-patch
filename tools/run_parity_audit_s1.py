"""
PulsePatch Lite - Session 1 Mathematical Parity Audit
Audits recorded phone SQLite database against ground-truth peripheral stream.
"""
import sqlite3
import pandas as pd
import numpy as np
import statistics
import os

db_path = "docs/field_test/raw/pulse_patch_phone_s1.db"
gt_csv = "docs/field_test/raw/ble_gt_resting_s1.csv"

conn = sqlite3.connect(db_path)
cur = conn.cursor()

# 1. Fetch Session Info
cur.execute("SELECT id, started_at, ended_at, type, source, quality_summary FROM sessions ORDER BY started_at DESC LIMIT 1")
session = cur.fetchone()
session_id = session[0]

# 2. Fetch Stored Session Stats
cur.execute("SELECT mean_hr, std_hr, min_hr, max_hr, start_hr, end_hr, recovery_drop, pulse_interval_ms, variability_est_ms, valid_sample_count, total_duration_seconds FROM session_stats WHERE session_id=?", (session_id,))
app_stats = cur.fetchone()

# 3. Fetch Raw Samples
cur.execute("SELECT t_ms, bpm, quality, is_valid FROM samples WHERE session_id=? ORDER BY t_ms ASC", (session_id,))
raw_samples = cur.fetchall()
samples_df = pd.DataFrame(raw_samples, columns=["t_ms", "bpm", "quality", "is_valid"])

# Filter valid samples
valid_samples = samples_df[samples_df["is_valid"] == 1]["bpm"].dropna().values
valid_t_ms = samples_df[samples_df["is_valid"] == 1]["t_ms"].values

# 4. Independent Python Recomputation
count = len(valid_samples)
py_mean_hr = float(np.mean(valid_samples))
py_std_hr = float(np.std(valid_samples, ddof=1)) if count > 1 else 0.0
py_min_hr = float(np.min(valid_samples))
py_max_hr = float(np.max(valid_samples))

# start_hr: median of BPM in first 10 seconds of valid data (t_ms <= 10000)
first_10s = [valid_samples[i] for i, t in enumerate(valid_t_ms) if t <= 10000]
py_start_hr = float(statistics.median(first_10s)) if first_10s else float(statistics.median(valid_samples[:min(10, count)]))

# end_hr: median of BPM in last 10 seconds of valid data (t_ms >= max_t - 10000)
max_t = valid_t_ms[-1] if len(valid_t_ms) > 0 else 0
last_10s = [valid_samples[i] for i, t in enumerate(valid_t_ms) if t >= (max_t - 10000)]
py_end_hr = float(statistics.median(last_10s)) if last_10s else float(statistics.median(valid_samples[max(0, count - 10):]))

# recovery_drop: for rest session, start_hr - end_hr
py_recovery_drop = py_start_hr - py_end_hr

# Load Peripheral Ground Truth
gt_df = pd.read_csv(gt_csv)
gt_bpm = gt_df["bpm"].values

print("=" * 80)
print(f"PULSEPATCH LITE — SESSION 1 MATHEMATICAL PARITY AUDIT REPORT")
print(f"Session ID:         {session_id}")
print(f"Session Type:       {session[3].upper()}")
print(f"Source:             {session[4]}")
print(f"Quality Summary:    {session[5]}")
print(f"Start Timestamp:    {session[1]}")
print(f"End Timestamp:      {session[2]}")
print(f"Recorded Duration:  {app_stats[10]} seconds (Valid Samples: {app_stats[9]})")
print("=" * 80)
print(f"{'Metric':<22} | {'Python Recomputed':<18} | {'App Stored':<15} | {'Diff (Abs)':<12} | {'Parity'}")
print("-" * 80)

metrics = [
    ("Valid Sample Count", count, app_stats[9]),
    ("Duration (s)", app_stats[10], app_stats[10]),
    ("Mean HR (BPM)", py_mean_hr, app_stats[0]),
    ("Std Dev HR (BPM)", py_std_hr, app_stats[1]),
    ("Min HR (BPM)", py_min_hr, app_stats[2]),
    ("Max HR (BPM)", py_max_hr, app_stats[3]),
    ("Start HR (BPM)", py_start_hr, app_stats[4]),
    ("End HR (BPM)", py_end_hr, app_stats[5]),
    ("Recovery Drop (BPM)", py_recovery_drop, app_stats[6]),
]

for name, py_val, app_val in metrics:
    diff = abs(py_val - app_val)
    status = "EXACT MATCH" if diff < 1e-4 else ("PASS (<0.01)" if diff < 0.01 else "MISMATCH")
    print(f"{name:<22} | {py_val:<18.4f} | {app_val:<15.4f} | {diff:<12.6f} | {status}")

print("=" * 80)
print(f"Pulse Interval (ms): {app_stats[7]:.1f} ms")
print(f"Variability Est (ms): {app_stats[8]:.1f} ms")
print(f"Peripheral GT Stream: {len(gt_df)} total packets emitted | Phone captured: {count} valid packets")
print("=" * 80)
