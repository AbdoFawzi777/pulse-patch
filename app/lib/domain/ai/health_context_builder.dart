import '../../data/repositories/session_repository.dart';
import '../../data/repositories/user_profile_repository.dart';
import 'ai_provider.dart';

/// Builds sanitized, non-PII health context for AI reasoning
class HealthContextBuilder {
  const HealthContextBuilder({
    this.sessionRepository,
    this.userProfileRepository,
  });

  final SessionRepository? sessionRepository;
  final UserProfileRepository? userProfileRepository;

  Future<AiPromptRequest> buildRequest({
    required String query,
    required String language,
  }) async {
    double? recentHr;
    double? recentSpo2;
    double? estimatedSbp;
    double? estimatedDbp;
    int? userAge;
    String? userGender;

    if (sessionRepository != null) {
      try {
        final sessions = sessionRepository!.getAllSessions();
        if (sessions.isNotEmpty) {
          final s = sessions.first;
          final stats = sessionRepository!.getStatsForSession(s.id);
          if (stats != null) {
            recentHr = stats.meanHr > 0 ? stats.meanHr : null;
            recentSpo2 = stats.avgSpo2 != null && stats.avgSpo2! > 0 ? stats.avgSpo2 : null;
          }
        }
      } catch (_) {
        // Degrade gracefully if database read fails
      }
    }

    if (userProfileRepository != null) {
      try {
        final profile = await userProfileRepository!.getProfile();
        if (profile != null) {
          userAge = profile.age;
          userGender = profile.gender;
          estimatedSbp = profile.baselineSbp;
          estimatedDbp = profile.baselineDbp;
        }
      } catch (_) {
        // Degrade gracefully
      }
    }

    return AiPromptRequest(
      query: query,
      language: language,
      recentHr: recentHr,
      recentSpo2: recentSpo2,
      estimatedSbp: estimatedSbp,
      estimatedDbp: estimatedDbp,
      userAge: userAge,
      userGender: userGender,
    );
  }
}
