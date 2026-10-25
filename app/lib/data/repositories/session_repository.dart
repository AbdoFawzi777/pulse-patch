import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3/sqlite3.dart';
import '../../domain/entities/ai_result_record.dart';
import '../../domain/entities/pulse_sample.dart';
import '../../domain/entities/session_record.dart';
import '../../domain/entities/session_stats_record.dart';
import '../drift/app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('appDatabaseProvider must be overridden in main()');
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SessionRepository(db);
});

class SessionDetailsData {
  const SessionDetailsData({
    required this.session,
    required this.samples,
    this.stats,
    this.aiResult,
  });

  final SessionRecord session;
  final List<PulseSample> samples;
  final SessionStatsRecord? stats;
  final AiResultRecord? aiResult;
}

class SessionRepository {
  SessionRepository(this._db);

  final AppDatabase _db;

  /// Inserts a complete session with its samples and statistics inside an atomic transaction.
  Future<void> insertSession({
    required SessionRecord session,
    required List<PulseSample> samples,
    SessionStatsRecord? stats,
    AiResultRecord? aiResult,
  }) async {
    try {
      final db = _db.rawDb;
      db.execute('BEGIN TRANSACTION;');

      db.execute(
        '''
        INSERT INTO sessions (id, started_at, ended_at, type, quality_summary, app_version, source)
        VALUES (?, ?, ?, ?, ?, ?, ?);
      ''',
        [
          session.id,
          session.startedAt.millisecondsSinceEpoch,
          session.endedAt?.millisecondsSinceEpoch,
          session.type.name,
          session.qualitySummary.name,
          session.appVersion,
          session.source.code,
        ],
      );

      final sampleStmt = db.prepare('''
        INSERT INTO samples (session_id, t_ms, bpm, quality, is_valid, spo2)
        VALUES (?, ?, ?, ?, ?, ?);
      ''');

      for (final s in samples) {
        sampleStmt.execute([
          s.sessionId,
          s.tMs,
          s.bpm,
          s.quality,
          s.isValid ? 1 : 0,
          s.spo2,
        ]);
      }
      sampleStmt.dispose();

      if (stats != null) {
        db.execute(
          '''
          INSERT INTO session_stats (
            session_id, mean_hr, std_hr, min_hr, max_hr, start_hr, end_hr,
            recovery_drop, pulse_interval_ms, variability_est_ms, valid_sample_count, total_duration_seconds, avg_spo2
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        ''',
          [
            stats.sessionId,
            stats.meanHr,
            stats.stdHr,
            stats.minHr,
            stats.maxHr,
            stats.startHr,
            stats.endHr,
            stats.recoveryDrop,
            stats.pulseIntervalMs,
            stats.variabilityEstMs,
            stats.validSampleCount,
            stats.totalDurationSeconds,
            stats.avgSpo2,
          ],
        );
      }

      if (aiResult != null) {
        db.execute(
          '''
          INSERT INTO ai_results (session_id, model_version, label, features_json, created_at)
          VALUES (?, ?, ?, ?, ?);
        ''',
          [
            aiResult.sessionId,
            aiResult.modelVersion,
            aiResult.label,
            aiResult.featuresJson,
            aiResult.createdAt.millisecondsSinceEpoch,
          ],
        );
      }

      db.execute('COMMIT;');
    } catch (e) {
      try {
        _db.rawDb.execute('ROLLBACK;');
      } catch (_) {}
      throw StorageException('Failed to insert session transactionally', e);
    }
  }

  /// Retrieves all recorded sessions ordered by latest started_at first.
  List<SessionRecord> getAllSessions() {
    try {
      final rows = _db.rawDb.select(
        'SELECT * FROM sessions ORDER BY started_at DESC;',
      );
      return rows.map<SessionRecord>((r) => _mapSessionRow(r)).toList();
    } catch (e) {
      throw StorageException('Failed to query sessions', e);
    }
  }

  /// Retrieves a specific session by its UUID.
  SessionRecord? getSessionById(String id) {
    try {
      final rows = _db.rawDb.select('SELECT * FROM sessions WHERE id = ?;', [
        id,
      ]);
      if (rows.isEmpty) return null;
      return _mapSessionRow(rows.first);
    } catch (e) {
      throw StorageException('Failed to get session by id: $id', e);
    }
  }

  /// Retrieves full session details including samples, stats, and AI result.
  SessionDetailsData? getSessionDetails(String id) {
    final session = getSessionById(id);
    if (session == null) return null;

    final samples = getSamplesForSession(id);
    final stats = getStatsForSession(id);
    final aiResult = getAiResultForSession(id);

    return SessionDetailsData(
      session: session,
      samples: samples,
      stats: stats,
      aiResult: aiResult,
    );
  }

  /// Retrieves all pulse samples belonging to a session.
  List<PulseSample> getSamplesForSession(String sessionId) {
    try {
      final rows = _db.rawDb.select(
        'SELECT * FROM samples WHERE session_id = ? ORDER BY t_ms ASC;',
        [sessionId],
      );
      return rows.map((r) {
        return PulseSample(
          id: r['id'] as int?,
          sessionId: r['session_id'] as String,
          tMs: r['t_ms'] as int,
          bpm: (r['bpm'] as num?)?.toDouble(),
          quality: r['quality'] as int,
          isValid: (r['is_valid'] as int) == 1,
          spo2: (r['spo2'] as num?)?.toDouble(),
        );
      }).toList();
    } catch (e) {
      throw StorageException(
        'Failed to query samples for session: $sessionId',
        e,
      );
    }
  }

  /// Retrieves computed statistics for a session.
  SessionStatsRecord? getStatsForSession(String sessionId) {
    try {
      final rows = _db.rawDb.select(
        'SELECT * FROM session_stats WHERE session_id = ?;',
        [sessionId],
      );
      if (rows.isEmpty) return null;
      final r = rows.first;
      return SessionStatsRecord(
        sessionId: r['session_id'] as String,
        meanHr: (r['mean_hr'] as num).toDouble(),
        stdHr: (r['std_hr'] as num).toDouble(),
        minHr: (r['min_hr'] as num).toDouble(),
        maxHr: (r['max_hr'] as num).toDouble(),
        startHr: (r['start_hr'] as num).toDouble(),
        endHr: (r['end_hr'] as num).toDouble(),
        recoveryDrop: (r['recovery_drop'] as num?)?.toDouble(),
        pulseIntervalMs: (r['pulse_interval_ms'] as num?)?.toDouble(),
        variabilityEstMs: (r['variability_est_ms'] as num?)?.toDouble(),
        validSampleCount: r['valid_sample_count'] as int,
        totalDurationSeconds: r['total_duration_seconds'] as int,
        avgSpo2: (r['avg_spo2'] as num?)?.toDouble(),
      );
    } catch (e) {
      throw StorageException(
        'Failed to query stats for session: $sessionId',
        e,
      );
    }
  }

  /// Retrieves the stored AI classification result for a session.
  AiResultRecord? getAiResultForSession(String sessionId) {
    try {
      final rows = _db.rawDb.select(
        'SELECT * FROM ai_results WHERE session_id = ?;',
        [sessionId],
      );
      if (rows.isEmpty) return null;
      final r = rows.first;
      return AiResultRecord(
        sessionId: r['session_id'] as String,
        modelVersion: r['model_version'] as String,
        label: r['label'] as String,
        featuresJson: r['features_json'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
      );
    } catch (e) {
      throw StorageException(
        'Failed to query AI result for session: $sessionId',
        e,
      );
    }
  }

  /// Inserts or updates an AI classification result for a session.
  void insertOrUpdateAiResult(AiResultRecord aiResult) {
    try {
      _db.rawDb.execute(
        '''
        INSERT INTO ai_results (session_id, model_version, label, features_json, created_at)
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(session_id) DO UPDATE SET
          model_version = excluded.model_version,
          label = excluded.label,
          features_json = excluded.features_json,
          created_at = excluded.created_at;
      ''',
        [
          aiResult.sessionId,
          aiResult.modelVersion,
          aiResult.label,
          aiResult.featuresJson,
          aiResult.createdAt.millisecondsSinceEpoch,
        ],
      );
    } catch (e) {
      throw StorageException(
        'Failed to save AI result for session: ${aiResult.sessionId}',
        e,
      );
    }
  }

  /// Deletes a specific session and cascades to samples, stats, and AI results.
  Future<void> deleteSession(String id) async {
    try {
      _db.rawDb.execute('DELETE FROM sessions WHERE id = ?;', [id]);
    } catch (e) {
      throw StorageException('Failed to delete session: $id', e);
    }
  }

  /// Erases all user recorded sessions and samples.
  Future<void> deleteAllData() async {
    try {
      final db = _db.rawDb;
      db.execute('BEGIN TRANSACTION;');
      db.execute('DELETE FROM samples;');
      db.execute('DELETE FROM session_stats;');
      db.execute('DELETE FROM ai_results;');
      db.execute('DELETE FROM sessions;');
      db.execute('COMMIT;');
    } catch (e) {
      try {
        _db.rawDb.execute('ROLLBACK;');
      } catch (_) {}
      throw StorageException('Failed to delete all data', e);
    }
  }

  /// Exports all sessions and associated stats to a structured JSON string.
  String exportToJson() {
    final sessions = getAllSessions();
    final exportList = <Map<String, dynamic>>[];

    for (final s in sessions) {
      final stats = getStatsForSession(s.id);
      final ai = getAiResultForSession(s.id);
      exportList.add({
        'session': s.toJson(),
        'stats': stats?.toJson(),
        'aiResult': ai?.toJson(),
      });
    }

    return const JsonEncoder.withIndent('  ').convert({
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'sessions': exportList,
    });
  }

  /// Exports sessions summary to standard CSV.
  String exportToCsv() {
    final sessions = getAllSessions();
    final buffer = StringBuffer();
    buffer.writeln(
      'SessionID,StartedAt,EndedAt,Type,Quality,DurationSec,MeanBPM,MinBPM,MaxBPM,PatternLabel,Source',
    );

    for (final s in sessions) {
      final stats = getStatsForSession(s.id);
      final ai = getAiResultForSession(s.id);

      final row = [
        s.id,
        s.startedAt.toIso8601String(),
        s.endedAt?.toIso8601String() ?? '',
        s.type.name,
        s.qualitySummary.name,
        stats?.totalDurationSeconds ?? s.durationSeconds,
        stats?.meanHr.toStringAsFixed(1) ?? '',
        stats?.minHr.toStringAsFixed(1) ?? '',
        stats?.maxHr.toStringAsFixed(1) ?? '',
        ai?.label ?? 'none',
        s.source.name,
      ];
      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  /// Exports feature dataset for Python ML model retraining (Section 7.2 of build plan).
  String exportTrainingCsv({String anonymousSubjectId = 'sub-01'}) {
    final sessions = getAllSessions();
    final buffer = StringBuffer();
    buffer.writeln(
      'subject_code,session_id,session_type,source,mean_hr,std_hr,start_hr,end_hr,recovery_drop,valid_sample_count,quality,created_at',
    );

    for (final s in sessions) {
      final stats = getStatsForSession(s.id);
      if (stats == null) continue;

      final row = [
        anonymousSubjectId,
        s.id,
        s.type.name,
        s.source.code,
        stats.meanHr.toStringAsFixed(2),
        stats.stdHr.toStringAsFixed(2),
        stats.startHr.toStringAsFixed(2),
        stats.endHr.toStringAsFixed(2),
        stats.recoveryDrop?.toStringAsFixed(2) ?? '',
        stats.validSampleCount.toString(),
        s.qualitySummary.name,
        s.startedAt.toIso8601String(),
      ];
      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  SessionRecord _mapSessionRow(Row r) {
    return SessionRecord(
      id: r['id'] as String,
      startedAt: DateTime.fromMillisecondsSinceEpoch(r['started_at'] as int),
      endedAt: r['ended_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(r['ended_at'] as int)
          : null,
      type: SessionType.fromString(r['type'] as String),
      qualitySummary: QualitySummary.fromString(r['quality_summary'] as String),
      appVersion: r['app_version'] as String,
      source: SessionSource.fromString(r['source'] as String),
    );
  }
}
