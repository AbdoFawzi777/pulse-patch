import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/pill_button.dart';
import '../bp/bp_monitoring_screen.dart';
import '../doctors/doctor_discovery_screen.dart';
import '../knowledge/medical_knowledge_assistant_screen.dart';
import '../reports/health_analytics_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/cloud_sync_screen.dart';

/// Health Services Hub screen uniting clinical and cloud services:
/// - Clinical PDF Reports & Export
/// - Blood Pressure Research & Calibration
/// - Native Google Maps Nearby Healthcare Discovery
/// - Evidence-based AI Knowledge Assistant (Gemini & Local RAG)
/// - Firebase Cloud Sync & Backup
/// - Longitudinal Health Analytics
/// - Emergency Escalation Guidance (ESC/ISH 2023 & Egyptian Ambulance 123)
class HealthServicesHubScreen extends StatelessWidget {
  const HealthServicesHubScreen({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return DesignCanvasScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleIconButton(
                type: CircleIconType.back,
                semanticLabel: 'Back',
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    isRtl ? 'الخدمات الطبية والرعاية' : 'Health Services',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22.0,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 56.0),
            ],
          ),
          const SizedBox(height: 16.0),

          // Scrollable Service Cards
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // 1. Clinical PDF Reports Card
                MetricCard(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: AppColors.accentCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: AppColors.accentCyan,
                              size: 24.0,
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isRtl ? 'التقارير الطبية وتصدير PDF' : 'Clinical Reports & PDF',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  isRtl
                                      ? 'توليد تقرير طبي متكامل غير تشخيصي بالعربية والإنجليزية'
                                      : 'Generate offline clinical PDF reports in EN & AR',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.0,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14.0),
                      PillButton(
                        label: isRtl ? 'عرض وتصدير التقارير' : 'Open Reports Center',
                        style: PillButtonStyle.white,
                        width: double.infinity,
                        height: 44.0,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReportsScreen(
                                onBack: () => Navigator.of(context).maybePop(),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),

                // 2. Blood Pressure Research & Calibration
                MetricCard(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: const Icon(
                              Icons.speed_rounded,
                              color: Color(0xFFF59E0B),
                              size: 24.0,
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      isRtl ? 'ضغط الدم ومعايرة الذراع' : 'Blood Pressure (Research)',
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 6.0),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
                                      decoration: BoxDecoration(
                                        color: const Color(0x33F59E0B),
                                        borderRadius: BorderRadius.circular(4.0),
                                      ),
                                      child: const Text(
                                        'Experimental',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 9.0,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFFFBBF24),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  isRtl
                                      ? 'نموذج بحثي تجريبي لتقدير ضغط الدم ومعايرة الحزام'
                                      : 'PPG morphological estimation & cuff calibration',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.0,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14.0),
                      PillButton(
                        label: isRtl ? 'إدارة ضغط الدم والمعايرة' : 'BP Monitoring & Calibration',
                        style: PillButtonStyle.dark,
                        width: double.infinity,
                        height: 44.0,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BpMonitoringScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),

                // 3. Native Google Maps Healthcare Discovery
                MetricCard(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: const Icon(
                              Icons.map_rounded,
                              color: Color(0xFF10B981),
                              size: 24.0,
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isRtl ? 'استكشاف الرعاية عبر خريطة OpenStreetMap' : 'OpenStreetMap Healthcare Discovery',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  isRtl
                                      ? 'خريطة تفاعلية للقلب والمستشفيات مع فلاتر المسافة والملاحة'
                                      : 'Interactive dark map with cardiology, hospitals & GPS',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.0,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14.0),
                      PillButton(
                        label: isRtl ? 'فتح الخريطة التفاعلية' : 'Open Healthcare Map',
                        style: PillButtonStyle.dark,
                        width: double.infinity,
                        height: 44.0,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DoctorDiscoveryScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),

                // 4. Evidence-based AI Assistant (Gemini & Local RAG)
                MetricCard(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: AppColors.accentCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: const Icon(
                              Icons.psychology_rounded,
                              color: AppColors.accentCyan,
                              size: 24.0,
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isRtl ? 'المساعد الطبي بالذكاء الاصطناعي' : 'Medical Reference AI Assistant',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  isRtl
                                      ? 'استشارات معتمدة بأدلة WHO و ESC مع دعم Gemini 3.8 Flash'
                                      : 'Evidence-based guidance (WHO, ESC) with Gemini 3.8 Flash',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.0,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14.0),
                      PillButton(
                        label: isRtl ? 'بدء محادثة طبية' : 'Consult Health AI',
                        style: PillButtonStyle.dark,
                        width: double.infinity,
                        height: 44.0,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MedicalKnowledgeAssistantScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),

                // 5. Firebase Cloud Sync & Backup
                MetricCard(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: const Icon(
                              Icons.cloud_sync_rounded,
                              color: Color(0xFF6366F1),
                              size: 24.0,
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isRtl ? 'المزامنة والنسخ السحابي' : 'Firebase Cloud Sync & Backup',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  isRtl
                                      ? 'مزامنة آمنة مع Firestore مع حفظ البيانات غير المتصلة أولاً'
                                      : 'Secure Firestore sync with offline-first SQLite queue',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.0,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14.0),
                      PillButton(
                        label: isRtl ? 'إدارة المزامنة السحابية' : 'Manage Cloud Sync',
                        style: PillButtonStyle.dark,
                        width: double.infinity,
                        height: 44.0,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CloudSyncScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),

                // 6. Longitudinal Health Analytics
                MetricCard(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: AppColors.accentBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: const Icon(
                              Icons.analytics_rounded,
                              color: AppColors.accentBlue,
                              size: 24.0,
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isRtl ? 'التحليلات الصحية التراكمية' : 'Health Analytics & Baseline',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  isRtl
                                      ? 'معدلات النبض، الأكسجين، وخط الأساس لـ 7 و 30 يوماً'
                                      : 'Resting HR, SpO2 trends & baseline stability',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.0,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14.0),
                      PillButton(
                        label: isRtl ? 'عرض التحليلات المتقدمة' : 'View Detailed Analytics',
                        style: PillButtonStyle.dark,
                        width: double.infinity,
                        height: 44.0,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const HealthAnalyticsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),

                // 7. Emergency Safety Banner
                Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.emergency_rounded,
                        color: Color(0xFFEF4444),
                        size: 22.0,
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isRtl ? 'طوارئ الإسعاف الطبي (مصر): 123' : 'Emergency Medical Assistance: 123',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.0,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFCA5A5),
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              isRtl
                                  ? 'تطبيق PulsePatch Lite أداة تعليمية بحثية وليس جهازاً طبياً معتمداً. في حال وجود ألم بالصدر أو ضيق تنفس أو أعراض حرجة، اتصل بالطوارئ فوراً.'
                                  : 'PulsePatch Lite is an educational wellness prototype and not a certified diagnostic device. Call emergency services immediately for acute chest pain or shortness of breath.',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.0,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
