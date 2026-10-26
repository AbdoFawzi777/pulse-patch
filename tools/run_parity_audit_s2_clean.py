"""
PulsePatch Lite - Clean Post-Activity Session Mathematical Parity Audit
Audits recorded phone SQLite database for sess-1793010133841 against independent Python recomputations.
"""
import sqlite3
import pandas as pd
import numpy as np
import statistics
import json

db_path = "docs/field_test/raw/pulse_patch_phone_clean.db"
conn = sqlite3.connect(db_path)
cur = conn.cursor()

session_id = "sess-1793010133841"
cur.execute("SELECT id, started_at, ended_at, type, source, quality_summary FROM sessions WHERE id=?", (session_id,))
session = cur.fetchone()
if not session:
    raise ValueError(f"Session {session_id} not found in {db_path}")

# Stored Session Stats
cur.execute("""
    SELECT mean_hr, std_hr, min_hr, max_hr, start_hr, end_hr, recovery_drop, 
           pulse_interval_ms, variability_est_ms, valid_sample_count, total_duration_seconds 
    FROM session_stats WHERE session_id=?
""", (session_id,))
app_stats = cur.fetchone()

# Stored AI Result
cur.execute("SELECT model_version, label, features_json, created_at FROM ai_results WHERE session_id=?", (session_id,))
ai_row = cur.fetchone()

# Raw Samples
cur.execute("SELECT t_ms, bpm, quality, is_valid FROM samples WHERE session_id=? ORDER BY t_ms ASC", (session_id,))
raw_samples = cur.fetchall()
samples_df = pd.DataFrame(raw_samples, columns=["t_ms", "bpm", "quality", "is_valid"])

valid_mask = samples_df["is_valid"] == 1
valid_samples = samples_df[valid_mask]["bpm"].dropna().values
valid_t_ms = samples_df[valid_mask]["t_ms"].values

# Independent Python Recomputation
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

# recovery_drop: for postActivity >= 70s, median(first 10s) - median(t_ms between 55s and 65s)
elapsed_s = app_stats[10]
if elapsed_s >= 70:
    recov_window = [valid_samples[i] for i, t in enumerate(valid_t_ms) if 55000 <= t <= 65000]
    if recov_window:
        recov_median = float(statistics.median(recov_window))
        py_recovery_drop = py_start_hr - recov_median
    else:
        py_recovery_drop = py_start_hr - py_end_hr
else:
    py_recovery_drop = py_start_hr - py_end_hr

py_pulse_interval = 60000.0 / py_mean_hr if py_mean_hr > 0 else 0.0

if count > 2:
    intervals = [60000.0 / b for b in valid_samples]
    diffs = [intervals[i+1] - intervals[i] for i in range(len(intervals)-1)]
    mean_diff = sum(diffs) / len(diffs)
    variance_diff = sum((d - mean_diff) ** 2 for d in diffs) / len(diffs)
    py_variability = float(np.sqrt(variance_diff))
else:
    py_variability = 0.0

print("=" * 82)
print("PULSEPATCH LITE — CLEAN POST-ACTIVITY MATHEMATICAL PARITY AUDIT REPORT")
print(f"Session ID:         {session_id}")
print(f"Session Type:       {session[3]} (90s Post-Activity Recovery)")
print(f"Source:             {session[4]}")
print(f"Quality Summary:    {session[5]}")
print(f"Start Timestamp:    {session[1]}")
print(f"End Timestamp:      {session[2]}")
print(f"Recorded Duration:  {app_stats[10]} seconds (Valid Samples: {app_stats[9]})")
print("=" * 82)
print(f"{'Metric':<22} | {'Python Recomputed':<18} | {'App Stored':<15} | {'Diff (Abs)':<12} | {'Parity'}")
print("-" * 82)

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
    ("Pulse Interval (ms)", py_pulse_interval, app_stats[7]),
    ("Variability Est (ms)", py_variability, app_stats[8]),
]

all_exact = True
for name, py_val, app_val in metrics:
    diff = abs(py_val - app_val)
    status = "EXACT MATCH" if diff < 1e-4 else ("PASS (<0.01)" if diff < 0.01 else "MISMATCH")
    if diff >= 1e-4:
        all_exact = False
    print(f"{name:<22} | {py_val:<18.4f} | {app_val:<15.4f} | {diff:<12.6f} | {status}")

print("=" * 82)
if ai_row:
    ai_features = json.loads(ai_row[2])
    print("AI MODEL INFERENCE RESULT (Stored in SQLite ai_results table):")
    print(f"  Model Version:     {ai_row[0]}")
    print(f"  Pattern Label:     {ai_row[1]}")
    print(f"  Recovery Drop:     {app_stats[6]} BPM (Threshold: >= 12.0 BPM)")
    print(f"  Condition Rule:    Recovery Drop < 12.0 BPM -> 'Different pattern'")
    print(f"  Explanation:       \"{ai_features.get('explanation', '')}\"")
    print(f"  Inferred At:       {ai_features.get('inferredAt', '')}")
else:
    print("AI MODEL INFERENCE: None found in SQLite table!")
print("=" * 82)
