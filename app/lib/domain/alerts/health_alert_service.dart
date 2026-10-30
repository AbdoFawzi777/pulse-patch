import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/drift/app_database.dart';
import '../../data/repositories/session_repository.dart';
import '../entities/session_record.dart';
import '../entities/session_stats_record.dart';
import '../notifications/notification_event.dart';
import '../notifications/notification_service.dart';

enum AlertSeverity {
  info,
  moderate,
  urgent,
}

class HealthAlertRecord {
  const HealthAlertRecord({
    required this.id,
    this.sessionId,
    required this.severity,
    required this.title,
    required this.titleAr,
    required this.message,
    required this.messageAr,
    required this.createdAt,
    this.isDismissed = false,
  });

  final String id;
  final String? sessionId;
  final AlertSeverity severity;
  final String title;
  final String titleAr;
  final String message;
  final String messageAr;
  final DateTime createdAt;
  final bool isDismissed;

  Map<String, dynamic> toMap() => {
    'id': id,
    'session_id': sessionId,
    'severity': severity.name,
    'title': title,
    'title_ar': titleAr,
    'message': message,
    'message_ar': messageAr,
    'created_at': createdAt.millisecondsSinceEpoch,
    'is_dismissed': isDismissed ? 1 : 0,
  };

  factory HealthAlertRecord.fromMap(Map<String, dynamic> map) {
    return HealthAlertRecord(
      id: map['id'] as String,
      sessionId: map['session_id'] as String?,
      severity: AlertSeverity.values.firstWhere(
        (s) => s.name == map['severity'],
        orElse: () => AlertSeverity.info,
      ),
      title: map['title'] as String,
      titleAr: map['title_ar'] as String,
      message: map['message'] as String,
      messageAr: map['message_ar'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      isDismissed: (map['is_dismissed'] as int) == 1,
    );
  }
}

final healthAlertServiceProvider = Provider<HealthAlertService>((ref) {
  try {
    final db = ref.watch(appDatabaseProvider);
    final notificationNotifier = ref.watch(notificationServiceProvider.notifier);
    return HealthAlertService(db: db, notificationNotifier: notificationNotifier);
  } catch (_) {
    return HealthAlertService(db: AppDatabase.inMemory(), notificationNotifier: null);
  }
});

class HealthAlertService {
  HealthAlertService({required this.db, required this.notificationNotifier});

  final AppDatabase db;
  final NotificationServiceNotifier? notificationNotifier;

  static const Duration alertCooldown = Duration(minutes: 15);

  List<HealthAlertRecord> getActiveAlerts() {
    final rows = db.rawDb.select(
      'SELECT * FROM health_alerts WHERE is_dismissed = 0 ORDER BY created_at DESC;',
    );
    return rows.map((r) => HealthAlertRecord.fromMap(r)).toList();
  }

  void dismissAlert(String alertId) {
    db.rawDb.execute(
      'UPDATE health_alerts SET is_dismissed = 1 WHERE id = ?;',
      [alertId],
    );
  }

  /// Evaluates physiological stats from a completed rest session.
  Future<HealthAlertRecord?> evaluateSessionStats({
    required SessionRecord session,
    required SessionStatsRecord stats,
  }) async {
    // Only analyze rest sessions for baseline anomalies
    if (session.type != SessionType.rest) return null;

    final now = DateTime.now();

    // 1. Severe Hypoxemia Check (SpO2 < 90%)
    if (stats.avgSpo2 != null && stats.avgSpo2! > 0 && stats.avgSpo2! < 90.0) {
      return _createAlert(
        id: 'alert-spo2-${session.id}',
        sessionId: session.id,
        severity: AlertSeverity.urgent,
        title: 'Low Oxygen Saturation (<90%)',
        titleAr: 'انخفاض حاد في نسبة الأكسجين (<90%)',
        message: 'Average blood oxygen saturation (${stats.avgSpo2!.toStringAsFixed(1)}%) is markedly low. If experiencing shortness of breath or dizziness, call emergency services (123).',
        messageAr: 'متوسط الأكسجين (${stats.avgSpo2!.toStringAsFixed(1)}%) منخفض جداً. في حال الشعور بضيق تنفس أو دوار اتصل بالإسعاف (123) فوراً.',
        createdAt: now,
      );
    }

    // 2. Resting Tachycardia Check (mean HR > 100 BPM)
    if (stats.meanHr > 100.0) {
      return _createAlert(
        id: 'alert-tachy-${session.id}',
        sessionId: session.id,
        severity: AlertSeverity.moderate,
        title: 'Elevated Resting Pulse (>100 BPM)',
        titleAr: 'ارتفاع في نبض القلب الاسترخائي (>100 نبضة/د)',
        message: 'Resting heart rate (${stats.meanHr.round()} BPM) exceeds 100 BPM. Ensure you are well rested and adequately hydrated.',
        messageAr: 'متوسط النبض الاسترخائي (${stats.meanHr.round()} نبضة/د) يتجاوز 100 نبضة بالدقيقة. احرص على الراحة وشرب كمية كافية من الماء.',
        createdAt: now,
      );
    }

    // 3. Resting Bradycardia Check (mean HR < 50 BPM)
    if (stats.meanHr < 50.0 && stats.meanHr > 30.0) {
      return _createAlert(
        id: 'alert-brady-${session.id}',
        sessionId: session.id,
        severity: AlertSeverity.info,
        title: 'Low Resting Pulse (<50 BPM)',
        titleAr: 'نبض استرخائي منخفض (<50 نبضة/د)',
        message: 'Resting heart rate (${stats.meanHr.round()} BPM) is below 50 BPM. Common in well-conditioned endurance athletes; observe for lightheadedness.',
        messageAr: 'النبض الاسترخائي (${stats.meanHr.round()} نبضة/د) دون 50 نبضة. هذا شائع لدى الرياضيين ذوي اللياقة البدنية العالية.',
        createdAt: now,
      );
    }

    return null;
  }

  /// Evaluates a REAL cuff measurement entered by the user.
  Future<HealthAlertRecord?> evaluateCuffMeasurement({
    required double sbp,
    required double dbp,
  }) async {
    final now = DateTime.now();

    if (sbp >= 180.0 || dbp >= 120.0) {
      return _createAlert(
        id: 'alert-cuff-crisis-${now.millisecondsSinceEpoch}',
        severity: AlertSeverity.urgent,
        title: 'Hypertensive Crisis Cuff Reading (≥180/120)',
        titleAr: 'قراءة حزام ضغط شديدة الارتفاع (≥180/120)',
        message: 'Cuff measurement (${sbp.round()}/${dbp.round()} mmHg) is markedly elevated. Rest 5 minutes and repeat. If experiencing chest pain, visual changes, or acute headache, call 123 (Isʿaaf).',
        messageAr: 'قراءة الحزام (${sbp.round()}/${dbp.round()} مم زئبق) شديدة الارتفاع. استرخ 5 دقائق وأعد القياس. في حال وجود ألم بالصدر أو أعراض عصبية اتصل بالإسعاف (123) فوراً.',
        createdAt: now,
      );
    } else if (sbp >= 140.0 || dbp >= 90.0) {
      return _createAlert(
        id: 'alert-cuff-stage2-${now.millisecondsSinceEpoch}',
        severity: AlertSeverity.moderate,
        title: 'Elevated Cuff Reading (≥140/90)',
        titleAr: 'قراءة حزام ضغط مرتفعة (≥140/90)',
        message: 'Cuff measurement (${sbp.round()}/${dbp.round()} mmHg) meets hypertension criteria. Log subsequent readings and discuss with your physician.',
        messageAr: 'القراءة (${sbp.round()}/${dbp.round()} مم زئبق) تقع في نطاق ارتفاع ضغط الدم. واصل التسجيل واستشر طبيبك المعالج.',
        createdAt: now,
      );
    }

    return null;
  }

  /// STRICT SAFETY GATE: AI research model estimates CANNOT generate emergency clinical alerts.
  void evaluateModelEstimateSafetyGate({required double sbp, required double dbp}) {
    // Intentionally no-op. Experimental model estimates are strictly isolated
    // from clinical alert generation to prevent false emergency escalations.
  }

  HealthAlertRecord? _createAlert({
    required String id,
    String? sessionId,
    required AlertSeverity severity,
    required String title,
    required String titleAr,
    required String message,
    required String messageAr,
    required DateTime createdAt,
  }) {
    // Check cooldown / duplicate
    final existing = db.rawDb.select(
      'SELECT created_at FROM health_alerts WHERE title = ? AND is_dismissed = 0 ORDER BY created_at DESC LIMIT 1;',
      [title],
    );
    if (existing.isNotEmpty) {
      final lastMs = existing.first['created_at'] as int;
      final diff = createdAt.difference(DateTime.fromMillisecondsSinceEpoch(lastMs));
      if (diff < alertCooldown) {
        return null; // Cooldown active, suppress duplicate
      }
    }

    final record = HealthAlertRecord(
      id: id,
      sessionId: sessionId,
      severity: severity,
      title: title,
      titleAr: titleAr,
      message: message,
      messageAr: messageAr,
      createdAt: createdAt,
    );

    // Save to database
    db.rawDb.execute(
      '''
      INSERT OR REPLACE INTO health_alerts (
        id, session_id, severity, title, title_ar, message, message_ar, created_at, is_dismissed
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
      ''',
      [
        record.id,
        record.sessionId,
        record.severity.name,
        record.title,
        record.titleAr,
        record.message,
        record.messageAr,
        record.createdAt.millisecondsSinceEpoch,
        0,
      ],
    );

    // Post to notification service notifier
    try {
      notificationNotifier?.addEvent(
        NotificationEvent(
          id: record.id,
          title: record.title,
          message: record.message,
          timestamp: record.createdAt,
          category: NotificationCategory.measurement,
          sessionId: record.sessionId,
        ),
      );
    } catch (_) {}

    return record;
  }
}
