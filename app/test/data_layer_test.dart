import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/drift/app_database.dart';
import 'package:app/data/repositories/reminder_repository.dart';
import 'package:app/data/repositories/session_repository.dart';
import 'package:app/domain/entities/ai_result_record.dart';
import 'package:app/domain/entities/pulse_sample.dart';
import 'package:app/domain/entities/reminder_record.dart';
import 'package:app/domain/entities/session_record.dart';
import 'package:app/domain/entities/session_stats_record.dart';

void main() {
  late AppDatabase db;
  late SessionRepository sessionRepo;
  late ReminderRepository reminderRepo;

  setUp(() {
    db = AppDatabase.inMemory();
    sessionRepo = SessionRepository(db);
    reminderRepo = ReminderRepository(db);
  });

  tearDown(() {
    db.close();
  });

  group('Phase 3 Data Layer - Database & Migrations', () {
    test(
      'Database initializes in-memory with user_version 2 and foreign keys',
      () {
        final versionResult = db.rawDb.select('PRAGMA user_version;');
        expect(versionResult.first.values.first, 2);

        final fkResult = db.rawDb.select('PRAGMA foreign_keys;');
        expect(fkResult.first.values.first, 1);
      },
    );
  });

  group('Phase 3 Data Layer - SessionRepository Operations', () {
    test(
      'Inserts and retrieves complete session with samples and stats',
      () async {
        final now = DateTime.now();
        final session = SessionRecord(
          id: 'session-001',
          startedAt: now,
          endedAt: now.add(const Duration(seconds: 60)),
          type: SessionType.rest,
          qualitySummary: QualitySummary.good,
          appVersion: '1.0.0',
          source: SessionSource.pulsepatch,
        );

        final samples = [
          const PulseSample(
            sessionId: 'session-001',
            tMs: 0,
            bpm: 72.0,
            quality: 90,
            isValid: true,
          ),
          const PulseSample(
            sessionId: 'session-001',
            tMs: 1000,
            bpm: 74.0,
            quality: 92,
            isValid: true,
          ),
        ];

        final stats = const SessionStatsRecord(
          sessionId: 'session-001',
          meanHr: 73.0,
          stdHr: 1.41,
          minHr: 72.0,
          maxHr: 74.0,
          startHr: 72.0,
          endHr: 74.0,
          recoveryDrop: 2.0,
          pulseIntervalMs: 820.0,
          variabilityEstMs: 38.0,
          validSampleCount: 2,
          totalDurationSeconds: 60,
        );

        final aiResult = AiResultRecord(
          sessionId: 'session-001',
          modelVersion: '1.0.0-neural-net',
          label: 'typical',
          featuresJson: jsonEncode({'mean_hr': 73.0, 'recovery_drop': 2.0}),
          createdAt: now,
        );

        await sessionRepo.insertSession(
          session: session,
          samples: samples,
          stats: stats,
          aiResult: aiResult,
        );

        final allSessions = sessionRepo.getAllSessions();
        expect(allSessions.length, 1);
        expect(allSessions.first.id, 'session-001');

        final details = sessionRepo.getSessionDetails('session-001');
        expect(details, isNotNull);
        expect(details!.session.source, SessionSource.pulsepatch);
        expect(details.samples.length, 2);
        expect(details.stats?.meanHr, 73.0);
        expect(details.aiResult?.label, 'typical');
      },
    );

    test(
      'SessionSource supports multi-source codes and SpO2 persistence',
      () async {
        final now = DateTime.now();
        for (final src in [
          SessionSource.pulsepatch,
          SessionSource.standardBle,
          SessionSource.miBand5,
          SessionSource.importSource,
          SessionSource.simulator,
        ]) {
          final id = 'src-test-${src.code}';
          await sessionRepo.insertSession(
            session: SessionRecord(
              id: id,
              startedAt: now,
              type: SessionType.rest,
              qualitySummary: QualitySummary.good,
              appVersion: '1.0.0',
              source: src,
            ),
            samples: [
              PulseSample(
                sessionId: id,
                tMs: 0,
                bpm: 70.0,
                quality: 95,
                isValid: true,
                spo2: 98.0,
              ),
            ],
            stats: SessionStatsRecord(
              sessionId: id,
              meanHr: 70.0,
              stdHr: 0.0,
              minHr: 70.0,
              maxHr: 70.0,
              startHr: 70.0,
              endHr: 70.0,
              validSampleCount: 1,
              totalDurationSeconds: 10,
              avgSpo2: 98.0,
            ),
          );

          final loaded = sessionRepo.getSessionDetails(id);
          expect(loaded?.session.source, src);
          expect(loaded?.samples.first.spo2, 98.0);
          expect(loaded?.stats?.avgSpo2, 98.0);
        }
      },
    );

    test(
      'Cascade deletes samples, stats, and AI result on session deletion',
      () async {
        final now = DateTime.now();
        final session = SessionRecord(
          id: 'session-del',
          startedAt: now,
          type: SessionType.postActivity,
          qualitySummary: QualitySummary.fair,
          appVersion: '1.0.0',
          source: SessionSource.simulator,
        );

        final samples = [
          const PulseSample(
            sessionId: 'session-del',
            tMs: 0,
            bpm: 80.0,
            quality: 70,
            isValid: true,
          ),
        ];

        final stats = const SessionStatsRecord(
          sessionId: 'session-del',
          meanHr: 80.0,
          stdHr: 0.0,
          minHr: 80.0,
          maxHr: 80.0,
          startHr: 80.0,
          endHr: 80.0,
          validSampleCount: 1,
          totalDurationSeconds: 30,
        );

        await sessionRepo.insertSession(
          session: session,
          samples: samples,
          stats: stats,
        );

        expect(sessionRepo.getAllSessions().length, 1);
        expect(sessionRepo.getSamplesForSession('session-del').length, 1);

        await sessionRepo.deleteSession('session-del');
        expect(sessionRepo.getAllSessions().length, 0);
        expect(sessionRepo.getSamplesForSession('session-del').length, 0);
        expect(sessionRepo.getStatsForSession('session-del'), isNull);
      },
    );

    test('deleteAllData removes all records atomically', () async {
      final now = DateTime.now();
      for (int i = 0; i < 3; i++) {
        await sessionRepo.insertSession(
          session: SessionRecord(
            id: 'session-$i',
            startedAt: now.add(Duration(minutes: i)),
            type: SessionType.rest,
            qualitySummary: QualitySummary.good,
            appVersion: '1.0.0',
            source: SessionSource.pulsepatch,
          ),
          samples: const [],
        );
      }

      expect(sessionRepo.getAllSessions().length, 3);
      await sessionRepo.deleteAllData();
      expect(sessionRepo.getAllSessions().length, 0);
    });

    test('Exports sessions accurately to JSON and CSV formats', () async {
      final now = DateTime.parse('2026-10-24T12:00:00Z');
      final session = SessionRecord(
        id: 'session-exp',
        startedAt: now,
        endedAt: now.add(const Duration(seconds: 90)),
        type: SessionType.postActivity,
        qualitySummary: QualitySummary.good,
        appVersion: '1.0.0',
        source: SessionSource.pulsepatch,
      );

      final stats = const SessionStatsRecord(
        sessionId: 'session-exp',
        meanHr: 75.5,
        stdHr: 3.2,
        minHr: 68.0,
        maxHr: 88.0,
        startHr: 84.0,
        endHr: 70.0,
        recoveryDrop: 14.0,
        validSampleCount: 85,
        totalDurationSeconds: 90,
      );

      final aiResult = AiResultRecord(
        sessionId: 'session-exp',
        modelVersion: '1.0.0',
        label: 'typical',
        featuresJson: '{}',
        createdAt: now,
      );

      await sessionRepo.insertSession(
        session: session,
        samples: const [],
        stats: stats,
        aiResult: aiResult,
      );

      final jsonStr = sessionRepo.exportToJson();
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['version'], '1.0.0');
      expect((decoded['sessions'] as List).length, 1);

      final csvStr = sessionRepo.exportToCsv();
      expect(
        csvStr.contains('SessionID,StartedAt,EndedAt,Type,Quality'),
        isTrue,
      );
      expect(csvStr.contains('session-exp'), isTrue);
      expect(csvStr.contains('postActivity'), isTrue);

      final trainingCsv = sessionRepo.exportTrainingCsv(
        anonymousSubjectId: 'sub-vol-01',
      );
      expect(
        trainingCsv.contains(
          'subject_code,session_id,session_type,source,mean_hr,std_hr,start_hr,end_hr,recovery_drop,valid_sample_count,quality,created_at',
        ),
        isTrue,
      );
      expect(
        trainingCsv.contains(
          'sub-vol-01,session-exp,postActivity,pulsepatch,75.50,3.20,84.00,70.00,14.00,85,good,',
        ),
        isTrue,
      );
    });
  });

  group('Phase 3 Data Layer - ReminderRepository Operations', () {
    test('CRUD operations on user reminders', () async {
      final id = await reminderRepo.insertReminder(
        const ReminderRecord(
          hour: 8,
          minute: 30,
          label: 'Morning Resting Pulse',
          isEnabled: true,
          daysOfWeek: [1, 2, 3, 4, 5],
        ),
      );

      final reminders = reminderRepo.getAllReminders();
      expect(reminders.length, 1);
      expect(reminders.first.hour, 8);
      expect(reminders.first.minute, 30);
      expect(reminders.first.formattedTime, '08:30');
      expect(reminders.first.daysOfWeek, [1, 2, 3, 4, 5]);

      await reminderRepo.updateReminder(
        ReminderRecord(
          id: id,
          hour: 9,
          minute: 0,
          label: 'Updated Reminder',
          isEnabled: false,
        ),
      );

      final updated = reminderRepo.getAllReminders().first;
      expect(updated.hour, 9);
      expect(updated.minute, 0);
      expect(updated.isEnabled, isFalse);

      await reminderRepo.deleteReminder(id);
      expect(reminderRepo.getAllReminders().length, 0);
    });
  });
}
