import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class StorageException implements Exception {
  const StorageException(this.message, [this.cause]);
  final String message;
  final Object? cause;

  @override
  String toString() =>
      'StorageException: $message ${cause != null ? "($cause)" : ""}';
}

/// Robust SQLite database engine for PulsePatch Lite.
class AppDatabase {
  AppDatabase._(this._db) {
    _initDatabase();
  }

  final Database _db;

  Database get rawDb => _db;

  /// Creates a transient in-memory database for unit testing.
  factory AppDatabase.inMemory() {
    final db = sqlite3.openInMemory();
    return AppDatabase._(db);
  }

  /// Creates an on-disk database located in the application support directory.
  static Future<AppDatabase> onDisk() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(docDir.path, 'pulse_patch.db');
      final db = sqlite3.open(dbPath);
      return AppDatabase._(db);
    } catch (e) {
      throw StorageException('Failed to open on-disk database', e);
    }
  }

  void _initDatabase() {
    try {
      _db.execute('PRAGMA foreign_keys = ON;');
      _applyMigrations();
    } catch (e) {
      throw StorageException('Failed to initialize database schema', e);
    }
  }

  void _applyMigrations() {
    final result = _db.select('PRAGMA user_version;');
    final currentVersion = result.first.values.first as int;

    if (currentVersion < 1) {
      _db.execute('''
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

        PRAGMA user_version = 1;
      ''');
    }
  }

  void close() {
    _db.dispose();
  }
}
