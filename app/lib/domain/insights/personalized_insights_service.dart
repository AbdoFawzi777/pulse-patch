import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../analytics/health_analytics_service.dart';

enum InsightCategory {
  heartRate,
  oxygen,
  consistency,
  baseline,
  bloodPressure,
}

class PersonalizedInsight {
  const PersonalizedInsight({
    required this.id,
    required this.category,
    required this.title,
    required this.titleAr,
    required this.observation,
    required this.observationAr,
    required this.recommendation,
    required this.recommendationAr,
    required this.sampleCount,
    required this.comparisonPeriod,
    required this.isInformational,
    required this.evidenceNote,
  });

  final String id;
  final InsightCategory category;
  final String title;
  final String titleAr;
  final String observation;
  final String observationAr;
  final String recommendation;
  final String recommendationAr;
  final int sampleCount;
  final String comparisonPeriod;
  final bool isInformational;
  final String evidenceNote;
}

final personalizedInsightsServiceProvider = Provider<PersonalizedInsightsService>((ref) {
  final analyticsService = ref.watch(healthAnalyticsServiceProvider);
  final profileRepo = ref.watch(userProfileRepositoryProvider);
  return PersonalizedInsightsService(analytics: analyticsService, profileRepo: profileRepo);
});

class PersonalizedInsightsService {
  PersonalizedInsightsService({required this.analytics, required this.profileRepo});

  final HealthAnalyticsService analytics;
  final UserProfileRepository profileRepo;

  Future<List<PersonalizedInsight>> generateInsights({DateTime? referenceTime}) async {
    final report = analytics.computeReport(referenceTime: referenceTime);
    final profile = await profileRepo.getProfile();
    final insights = <PersonalizedInsight>[];

    // 1. Consistency & Habit Insight
    if (report.totalSessionsRecorded == 0) {
      insights.add(
        const PersonalizedInsight(
          id: 'insight-start-monitoring',
          category: InsightCategory.consistency,
          title: 'Start Establishing Your Health Baseline',
          titleAr: 'ابدأ في تسجيل خط الأساس الصحي',
          observation: 'No recorded telemetry sessions yet. Personal trends require at least 3 valid sessions.',
          observationAr: 'لم يتم تسجيل جلسات قياس بعد. يتطلب خط الأساس 3 جلسات صالحة على الأقل.',
          recommendation: 'Perform your first 2-minute resting session in a quiet seated position with your PulsePatch sensor.',
          recommendationAr: 'سجّل أول جلسة قياس استرخاء لمدة دقيقتين في وضع الجلوس الهادئ باستخدام مستشعر PulsePatch.',
          sampleCount: 0,
          comparisonPeriod: 'Initial baseline setup',
          isInformational: true,
          evidenceNote: 'AHA recommended practice for resting photoplethysmogram monitoring.',
        ),
      );
      return insights;
    } else if (report.totalSessionsRecorded < 3) {
      insights.add(
        PersonalizedInsight(
          id: 'insight-insufficient-history',
          category: InsightCategory.consistency,
          title: 'Baseline In Progress',
          titleAr: 'بناء خط الأساس قيد التقدم',
          observation: '${report.totalSessionsRecorded} of 3 sessions recorded. Trends will become active after 3 sessions.',
          observationAr: 'تم تسجيل ${report.totalSessionsRecorded} من 3 جلسات مطلوبة. ستتفعّل التحليلات التراكمية بعد الجلسة الثالثة.',
          recommendation: 'Take another measurement today to establish a statistically reliable resting baseline.',
          recommendationAr: 'قم بأخذ قياس إضافي اليوم لإنشاء خط أساس موثوق إحصائياً لنبض القلب.',
          sampleCount: report.totalSessionsRecorded,
          comparisonPeriod: 'Baseline establishment',
          isInformational: true,
          evidenceNote: 'Minimum 3 independent rest recordings needed for robust central tendency calculation.',
        ),
      );
    } else {
      // 2. Resting Heart Rate Trend Insight
      final hr = report.heartRateSummary;
      if (hr.isReliable && hr.sevenDayAverage != null && hr.baselineAverage != null) {
        final diff = hr.sevenDayAverage! - hr.baselineAverage!;
        final diffAbs = diff.abs().toStringAsFixed(1);

        if (diff > 5.0) {
          insights.add(
            PersonalizedInsight(
              id: 'insight-hr-elevated',
              category: InsightCategory.heartRate,
              title: 'Elevated 7-Day Resting Heart Rate',
              titleAr: 'ارتفاع نسبي في متوسط نبض القلب',
              observation: 'Your 7-day average resting heart rate (${hr.sevenDayAverage!.toStringAsFixed(0)} BPM) is $diffAbs BPM above your baseline (${hr.baselineAverage!.toStringAsFixed(0)} BPM).',
              observationAr: 'متوسط نبض القلب لـ 7 أيام (${hr.sevenDayAverage!.toStringAsFixed(0)} نبضة/د) أعلى بمقدار $diffAbs نبضة/د عن خط الأساس (${hr.baselineAverage!.toStringAsFixed(0)} نبضة/د).',
              recommendation: 'Common causes include poor sleep, mild dehydration, stress, or caffeine. Prioritize adequate rest and hydration.',
              recommendationAr: 'من الأسباب الشائعة قلة النوم، التوتر، أو الإكثار من المنبهات. احرص على شرب الماء وأخذ قسط كافٍ من النوم.',
              sampleCount: hr.measurementCount,
              comparisonPeriod: 'Past 7 days vs Personal Baseline',
              isInformational: true,
              evidenceNote: 'Physiological variation standard: resting HR fluctuations under 10 BPM are typically benign lifestyle responses.',
            ),
          );
        } else {
          insights.add(
            PersonalizedInsight(
              id: 'insight-hr-stable',
              category: InsightCategory.heartRate,
              title: 'Stable Resting Heart Rate',
              titleAr: 'استقرار نبض القلب الاسترخائي',
              observation: 'Your 7-day resting pulse (${hr.sevenDayAverage!.toStringAsFixed(0)} BPM) is consistent with your personal baseline (${hr.baselineAverage!.toStringAsFixed(0)} BPM).',
              observationAr: 'متوسط نبضك الاسترخائي (${hr.sevenDayAverage!.toStringAsFixed(0)} نبضة/د) متطابق ومستقر مع خط الأساس (${hr.baselineAverage!.toStringAsFixed(0)} نبضة/د).',
              recommendation: 'Continue maintaining regular physical activity and recording resting sessions at the same time of day.',
              recommendationAr: 'واصل الحفاظ على النشاط البدني المنتظم مع أخذ القياسات في نفس الوقت يومياً.',
              sampleCount: hr.measurementCount,
              comparisonPeriod: 'Past 7 days vs Personal Baseline',
              isInformational: true,
              evidenceNote: 'Consistent resting heart rate indicates autonomic nervous system stability.',
            ),
          );
        }
      }

      // 3. SpO2 Oxygenation Stability Insight
      final spo2 = report.spo2Summary;
      if (spo2.isReliable && spo2.sevenDayAverage != null) {
        if (spo2.sevenDayAverage! < 95.0) {
          insights.add(
            PersonalizedInsight(
              id: 'insight-spo2-low',
              category: InsightCategory.oxygen,
              title: 'Mild Oxygen Saturation Variation',
              titleAr: 'انخفاض نسبي في نسبة الأكسجين',
              observation: '7-day average SpO₂ is ${spo2.sevenDayAverage!.toStringAsFixed(1)}%. Readings below 95% warrant observation.',
              observationAr: 'متوسط الأكسجين لـ 7 أيام هو ${spo2.sevenDayAverage!.toStringAsFixed(1)}%. القراءات دون 95% تستدعي المتابعة.',
              recommendation: 'Ensure clean sensor placement without movement. If you experience shortness of breath or persistent low readings, consult a physician.',
              recommendationAr: 'تأكد من ثبات وضع الإصبع على المستشعر. في حال شعرت بضيق في التنفس أو استمرار الانخفاض، استشر طبيباً.',
              sampleCount: spo2.measurementCount,
              comparisonPeriod: 'Past 7 days',
              isInformational: false,
              evidenceNote: 'WHO clinical threshold: normal sea-level pulse oximetry ranges between 95% and 100%.',
            ),
          );
        } else {
          insights.add(
            PersonalizedInsight(
              id: 'insight-spo2-optimal',
              category: InsightCategory.oxygen,
              title: 'Optimal Blood Oxygenation',
              titleAr: 'نسبة أكسجين ممتازة ومثالية',
              observation: '7-day average SpO₂ is ${spo2.sevenDayAverage!.toStringAsFixed(1)}%, well within the healthy clinical range (95–100%).',
              observationAr: 'متوسط الأكسجين هو ${spo2.sevenDayAverage!.toStringAsFixed(1)}%، وهو ضمن النطاق الصحي الطبيعي تماماً (95–100%).',
              recommendation: 'Keep up healthy breathing habits and regular aerobic conditioning.',
              recommendationAr: 'استمر في العادات الصحية والتنفس السليم والتمارين الهوائية المنتظمة.',
              sampleCount: spo2.measurementCount,
              comparisonPeriod: 'Past 7 days',
              isInformational: true,
              evidenceNote: 'WHO standard for non-hypoxemic resting blood oxygen saturation.',
            ),
          );
        }
      }

      // 4. Blood Pressure & Demographic Context
      final bp = report.bpAnalytics;
      if (bp.hasCuffData && bp.latestCuffSbp != null && bp.latestCuffDbp != null) {
        final sbp = bp.latestCuffSbp!;
        final dbp = bp.latestCuffDbp!;

        if (sbp >= 140 || dbp >= 90) {
          insights.add(
            PersonalizedInsight(
              id: 'insight-bp-cuff-elevated',
              category: InsightCategory.bloodPressure,
              title: 'Elevated Cuff Blood Pressure Recorded',
              titleAr: 'تسجيل قراءة ضغط دم مرتفعة بالحزام',
              observation: 'Latest cuff measurement is ${sbp.toStringAsFixed(0)}/${dbp.toStringAsFixed(0)} mmHg (Stage 1 or 2 Hypertension threshold).',
              observationAr: 'آخر قراءة حزام مسجلة هي ${sbp.toStringAsFixed(0)}/${dbp.toStringAsFixed(0)} مم زئبق (نطاق مرحلة ارتفاع ضغط الدم).',
              recommendation: 'Log repeat measurements over several days and share these records with your healthcare provider for evaluation.',
              recommendationAr: 'قم بتسجيل قراءات متكررة لعدة أيام وشارك هذا السجل مع طبيبك المعالج للتقييم السريري.',
              sampleCount: bp.cuffCount,
              comparisonPeriod: 'Latest reference measurement',
              isInformational: false,
              evidenceNote: 'ESC/ISH 2023 Clinical Practice Guidelines for Management of Arterial Hypertension.',
            ),
          );
        }
      }

      // 5. Anthropometric Insight (BMI & Age context)
      if (profile != null && profile.age >= 18 && profile.bmi > 0) {
        if (profile.bmi >= 25.0) {
          insights.add(
            PersonalizedInsight(
              id: 'insight-bmi-lifestyle',
              category: InsightCategory.baseline,
              title: 'Cardiovascular Health & Weight Management',
              titleAr: 'صحة القلب والوزن الصحي',
              observation: 'Calculated adult BMI is ${profile.bmi} kg/m² (${profile.bmiCategory}).',
              observationAr: 'مؤشر كتلة الجسم هو ${profile.bmi} كجم/م² (${profile.bmiCategoryArabic}).',
              recommendation: 'Adopting a balanced Mediterranean or low-sodium dietary pattern paired with regular walking supports resting cardiovascular health.',
              recommendationAr: 'اتباع نمط غذائي متوازن قليل الصوديوم مع المشي اليومي يعزز صحة القلب والأوعية الدموية.',
              sampleCount: 1,
              comparisonPeriod: 'Profile anthropometrics',
              isInformational: true,
              evidenceNote: 'WHO guidance on weight management and long-term cardiovascular risk reduction.',
            ),
          );
        }
      }
    }

    return insights;
  }
}
