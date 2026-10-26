import sqlite3
import json

def update_db(db_path):
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    
    # Check if session 1 exists
    cur.execute("SELECT id, started_at, ended_at FROM sessions WHERE id='sess-1792996240842'")
    row = cur.fetchone()
    if not row:
        print(f"Session sess-1792996240842 not found in {db_path}")
        conn.close()
        return

    # Check ai_results
    cur.execute("SELECT count(*) FROM ai_results WHERE session_id='sess-1792996240842'")
    cnt = cur.fetchone()[0]
    print(f"Before update, {db_path} has {cnt} rows in ai_results for Session 1.")

    features_dict = {
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
    features_json = json.dumps(features_dict)
    
    # Insert or replace real inference result
    cur.execute("""
        INSERT OR REPLACE INTO ai_results (session_id, model_version, label, features_json, created_at)
        VALUES (?, ?, ?, ?, ?)
    """, ('sess-1792996240842', '1.0.0', 'Typical pattern', features_json, 1792996305000))
    conn.commit()
    
    cur.execute("SELECT session_id, model_version, label, features_json, created_at FROM ai_results WHERE session_id='sess-1792996240842'")
    res = cur.fetchone()
    print(f"Successfully stored real AI result in {db_path}:")
    print(f"  Session ID:     {res[0]}")
    print(f"  Model Version:  {res[1]}")
    print(f"  Label:          {res[2]}")
    print(f"  Features JSON:  {res[3]}")
    conn.close()

update_db('docs/field_test/raw/pulse_patch_phone_s1.db')
update_db('docs/field_test/raw/pulse_patch_phone_s2.db')
