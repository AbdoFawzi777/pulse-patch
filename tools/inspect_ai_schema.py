import sqlite3
import json
from datetime import datetime

conn = sqlite3.connect('docs/field_test/raw/pulse_patch_phone_s1.db')
cur = conn.cursor()
cur.execute("SELECT sql FROM sqlite_master WHERE name='ai_results'")
schema = cur.fetchone()[0]
print("ai_results schema:")
print(schema)

# Re-run inference with exact numbers from Session 1
sessionId = 'sess-1792996240842'
modelVersion = '1.0.0'
label = 'Typical pattern'
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
featuresJson = json.dumps(features_dict)
createdAt = 1792996305000  # Unix timestamp ms or ISO string depending on schema

print("\nFeatures JSON to insert:")
print(featuresJson)
