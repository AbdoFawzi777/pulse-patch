import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/drift/app_database.dart';
import 'package:app/data/repositories/session_repository.dart';
import 'package:app/data/repositories/user_profile_repository.dart';
import 'package:app/domain/alerts/health_alert_service.dart';
import 'package:app/domain/analytics/health_analytics_service.dart';
import 'package:app/domain/doctors/doctor_discovery_service.dart';
import 'package:app/domain/entities/pulse_sample.dart';
import 'package:app/domain/entities/session_record.dart';
import 'package:app/domain/entities/session_stats_record.dart';
import 'package:app/domain/insights/personalized_insights_service.dart';
import 'package:app/domain/knowledge/medical_knowledge_engine.dart';
import 'package:app/domain/profile/user_profile.dart';
import 'package:app/domain/signal/ble_packet.dart';
import 'package:app/features/reports/pdf_report_generator.dart';

void main() {
  late AppDatabase db;
  late SessionRepository sessionRepo;
  late UserProfileRepository profileRepo;
  late HealthAnalyticsService analyticsService;
  late PersonalizedInsightsService insightsService;
  late HealthAlertService alertService;

  setUp(() {
    db = AppDatabase.inMemory();
    sessionRepo = SessionRepository(db);
    profileRepo = UserProfileRepository(db);
    analyticsService = HealthAnalyticsService(sessionRepo: sessionRepo, db: db);
    insightsService = PersonalizedInsightsService(analytics: analyticsService, profileRepo: profileRepo);
    alertService = HealthAlertService(db: db, notificationNotifier: null);
  });

  tearDown(() {
    db.close();
  });

  group('PulsePatch Lite End-to-End User Journeys (A through J)', () {
    test('Journey A — First-time user profile & BMI age safeguards', () async {
      final now = DateTime.now();

      // Pediatric user (< 18)
      final childProfile = UserProfile(
        id: 'child_1',
        fullName: 'Omar Child',
        age: 12,
        gender: 'male',
        heightCm: 145.0,
        weightKg: 40.0,
        createdAt: now,
        updatedAt: now,
      );
      await profileRepo.saveProfile(childProfile);

      final retrievedChild = await profileRepo.getProfile();
      expect(retrievedChild, isNotNull);
      expect(retrievedChild!.bmi, equals(19.0));
      expect(retrievedChild.bmiCategory, contains('under-18'));

      // Adult user (>= 18)
      final adultProfile = UserProfile(
        id: 'user_primary',
        fullName: 'Sara Adult',
        age: 28,
        gender: 'female',
        heightCm: 165.0,
        weightKg: 60.0,
        createdAt: now.add(const Duration(seconds: 2)),
        updatedAt: now.add(const Duration(seconds: 2)),
      );
      await profileRepo.saveProfile(adultProfile);

      final retrievedAdult = await profileRepo.getProfile();
      expect(retrievedAdult!.bmi, equals(22.0));
      expect(retrievedAdult.bmiCategory, equals('Normal weight'));
    });

    test('Journey B & C — BLE packet decoding, SpO2 & HR ingestion and session persistence', () async {
      // 12-byte telemetry packet with version=1, contact=1, rawBpm=75, quality=92, SpO2=98
      final packetBytes = [
        0x01,       // protocolVersion = 1
        0x01,       // contact = true
        0xEE, 0x02, // 750 (75.0 BPM)
        0x5C,       // quality = 92
        0x00, 0x00, 0x00, 0x00, // timestamp
        0x01, 0x00, // seq = 1
        0x62,       // SpO2 = 98%
      ];

      final packet = BlePacket.parse(packetBytes);
      expect(packet, isNotNull);
      expect(packet!.rawBpm, equals(75.0));
      expect(packet.quality, equals(92));
      expect(packet.spo2, equals(98.0));

      // Save recorded session
      final now = DateTime.now();
      final session = SessionRecord(
        id: 'sess-e2e-1',
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 2)),
        type: SessionType.rest,
        qualitySummary: QualitySummary.good,
        appVersion: '2.0.0',
        source: SessionSource.pulsepatch,
      );

      final stats = SessionStatsRecord(
        sessionId: 'sess-e2e-1',
        meanHr: 75.0,
        stdHr: 2.2,
        minHr: 70.0,
        maxHr: 80.0,
        startHr: 76.0,
        endHr: 74.0,
        validSampleCount: 120,
        totalDurationSeconds: 120,
        avgSpo2: 98.0,
      );

      final sample = PulseSample(
        sessionId: 'sess-e2e-1',
        tMs: 0,
        bpm: packet.rawBpm,
        quality: packet.quality,
        isValid: true,
        spo2: packet.spo2,
      );

      await sessionRepo.insertSession(session: session, samples: [sample], stats: stats);

      final loadedSessions = sessionRepo.getAllSessions();
      expect(loadedSessions.length, equals(1));
      final loadedStats = sessionRepo.getStatsForSession('sess-e2e-1');
      expect(loadedStats?.avgSpo2, equals(98.0));
    });

    test('Journey D — PPG streaming & invalid packet recovery', () {
      final invalidBytes = [0x00, 0x11, 0x22]; // Corrupted short packet
      final corruptedPacket = BlePacket.parse(invalidBytes);
      expect(corruptedPacket, isNull);
    });

    test('Journey E — Blood pressure cuff entry, calibration & safety alerts isolation', () async {
      // 1. Enter cuff reading >= 180/120 -> triggers clinical safety alert
      final crisisAlert = await alertService.evaluateCuffMeasurement(sbp: 184.0, dbp: 124.0);
      expect(crisisAlert, isNotNull);
      expect(crisisAlert!.severity, equals(AlertSeverity.urgent));
      expect(crisisAlert.message, contains('123')); // Egyptian ambulance

      // 2. Strict Safety Gate: AI model estimate does NOT trigger clinical alerts
      alertService.evaluateModelEstimateSafetyGate(sbp: 184.0, dbp: 124.0);
      final activeAlerts = alertService.getActiveAlerts();
      expect(activeAlerts.length, equals(1)); // Only the cuff alert, no model alerts
    });

    test('Journey F — Analytics, baseline & personalized recommendations', () async {
      final now = DateTime.now();

      // Seed 3 sessions to establish baseline
      for (int i = 0; i < 3; i++) {
        final id = 'sess-base-$i';
        final session = SessionRecord(
          id: id,
          startedAt: now.subtract(Duration(days: i)),
          endedAt: now.subtract(Duration(days: i)).add(const Duration(minutes: 2)),
          type: SessionType.rest,
          qualitySummary: QualitySummary.good,
          appVersion: '2.0.0',
          source: SessionSource.pulsepatch,
        );
        final stats = SessionStatsRecord(
          sessionId: id,
          meanHr: 72.0,
          stdHr: 2.0,
          minHr: 68.0,
          maxHr: 76.0,
          startHr: 74.0,
          endHr: 70.0,
          validSampleCount: 120,
          totalDurationSeconds: 120,
          avgSpo2: 98.0,
        );
        final sample = PulseSample(sessionId: id, tMs: 0, bpm: 72.0, quality: 90, isValid: true, spo2: 98.0);
        await sessionRepo.insertSession(session: session, samples: [sample], stats: stats);
      }

      final report = analyticsService.computeReport(referenceTime: now);
      expect(report.heartRateSummary.isReliable, isTrue);
      expect(report.heartRateSummary.baselineAverage, equals(72.0));

      final insights = await insightsService.generateInsights(referenceTime: now);
      expect(insights.any((i) => i.id == 'insight-hr-stable'), isTrue);
      expect(insights.any((i) => i.id == 'insight-spo2-optimal'), isTrue);
    });

    test('Journey G — Health alerts deduplication & dismissal', () async {
      final alert = await alertService.evaluateCuffMeasurement(sbp: 145.0, dbp: 95.0);
      expect(alert, isNotNull);
      expect(alertService.getActiveAlerts().length, equals(1));

      // Dismiss alert
      alertService.dismissAlert(alert!.id);
      expect(alertService.getActiveAlerts().isEmpty, isTrue);
    });

    test('Journey H — Doctor & clinic discovery with offline privacy', () async {
      const discovery = DoctorDiscoveryService();
      expect(DoctorDiscoveryService.curatedClinics.length, equals(5));

      // Test distance sorting relative to Cairo Downtown (30.05, 31.23)
      final sorted = await discovery.findClinics(
        userLat: 30.05,
        userLon: 31.23,
      );
      expect(sorted.first.id, equals('cairo_magdi_yacoub'));
      expect(sorted.first.distanceKm, lessThan(3.0));

      // Test city filter
      final alexClinics = await discovery.findClinics(city: 'Alexandria');
      expect(alexClinics.length, equals(1));
      expect(alexClinics.first.id, equals('alex_smoha_cardio'));
    });

    test('Journey I — PDF clinical report generation with complete audit trail', () async {
      final now = DateTime.now();
      final session = SessionRecord(
        id: 'sess-pdf-audit',
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 2)),
        type: SessionType.rest,
        qualitySummary: QualitySummary.good,
        appVersion: '2.0.0',
        source: SessionSource.pulsepatch,
      );
      final stats = SessionStatsRecord(
        sessionId: 'sess-pdf-audit',
        meanHr: 72.0,
        stdHr: 2.0,
        minHr: 68.0,
        maxHr: 76.0,
        startHr: 74.0,
        endHr: 70.0,
        validSampleCount: 120,
        totalDurationSeconds: 120,
        avgSpo2: 99.0,
      );

      final pdfBytes = await PdfReportGenerator.generate(
        userName: 'Audit Subject',
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now,
        items: [
          SessionReportData(session: session, stats: stats, aiPattern: 'Typical pattern'),
        ],
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('Journey J — Persistence and state integrity across restarts', () async {
      final now = DateTime.now();
      final profile = UserProfile(
        id: 'restart_user',
        fullName: 'Persistence User',
        age: 45,
        gender: 'female',
        heightCm: 168.0,
        weightKg: 65.0,
        baselineSbp: 120.0,
        baselineDbp: 80.0,
        createdAt: now,
        updatedAt: now,
      );
      await profileRepo.saveProfile(profile);

      final reloaded = await profileRepo.getProfile();
      expect(reloaded?.fullName, equals('Persistence User'));
      expect(reloaded?.baselineSbp, equals(120.0));
      expect(reloaded?.baselineDbp, equals(80.0));
    });

    test('Journey K — Medical Knowledge Assistant query & authoritative citation audit', () async {
      final engine = MedicalKnowledgeEngine();
      await engine.initialize();

      // Query WHO blood pressure guidelines
      final bpAnswer = await engine.query('WHO blood pressure classification');
      expect(bpAnswer.citations, isNotEmpty);
      expect(bpAnswer.citations.first.organization, contains('World Health Organization'));
      expect(bpAnswer.citations.first.sourceUrl, isNotEmpty);
      expect(bpAnswer.isEmergency, isFalse);

      // Query emergency red flag symptoms
      final emergencyAnswer = await engine.query('crushing chest pain and difficulty breathing');
      expect(emergencyAnswer.isEmergency, isTrue);
      expect(emergencyAnswer.emergencyNoticeEn, contains('123'));
    });
  });
}
