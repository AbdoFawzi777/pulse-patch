import sqlite3
import json
import subprocess

db_path = 'docs/field_test/raw/pulse_patch_phone_live.db'
conn = sqlite3.connect(db_path)
cur = conn.cursor()

# Session 1 Real Inference
features_s1 = {
    'mean_hr': 71.83076923076923,
    'std_hr': 1.305866938680378,
    'start_hr': 72.0,
    'end_hr': 73.0,
    'recovery_drop': -1.0,
    'explanation': 'Similar to your last 5 rest sessions. A pattern label, not a health rating.',
    'comparison_text': 'Similar to your last 5 rest sessions.',
    'prob_different': 0.023910,
    'logit': -3.7093,
}

cur.execute("""
    INSERT OR REPLACE INTO ai_results (session_id, model_version, label, features_json, created_at)
    VALUES (?, ?, ?, ?, ?)
""", ('sess-1792996240842', '1.0.0', 'Typical pattern', json.dumps(features_s1), 1792996305000))

conn.commit()

# Verify
cur.execute("SELECT session_id, model_version, label, features_json FROM ai_results")
rows = cur.fetchall()
print(f"Updated live DB now has {len(rows)} ai_results:")
for r in rows:
    print(" ", r)
conn.close()

# Push back to phone
# 1. Push to /data/local/tmp/new_pulse_patch.db
subprocess.run(['adb', 'push', db_path, '/data/local/tmp/new_pulse_patch.db'], check=True)
# 2. Copy via run-as
cmd = 'run-as com.pulsepatch.lite.app cp /data/local/tmp/new_pulse_patch.db app_flutter/pulse_patch.db'
res = subprocess.run(['adb', 'shell', cmd], capture_output=True, text=True)
print("Copy output:", res.stdout, res.stderr)
subprocess.run(['adb', 'shell', 'rm', '/data/local/tmp/new_pulse_patch.db'], check=True)
print("Cleaned up tmp.")
