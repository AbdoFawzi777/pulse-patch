import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/analytics/health_analytics_service.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/metric_card.dart';
import '../knowledge/medical_knowledge_assistant_screen.dart';

class HealthAnalyticsScreen extends ConsumerStatefulWidget {
  const HealthAnalyticsScreen({super.key});

  @override
  ConsumerState<HealthAnalyticsScreen> createState() => _HealthAnalyticsScreenState();
}

class _HealthAnalyticsScreenState extends ConsumerState<HealthAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsService = ref.watch(healthAnalyticsServiceProvider);
    final report = analyticsService.computeReport();
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return DesignCanvasScaffold(
      child: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                children: [
                  CircleIconButton(
                    type: CircleIconType.back,
                    semanticLabel: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Text(
                      isRtl ? 'التحليلات الصحية التراكمية' : 'Health Analytics & Baseline',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu_book_outlined, color: AppColors.accentCyan),
                    tooltip: isRtl ? 'المساعد الطبي المرجعي' : 'Ask Medical Reference AI',
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

            // Tab Bar
            TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.accentCyan,
              labelColor: AppColors.accentCyan,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 13),
              tabs: [
                Tab(text: isRtl ? 'نبض القلب' : 'Heart Rate'),
                Tab(text: isRtl ? 'الأكسجين (SpO₂)' : 'Oxygen (SpO₂)'),
                Tab(text: isRtl ? 'ضغط الدم' : 'Blood Pressure'),
                Tab(text: isRtl ? 'المستوى المرجعي' : 'Personal Baseline'),
              ],
            ),

            const SizedBox(height: 12.0),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHeartRateTab(report, isRtl),
                  _buildSpo2Tab(report, isRtl),
                  _buildBloodPressureTab(report, isRtl),
                  _buildBaselineTab(report, isRtl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeartRateTab(LongitudinalHealthReport report, bool isRtl) {
    final hr = report.heartRateSummary;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MetricCard(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isRtl ? 'متوسط النبض (7 أيام)' : '7-Day Heart Rate Average',
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 13.0, color: AppColors.textMuted),
                    ),
                    _buildTrendChip(hr.trend, isRtl),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  hr.sevenDayAverage != null ? '${hr.sevenDayAverage!.toStringAsFixed(0)} BPM' : '-- BPM',
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 32.0, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  hr.insufficientDataReason ?? (isRtl ? 'محسوب من قياسات حقيقية مؤكدة' : 'Calculated from verified user telemetry'),
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 12.0, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14.0),

          // Daily Trend Chart
          _buildDailyPointsChart(
            title: isRtl ? 'النبض اليومي عبر الأسبوع' : 'Daily Heart Rate Trend (Past 7 Days)',
            points: report.heartRateDailyPoints,
            unit: 'BPM',
            color: AppColors.accentBlue,
            isRtl: isRtl,
          ),
        ],
      ),
    );
  }

  Widget _buildSpo2Tab(LongitudinalHealthReport report, bool isRtl) {
    final spo2 = report.spo2Summary;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MetricCard(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isRtl ? 'متوسط نسبة الأكسجين (7 أيام)' : '7-Day SpO₂ Average',
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 13.0, color: AppColors.textMuted),
                    ),
                    _buildTrendChip(spo2.trend, isRtl),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  spo2.sevenDayAverage != null ? '${spo2.sevenDayAverage!.toStringAsFixed(1)}%' : '--%',
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 32.0, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  spo2.insufficientDataReason ?? (isRtl ? 'مستخلص من مستشعر MAX30102 ثنائي الأطوال الموجية' : 'Extracted from MAX30102 dual-wavelength telemetry'),
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 12.0, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14.0),

          _buildDailyPointsChart(
            title: isRtl ? 'نسبة الأكسجين اليومية' : 'Daily SpO₂ Trend (Past 7 Days)',
            points: report.spo2DailyPoints,
            unit: '%',
            color: AppColors.accentCyan,
            isRtl: isRtl,
          ),
        ],
      ),
    );
  }

  Widget _buildBloodPressureTab(LongitudinalHealthReport report, bool isRtl) {
    final bp = report.bpAnalytics;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Cuff Reference Section
          Text(
            isRtl ? 'قراءات حزام الضغط المرجعية (Cuff Sphygmomanometer)' : 'Reference Cuff Blood Pressure',
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 14.0, fontWeight: FontWeight.w600, color: AppColors.accentCyan),
          ),
          const SizedBox(height: 8.0),
          MetricCard(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isRtl ? 'آخر قراءة معتمدة' : 'Latest Cuff Measurement',
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 13.0, color: AppColors.textMuted),
                    ),
                    _buildTrendChip(bp.cuffTrend, isRtl),
                  ],
                ),
                const SizedBox(height: 6.0),
                Text(
                  bp.hasCuffData
                      ? '${bp.latestCuffSbp!.toStringAsFixed(0)} / ${bp.latestCuffDbp!.toStringAsFixed(0)} mmHg'
                      : '-- / -- mmHg',
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 28.0, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4.0),
                Text(
                  isRtl ? 'عدد القراءات المسجلة: ${bp.cuffCount}' : 'Total Reference Measurements: ${bp.cuffCount}',
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 12.0, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),

          // 2. Experimental PPG Model Estimates Section (STRICTLY SEGREGATED)
          Row(
            children: [
              Text(
                isRtl ? 'تقديرات النموذج التجريبي (AI Model)' : 'Experimental AI Estimates (PPG)',
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 14.0, fontWeight: FontWeight.w600, color: Color(0xFFFFB74D)),
              ),
              const SizedBox(width: 8.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: const Text('RESEARCH ONLY', style: TextStyle(fontFamily: 'Outfit', fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFFB74D))),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          MetricCard(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRtl ? 'آخر تقدير استدلالي للنموذج' : 'Latest PPG Model Estimation',
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 13.0, color: AppColors.textMuted),
                ),
                const SizedBox(height: 6.0),
                Text(
                  bp.hasEstimateData
                      ? '${bp.latestEstimateSbp!.toStringAsFixed(0)} / ${bp.latestEstimateDbp!.toStringAsFixed(0)} mmHg'
                      : '-- / -- mmHg',
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 26.0, fontWeight: FontWeight.w700, color: Color(0xFFFFB74D)),
                ),
                const SizedBox(height: 4.0),
                Text(
                  isRtl
                      ? '⚠️ غير مخصص للاستخدام التشخيصي أو اتخاذ قرارات علاجية.'
                      : '⚠️ Research-grade estimation only. Not for clinical diagnosis or medication adjustments.',
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 11.0, color: Color(0xFFFFB74D)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaselineTab(LongitudinalHealthReport report, bool isRtl) {
    final hr = report.heartRateSummary;
    final spo2 = report.spo2Summary;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MetricCard(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRtl ? 'ملخص خط الأساس الفردي' : 'Personal Established Baseline',
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 16.0, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12.0),
                _buildBaselineRow(
                  label: isRtl ? 'خط الأساس للنبض:' : 'Heart Rate Baseline:',
                  value: hr.baselineAverage != null ? '${hr.baselineAverage!.toStringAsFixed(0)} BPM' : '--',
                  isReliable: hr.isReliable,
                  count: hr.measurementCount,
                  isRtl: isRtl,
                ),
                const Divider(color: Color(0xFF1B2A66), height: 20.0),
                _buildBaselineRow(
                  label: isRtl ? 'خط الأساس للأكسجين:' : 'Oxygen (SpO₂) Baseline:',
                  value: spo2.baselineAverage != null ? '${spo2.baselineAverage!.toStringAsFixed(1)}%' : '--',
                  isReliable: spo2.isReliable,
                  count: spo2.measurementCount,
                  isRtl: isRtl,
                ),
                const Divider(color: Color(0xFF1B2A66), height: 20.0),
                _buildBaselineRow(
                  label: isRtl ? 'إجمالي الجلسات المعتمدة:' : 'Total Verified Sessions:',
                  value: '${report.totalSessionsRecorded}',
                  isReliable: report.totalSessionsRecorded >= 3,
                  count: report.totalSessionsRecorded,
                  isRtl: isRtl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaselineRow({
    required String label,
    required String value,
    required bool isReliable,
    required int count,
    required bool isRtl,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13.0, color: AppColors.textSecondary)),
            Text(
              isReliable
                  ? (isRtl ? 'خط أساس موثوق ($count قياسات)' : 'Established ($count measurements)')
                  : (isRtl ? 'غير كافٍ ($count/3 قياسات)' : 'Insufficient ($count/3 needed)'),
              style: TextStyle(fontFamily: 'Outfit', fontSize: 11.0, color: isReliable ? AppColors.accentCyan : AppColors.textMuted),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 18.0, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildDailyPointsChart({
    required String title,
    required List<DailyTrendPoint> points,
    required String unit,
    required Color color,
    required bool isRtl,
  }) {
    return MetricCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13.0, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: points.map((p) {
              final hasVal = p.value != null;
              final heightRatio = hasVal ? (p.value! / (unit == '%' ? 100.0 : 140.0)).clamp(0.2, 1.0) : 0.05;
              return Column(
                children: [
                  Text(
                    hasVal ? p.value!.toStringAsFixed(0) : '-',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 10.0, color: hasVal ? AppColors.textPrimary : AppColors.textMuted),
                  ),
                  const SizedBox(height: 4.0),
                  Container(
                    width: 14.0,
                    height: 80.0 * heightRatio,
                    decoration: BoxDecoration(
                      color: hasVal ? color : Colors.white12,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(p.label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11.0, color: AppColors.textMuted)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChip(MetricTrendDirection trend, bool isRtl) {
    IconData icon;
    Color color;
    String label;

    switch (trend) {
      case MetricTrendDirection.rising:
        icon = Icons.trending_up;
        color = const Color(0xFFFFB74D);
        label = isRtl ? 'تصاعدي' : 'Rising';
        break;
      case MetricTrendDirection.falling:
        icon = Icons.trending_down;
        color = AppColors.accentCyan;
        label = isRtl ? 'تنازلي' : 'Falling';
        break;
      case MetricTrendDirection.stable:
        icon = Icons.trending_flat;
        color = const Color(0xFF66BB6A);
        label = isRtl ? 'مستقر' : 'Stable';
        break;
      case MetricTrendDirection.insufficientData:
        icon = Icons.hourglass_empty;
        color = AppColors.textMuted;
        label = isRtl ? 'بيانات غير كافية' : 'Pending Data';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14.0),
          const SizedBox(width: 4.0),
          Text(label, style: TextStyle(fontFamily: 'Outfit', fontSize: 11.0, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}
