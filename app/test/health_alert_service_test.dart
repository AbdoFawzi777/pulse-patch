import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/drift/app_database.dart';
import 'package:app/domain/alerts/health_alert_service.dart';
import 'package:app/domain/entities/session_record.dart';
import 'package:app/domain/entities/session_stats_record.dart';

void main() {
  late AppDatabase db;
  late HealthAlertService alertService;

  setUp(() {
    db = AppDatabase.inMemory();
    alertService = HealthAlertService(db: db, notificationNotifier: null);
  });

  tearDown(() {
    db.close();
  });

  group('HealthAlertService Tests', () {
    test('Elevated resting heart rate (>100 BPM) generates moderate alert', () async {
      final now = DateTime.now();
      final session = SessionRecord(
        id: 'sess-tachy',
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 2)),
        type: SessionType.rest,
        qualitySummary: QualitySummary.good,
        appVersion: '2.0.0',
        source: SessionSource.pulsepatch,
      );

      // Insert session in database to satisfy foreign key constraint
      db.rawDb.execute(
        '''
        INSERT INTO sessions (id, started_at, ended_at, type, quality_summary, app_version, source)
        VALUES (?, ?, ?, ?, ?, ?, ?);
        ''',
        [session.id, now.millisecondsSinceEpoch, now.add(const Duration(minutes: 2)).millisecondsSinceEpoch, 'rest', 'good', '2.0.0', 'pulsepatch'],
      );

      final stats = SessionStatsRecord(
        sessionId: 'sess-tachy',
        meanHr: 108.0,
        stdHr: 4.0,
        minHr: 98.0,
        maxHr: 115.0,
        startHr: 105.0,
        endHr: 110.0,
        validSampleCount: 120,
        totalDurationSeconds: 120,
      );

      final alert = await alertService.evaluateSessionStats(session: session, stats: stats);

      expect(alert, isNotNull);
      expect(alert!.severity, equals(AlertSeverity.moderate));
      expect(alert.title, contains('>100 BPM'));
      expect(alert.titleAr.isNotEmpty, isTrue);

      final active = alertService.getActiveAlerts();
      expect(active.length, equals(1));
    });

    test('Severe hypoxemia (<90% SpO2) triggers urgent alert with emergency number 123', () async {
      final now = DateTime.now();
      final session = SessionRecord(
        id: 'sess-hypo',
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 2)),
        type: SessionType.rest,
        qualitySummary: QualitySummary.good,
        appVersion: '2.0.0',
        source: SessionSource.pulsepatch,
      );

      db.rawDb.execute(
        '''
        INSERT INTO sessions (id, started_at, ended_at, type, quality_summary, app_version, source)
        VALUES (?, ?, ?, ?, ?, ?, ?);
        ''',
        [session.id, now.millisecondsSinceEpoch, now.add(const Duration(minutes: 2)).millisecondsSinceEpoch, 'rest', 'good', '2.0.0', 'pulsepatch'],
      );

      final stats = SessionStatsRecord(
        sessionId: 'sess-hypo',
        meanHr: 82.0,
        stdHr: 3.0,
        minHr: 75.0,
        maxHr: 90.0,
        startHr: 80.0,
        endHr: 84.0,
        validSampleCount: 120,
        totalDurationSeconds: 120,
        avgSpo2: 88.5,
      );

      final alert = await alertService.evaluateSessionStats(session: session, stats: stats);

      expect(alert, isNotNull);
      expect(alert!.severity, equals(AlertSeverity.urgent));
      expect(alert.message, contains('123'));
      expect(alert.messageAr, contains('123'));
    });

    test('Cuff reading >= 180/120 generates urgent hypertensive crisis alert', () async {
      final alert = await alertService.evaluateCuffMeasurement(sbp: 185.0, dbp: 122.0);

      expect(alert, isNotNull);
      expect(alert!.severity, equals(AlertSeverity.urgent));
      expect(alert.title, contains('Hypertensive Crisis'));
      expect(alert.message, contains('123'));
    });

    test('Duplicate alert suppressed within cooldown period', () async {
      final now = DateTime.now();
      final session = SessionRecord(
        id: 'sess-dup-1',
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 2)),
        type: SessionType.rest,
        qualitySummary: QualitySummary.good,
        appVersion: '2.0.0',
        source: SessionSource.pulsepatch,
      );

      db.rawDb.execute(
        '''
        INSERT INTO sessions (id, started_at, ended_at, type, quality_summary, app_version, source)
        VALUES (?, ?, ?, ?, ?, ?, ?);
        ''',
        [session.id, now.millisecondsSinceEpoch, now.add(const Duration(minutes: 2)).millisecondsSinceEpoch, 'rest', 'good', '2.0.0', 'pulsepatch'],
      );

      final stats = SessionStatsRecord(
        sessionId: 'sess-dup-1',
        meanHr: 110.0,
        stdHr: 3.0,
        minHr: 100.0,
        maxHr: 115.0,
        startHr: 105.0,
        endHr: 110.0,
        validSampleCount: 120,
        totalDurationSeconds: 120,
      );

      final firstAlert = await alertService.evaluateSessionStats(session: session, stats: stats);
      expect(firstAlert, isNotNull);

      // Attempt immediate duplicate
      final secondAlert = await alertService.evaluateSessionStats(session: session, stats: stats);
      expect(secondAlert, isNull); // Suppressed by cooldown
    });

    test('Dismissing alert updates database record', () async {
      final alert = await alertService.evaluateCuffMeasurement(sbp: 150.0, dbp: 95.0);
      expect(alert, isNotNull);

      expect(alertService.getActiveAlerts().length, equals(1));

      alertService.dismissAlert(alert!.id);
      expect(alertService.getActiveAlerts().isEmpty, isTrue);
    });
  });
}
