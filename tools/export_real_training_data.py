"""
PulsePatch Lite — Export Real Training Data from Phone Database
Extracts all recorded sessions and stats from the phone's Drift SQLite database
into ml/data/phone_recorded_sessions.csv and merges with synthetic baseline in ml/data/combined_training_data.csv.
"""
import sqlite3
import pandas as pd
from datetime import datetime

db_path = "docs/field_test/raw/pulse_patch_phone_clean.db"
conn = sqlite3.connect(db_path)
cur = conn.cursor()

query = """
SELECT 
    s.id AS session_id,
    s.type AS session_type,
    s.source AS source,
    s.quality_summary AS quality,
    s.started_at,
    st.mean_hr,
    st.std_hr,
    st.start_hr,
    st.end_hr,
    st.recovery_drop,
    st.valid_sample_count
FROM sessions s
JOIN session_stats st ON s.id = st.session_id
ORDER BY s.started_at ASC
"""

cur.execute(query)
rows = cur.fetchall()
conn.close()

records = []
for r in rows:
    sess_id, stype, source, quality, started_at_raw, mean_hr, std_hr, start_hr, end_hr, rec_drop, count = r
    # Handle timestamp: if integer ms or ISO string
    if isinstance(started_at_raw, int) or (isinstance(started_at_raw, str) and started_at_raw.isdigit()):
        dt = datetime.fromtimestamp(int(started_at_raw) / 1000.0)
        created_at_iso = dt.isoformat()
    else:
        created_at_iso = str(started_at_raw)
    
    # Educational label:
    # 0 = Typical pattern, 1 = Different pattern
    if "post" in stype.lower() or "activity" in stype.lower():
        is_typical = rec_drop >= 12.0
    else:
        is_typical = (45.0 <= mean_hr <= 95.0) and (std_hr <= 8.0)
    lbl = 0 if is_typical else 1
    lbl_name = "Typical pattern" if is_typical else "Different pattern"

    records.append({
        "subject_id": "VOL_REAL_01",
        "subject_code": "VOL_REAL_01",
        "session_id": sess_id,
        "session_type": stype,
        "source": source,
        "mean_hr": round(mean_hr, 2),
        "std_hr": round(std_hr, 2),
        "start_hr": round(start_hr, 1),
        "end_hr": round(end_hr, 1),
        "recovery_drop": round(rec_drop, 1),
        "valid_sample_count": count,
        "quality": quality,
        "label": lbl,
        "label_name": lbl_name,
        "created_at": created_at_iso,
    })

df_real = pd.DataFrame(records)
out_csv = "ml/data/phone_recorded_sessions.csv"
df_real.to_csv(out_csv, index=False)
print(f"Exported {len(df_real)} real sessions from {db_path} to {out_csv}:")
print(df_real[["session_id", "session_type", "mean_hr", "recovery_drop", "valid_sample_count"]])

# Now update combined_training_data.csv
synthetic_cohort_csv = "ml/data/training_cohort.csv"
if pd.io.common.file_exists(synthetic_cohort_csv):
    df_synthetic = pd.read_csv(synthetic_cohort_csv)
    # Concatenate synthetic cohort with real sessions
    df_combined = pd.concat([df_synthetic, df_real], ignore_index=True)
    combined_csv = "ml/data/combined_training_data.csv"
    df_combined.to_csv(combined_csv, index=False)
    print(f"\nCreated {combined_csv} with {len(df_synthetic)} synthetic + {len(df_real)} real = {len(df_combined)} total sessions.")
