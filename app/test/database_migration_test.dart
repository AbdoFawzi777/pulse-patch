import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  group('Database Schema Migration v1 -> v2 -> v3 Verification', () {
    test('Simulates explicit v1 database, applies migrations to v3, and checks integrity', () {
      final db = sqlite3.openInMemory();
      db.execute('PRAGMA foreign_keys = ON;');

      // 1. Create original Schema Version 1
      db.execute('''
        CREATE TABLE sessions (
          id TEXT PRIMARY KEY,
          started_at INTEGER NOT NULL,
          ended_at INTEGER,
          type TEXT NOT NULL,
          quality_summary TEXT NOT NULL,
          app_version TEXT NOT NULL,
          source TEXT NOT NULL
        );

        CREATE TABLE samples (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id TEXT NOT NULL,
          t_ms INTEGER NOT NULL,
          bpm REAL,
          quality INTEGER NOT NULL,
          is_valid INTEGER NOT NULL,
          FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
        );

        CREATE TABLE session_stats (
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

        CREATE TABLE ai_results (
          session_id TEXT PRIMARY KEY,
          model_version TEXT NOT NULL,
          label TEXT NOT NULL,
          features_json TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
        );

        CREATE TABLE reminders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          hour INTEGER NOT NULL,
          minute INTEGER NOT NULL,
          label TEXT NOT NULL,
          is_enabled INTEGER NOT NULL,
          days_of_week TEXT NOT NULL
        );

        CREATE TABLE app_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        );

        PRAGMA user_version = 1;
      ''');

      // Populate existing historic record
      db.execute('''
        INSERT INTO sessions (id, started_at, ended_at, type, quality_summary, app_version, source)
        VALUES ('historic-001', 1700000000, 1700000060, 'rest', 'good', '1.0.0', 'standard_hr');

        INSERT INTO samples (session_id, t_ms, bpm, quality, is_valid)
        VALUES ('historic-001', 1000, 72.0, 95, 1);

        INSERT INTO session_stats (session_id, mean_hr, std_hr, min_hr, max_hr, start_hr, end_hr, valid_sample_count, total_duration_seconds)
        VALUES ('historic-001', 72.0, 2.5, 70.0, 75.0, 71.0, 73.0, 1, 60);
      ''');

      // Verify v1 state
      final v1Check = db.select('PRAGMA user_version;');
      expect(v1Check.first.values.first, equals(1));

      // 2. Perform Migration to v2 (SpO2 columns)
      db.execute('ALTER TABLE samples ADD COLUMN spo2 REAL;');
      db.execute('ALTER TABLE session_stats ADD COLUMN avg_spo2 REAL;');
      db.execute('PRAGMA user_version = 2;');

      // 3. Perform Migration to v3 (New clinical & profile tables)
      db.execute('''
        CREATE TABLE IF NOT EXISTS user_profiles (
          id TEXT PRIMARY KEY,
          full_name TEXT NOT NULL,
          age INTEGER NOT NULL,
          gender TEXT NOT NULL,
          height_cm REAL NOT NULL,
          weight_kg REAL NOT NULL,
          baseline_sbp REAL,
          baseline_dbp REAL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        );

        CREATE TABLE IF NOT EXISTS bp_calibrations (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          cuff_sbp REAL NOT NULL,
          cuff_dbp REAL NOT NULL,
          estimated_sbp REAL NOT NULL,
          estimated_dbp REAL NOT NULL,
          offset_sbp REAL NOT NULL,
          offset_dbp REAL NOT NULL,
          calibrated_at INTEGER NOT NULL,
          device_identifier TEXT,
          FOREIGN KEY (user_id) REFERENCES user_profiles (id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS bp_estimates (
          id TEXT PRIMARY KEY,
          session_id TEXT NOT NULL,
          sbp REAL NOT NULL,
          dbp REAL NOT NULL,
          map REAL NOT NULL,
          category TEXT NOT NULL,
          category_ar TEXT NOT NULL,
          is_calibrated INTEGER NOT NULL,
          confidence_score REAL NOT NULL,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS health_alerts (
          id TEXT PRIMARY KEY,
          session_id TEXT,
          severity TEXT NOT NULL,
          title TEXT NOT NULL,
          title_ar TEXT NOT NULL,
          message TEXT NOT NULL,
          message_ar TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          is_dismissed INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE SET NULL
        );

        CREATE TABLE IF NOT EXISTS doctor_cache (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          specialty TEXT NOT NULL,
          address TEXT NOT NULL,
          phone TEXT,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          city TEXT NOT NULL,
          cached_at INTEGER NOT NULL
        );

        PRAGMA user_version = 3;
      ''');

      // Verify v3 state & preserved record
      final v3Check = db.select('PRAGMA user_version;');
      expect(v3Check.first.values.first, equals(3));

      final historicRows = db.select("SELECT * FROM sessions WHERE id = 'historic-001';");
      expect(historicRows.length, equals(1));
      expect(historicRows.first['app_version'], equals('1.0.0'));

      // Test Cascade deletion
      db.execute("DELETE FROM sessions WHERE id = 'historic-001';");
      final sampleCheck = db.select("SELECT * FROM samples WHERE session_id = 'historic-001';");
      expect(sampleCheck.length, equals(0), reason: 'CASCADE foreign key must delete child samples');

      db.dispose();
    });
  });
}
