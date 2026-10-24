import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/session_repository.dart';
import '../entities/ai_result_record.dart';
import '../entities/session_record.dart';
import '../entities/session_stats_record.dart';
import 'ai_inference_service.dart';

final aiInferenceServiceProvider = Provider<AiInferenceService>((ref) {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final service = AiInferenceService(repository: sessionRepo);
  service.initialize();
  return service;
});

class DashboardPatternSummary {
  const DashboardPatternSummary({
    required this.totalSessions,
    required this.typicalCount,
    required this.differentCount,
    required this.consistencyPercentage,
    required this.averageRecoveryDrop,
    required this.recentSessionsWithAi,
  });

  final int totalSessions;
  final int typicalCount;
  final int differentCount;
  final double consistencyPercentage;
  final double? averageRecoveryDrop;
  final List<SessionWithAi> recentSessionsWithAi;
}

class SessionWithAi {
  const SessionWithAi({
    required this.session,
    required this.stats,
    required this.aiResult,
  });

  final SessionRecord session;
  final SessionStatsRecord? stats;
  final AiResultRecord? aiResult;
}

final aiDashboardSummaryProvider = FutureProvider<DashboardPatternSummary>((
  ref,
) async {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final sessions = sessionRepo.getAllSessions();

  int typical = 0;
  int different = 0;
  final recoveryDrops = <double>[];
  final list = <SessionWithAi>[];

  for (final s in sessions) {
    final stats = sessionRepo.getStatsForSession(s.id);
    final ai = sessionRepo.getAiResultForSession(s.id);

    if (ai != null) {
      if (ai.label.toLowerCase().contains('typical')) {
        typical++;
      } else {
        different++;
      }
    }

    if (stats?.recoveryDrop != null) {
      recoveryDrops.add(stats!.recoveryDrop!);
    }

    list.add(SessionWithAi(session: s, stats: stats, aiResult: ai));
  }

  final totalAi = typical + different;
  final consistency = totalAi > 0 ? (typical / totalAi) * 100.0 : 100.0;
  final avgRecovery = recoveryDrops.isNotEmpty
      ? recoveryDrops.reduce((a, b) => a + b) / recoveryDrops.length
      : null;

  return DashboardPatternSummary(
    totalSessions: sessions.length,
    typicalCount: typical,
    differentCount: different,
    consistencyPercentage: consistency,
    averageRecoveryDrop: avgRecovery,
    recentSessionsWithAi: list,
  );
});

final sessionAiAnalysisProvider = FutureProvider.family<AiInferenceState, String>((
  ref,
  sessionId,
) async {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final aiService = ref.watch(aiInferenceServiceProvider);

  // Check if session exists
  final session = sessionRepo.getSessionById(sessionId);
  if (session == null) {
    return AiInferenceState.invalidInput('Session not found.');
  }

  // Check if AI result is already saved
  final existingAi = sessionRepo.getAiResultForSession(sessionId);
  final stats = sessionRepo.getStatsForSession(sessionId);

  if (existingAi != null && stats != null) {
    return AiInferenceState.success(
      AiInferenceResult(
        label: existingAi.label,
        explanation: existingAi.label == 'Typical pattern'
            ? 'Similar to your last rest sessions. A pattern label, not a health rating.'
            : 'Varied from your typical resting baseline pattern. A statistical pattern label, not a health rating.',
        comparisonText:
            'Evaluated with PulsePatch AI Insights v${existingAi.modelVersion}.',
        features: {
          'mean_hr': stats.meanHr,
          'std_hr': stats.stdHr,
          'start_hr': stats.startHr,
          'end_hr': stats.endHr,
          'recovery_drop': stats.recoveryDrop ?? (stats.startHr - stats.endHr),
        },
        scaledFeatures: {},
        modelVersion: existingAi.modelVersion,
        inferredAt: existingAi.createdAt,
      ),
    );
  }

  if (stats == null) {
    return AiInferenceState.insufficientData(
      'Session does not have computed statistics.',
    );
  }

  // Run analysis through inference service
  return await aiService.analyzeSession(
    sessionId: sessionId,
    features: {
      'mean_hr': stats.meanHr,
      'std_hr': stats.stdHr,
      'start_hr': stats.startHr,
      'end_hr': stats.endHr,
      'recovery_drop': stats.recoveryDrop,
    },
    validSampleCount: stats.validSampleCount,
    sessionType: session.type,
  );
});
