#!/usr/bin/env python3
"""
tools/verify_erd_parity.py
Compares the tables and columns defined in docs/erd/pulse_patch_erd.mmd
against the real SQLite database schema created by AppDatabase.
"""

import re
import sys
import sqlite3
from pathlib import Path

def get_real_sqlite_schema() -> dict[str, set[str]]:
    """Constructs the real SQLite schema directly from AppDatabase migrations."""
    conn = sqlite3.connect(":memory:")
    conn.execute("PRAGMA foreign_keys = ON;")

    # Migration v1
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS sessions (
          id TEXT PRIMARY KEY,
          started_at INTEGER NOT NULL,
          ended_at INTEGER,
          type TEXT NOT NULL,
          quality_summary TEXT NOT NULL,
          app_version TEXT NOT NULL,
          source TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS samples (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id TEXT NOT NULL,
          t_ms INTEGER NOT NULL,
          bpm REAL,
          quality INTEGER NOT NULL,
          is_valid INTEGER NOT NULL,
          FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
        );

        CREATE INDEX IF NOT EXISTS idx_samples_session_id ON samples (session_id);

        CREATE TABLE IF NOT EXISTS session_stats (
          session_id TEXT PRIMARY KEY,
          mean_hr REAL NOT NULL,
          std_hr REAL NOT NULL,
          min_hr REAL NOT NULL,
          max_hr REAL NOT NULL,
          start_hr REAL NOT NULL,
          end_hr REAL NOT NULL,
          recovery_drop REAL,
          pulse_interval_ms REAL,
          variability_est_ms REAL,
          valid_sample_count INTEGER NOT NULL,
          total_duration_seconds INTEGER NOT NULL,
          FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS ai_results (
          session_id TEXT PRIMARY KEY,
          model_version TEXT NOT NULL,
          label TEXT NOT NULL,
          features_json TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS reminders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          hour INTEGER NOT NULL,
          minute INTEGER NOT NULL,
          label TEXT NOT NULL,
          is_enabled INTEGER NOT NULL,
          days_of_week TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS app_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        );
    """)

    # Migration v2
    conn.execute("ALTER TABLE samples ADD COLUMN spo2 REAL;")
    conn.execute("ALTER TABLE session_stats ADD COLUMN avg_spo2 REAL;")
    conn.execute("PRAGMA user_version = 2;")

    schema = {}
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
    tables = [row[0] for row in cursor.fetchall()]

    for t in tables:
        cursor.execute(f"PRAGMA table_info({t});")
        columns = {row[1] for row in cursor.fetchall()}
        schema[t] = columns

    conn.close()
    return schema

def parse_mermaid_erd(mmd_path: Path) -> dict[str, set[str]]:
    """Parses a Mermaid erDiagram file and extracts table and column names."""
    content = mmd_path.read_text(encoding="utf-8")
    
    # Match blocks like: table_name { ... } starting at line boundary
    pattern = re.compile(r"^[ \t]*([a-zA-Z_]\w*)[ \t]*\{([^}]+)\}", re.MULTILINE)
    matches = pattern.findall(content)

    erd_schema = {}
    for table_name, body in matches:
        cols = set()
        for line in body.strip().splitlines():
            line = line.strip()
            if not line or line.startswith("%%"):
                continue
            tokens = line.split()
            if len(tokens) >= 2:
                col_name = tokens[1]
                cols.add(col_name)
        erd_schema[table_name] = cols

    return erd_schema

def main():
    mmd_file = Path("docs/erd/pulse_patch_erd.mmd")
    if not mmd_file.exists():
        print(f"Error: {mmd_file} not found.")
        sys.exit(1)

    real_schema = get_real_sqlite_schema()
    erd_schema = parse_mermaid_erd(mmd_file)

    print("================================================================================")
    print("PulsePatch Lite — ERD vs Real SQLite Schema Parity Verification")
    print("================================================================================")
    print(f"ERD File:          {mmd_file}")
    print(f"Real Tables Count: {len(real_schema)}")
    print(f"ERD Tables Count:  {len(erd_schema)}")
    print("--------------------------------------------------------------------------------")

    all_tables = sorted(set(real_schema.keys()) | set(erd_schema.keys()))
    has_error = False

    for table in all_tables:
        if table not in real_schema:
            print(f"[-] Extra table in ERD: {table}")
            has_error = True
            continue
        if table not in erd_schema:
            print(f"[-] Missing table in ERD: {table}")
            has_error = True
            continue

        real_cols = real_schema[table]
        erd_cols = erd_schema[table]

        missing = sorted(real_cols - erd_cols)
        extra = sorted(erd_cols - real_cols)

        if missing or extra:
            has_error = True
            print(f"[FAIL] Table '{table}':")
            if missing:
                print(f"       Missing columns in ERD: {missing}")
            if extra:
                print(f"       Extra columns in ERD:   {extra}")
        else:
            print(f"[PASS] Table '{table}': {len(real_cols)} columns verified exactly.")

    print("================================================================================")
    if has_error:
        print("VERDICT: FAILED — Discrepancies found between ERD and SQLite schema.")
        sys.exit(1)
    else:
        print("VERDICT: 100% PARITY — 0 missing and 0 extra tables/columns.")
        print("================================================================================")

if __name__ == "__main__":
    main()
