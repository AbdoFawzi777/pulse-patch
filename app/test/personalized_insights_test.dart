import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/drift/app_database.dart';
import 'package:app/data/repositories/session_repository.dart';
import 'package:app/data/repositories/user_profile_repository.dart';
import 'package:app/domain/analytics/health_analytics_service.dart';
import 'package:app/domain/entities/pulse_sample.dart';
import 'package:app/domain/entities/session_record.dart';
import 'package:app/domain/entities/session_stats_record.dart';
import 'package:app/domain/insights/personalized_insights_service.dart';
import 'package:app/domain/profile/user_profile.dart';

void main() {
  late AppDatabase db;
  late SessionRepository sessionRepo;
  late UserProfileRepository profileRepo;
  late HealthAnalyticsService analyticsService;
  late PersonalizedInsightsService insightsService;

  setUp(() {
    db = AppDatabase.inMemory();
    sessionRepo = SessionRepository(db);
    profileRepo = UserProfileRepository(db);
    analyticsService = HealthAnalyticsService(sessionRepo: sessionRepo, db: db);
    insightsService = PersonalizedInsightsService(
      analytics: analyticsService,
      profileRepo: profileRepo,
    );
  });

  tearDown(() {
    db.close();
  });

  group('PersonalizedInsightsService Tests', () {
    test('Empty history produces initial setup guidance', () async {
      final insights = await insightsService.generateInsights();

      expect(insights.length, equals(1));
      expect(insights.first.id, equals('insight-start-monitoring'));
      expect(insights.first.title, contains('Health Baseline'));
      expect(insights.first.titleAr.isNotEmpty, isTrue);
      expect(insights.first.observationAr.isNotEmpty, isTrue);
      expect(insights.first.isInformational, isTrue);
    });

    test('1 to 2 sessions produces baseline in-progress guidance', () async {
      final now = DateTime.now();
      final session = SessionRecord(
        id: 'sess-1',
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 2)),
        type: SessionType.rest,
        qualitySummary: QualitySummary.good,
        appVersion: '2.0.0',
        source: SessionSource.pulsepatch,
      );
      final stats = SessionStatsRecord(
        sessionId: 'sess-1',
        meanHr: 72.0,
        stdHr: 2.1,
        minHr: 68.0,
        maxHr: 78.0,
        startHr: 74.0,
        endHr: 70.0,
        validSampleCount: 120,
        totalDurationSeconds: 120,
        avgSpo2: 98.0,
      );
      final sample = PulseSample(sessionId: 'sess-1', tMs: 0, bpm: 72.0, quality: 90, isValid: true);

      await sessionRepo.insertSession(session: session, samples: [sample], stats: stats);

      final insights = await insightsService.generateInsights();
      expect(insights.length, equals(1));
      expect(insights.first.id, equals('insight-insufficient-history'));
      expect(insights.first.sampleCount, equals(1));
    });

    test('Sufficient history produces resting HR, SpO2, and demographic insights', () async {
      final now = DateTime.now();

      // Save a user profile with BMI >= 25
      final profile = UserProfile(
        id: 'user_primary',
        fullName: 'Ahmed Ali',
        age: 35,
        gender: 'male',
        heightCm: 175.0,
        weightKg: 85.0, // BMI = 27.8 -> Overweight
        createdAt: now,
        updatedAt: now,
      );
      await profileRepo.saveProfile(profile);

      // Save 4 sessions
      for (int i = 0; i < 4; i++) {
        final sessId = 'sess-$i';
        final session = SessionRecord(
          id: sessId,
          startedAt: now.subtract(Duration(days: i)),
          endedAt: now.subtract(Duration(days: i)).add(const Duration(minutes: 2)),
          type: SessionType.rest,
          qualitySummary: QualitySummary.good,
          appVersion: '2.0.0',
          source: SessionSource.pulsepatch,
        );
        final stats = SessionStatsRecord(
          sessionId: sessId,
          meanHr: 71.0,
          stdHr: 2.0,
          minHr: 68.0,
          maxHr: 75.0,
          startHr: 73.0,
          endHr: 70.0,
          validSampleCount: 120,
          totalDurationSeconds: 120,
          avgSpo2: 99.0,
        );
        final sample = PulseSample(sessionId: sessId, tMs: 0, bpm: 71.0, quality: 90, isValid: true, spo2: 99.0);
        await sessionRepo.insertSession(session: session, samples: [sample], stats: stats);
      }

      final insights = await insightsService.generateInsights();

      expect(insights.any((i) => i.id == 'insight-hr-stable'), isTrue);
      expect(insights.any((i) => i.id == 'insight-spo2-optimal'), isTrue);
      expect(insights.any((i) => i.id == 'insight-bmi-lifestyle'), isTrue);

      // Verify no prescription or diagnosis exists in recommendations
      for (final ins in insights) {
        expect(ins.recommendation.toLowerCase(), isNot(contains('prescribe')));
        expect(ins.recommendation.toLowerCase(), isNot(contains('diagnose')));
        expect(ins.evidenceNote.isNotEmpty, isTrue);
        expect(ins.titleAr.isNotEmpty, isTrue);
      }
    });
  });
}
