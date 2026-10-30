import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/entities/session_record.dart';
import '../../domain/entities/session_stats_record.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/error_banner.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/pill_button.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/status_chip.dart';
import '../device/heart_rate_source.dart';
import 'pdf_report_generator.dart';

enum ReportDateRange { daily, past7Days, past30Days, yearly, allTime }

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportDateRange _selectedRange = ReportDateRange.past7Days;
  bool _isGeneratingPdf = false;
  String? _exportError;

  @override
  Widget build(BuildContext context) {
    final sessionRepo = ref.watch(sessionRepositoryProvider);
    final bleSource = ref.watch(heartRateSourceProvider);
    final allSessions = sessionRepo.getAllSessions();

    final now = DateTime.now();
    final DateTime startDate;
    switch (_selectedRange) {
      case ReportDateRange.daily:
        startDate = now.subtract(const Duration(hours: 24));
        break;
      case ReportDateRange.past7Days:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case ReportDateRange.past30Days:
        startDate = now.subtract(const Duration(days: 30));
        break;
      case ReportDateRange.yearly:
        startDate = now.subtract(const Duration(days: 365));
        break;
      case ReportDateRange.allTime:
        startDate = DateTime(2020);
        break;
    }

    final eligibleSessions = allSessions
        .where((s) => s.startedAt.isAfter(startDate))
        .toList();

    final reportItems = eligibleSessions.map((s) {
      final stats = sessionRepo.getStatsForSession(s.id);
      final ai = sessionRepo.getAiResultForSession(s.id);
      return SessionReportData(session: s, stats: stats, aiPattern: ai?.label);
    }).toList();

    final validStats = reportItems
        .map((i) => i.stats)
        .whereType<SessionStatsRecord>()
        .toList();

    final meanHrAvg = validStats.isNotEmpty
        ? (validStats.map((s) => s.meanHr).reduce((a, b) => a + b) /
                  validStats.length)
              .round()
        : null;

    final restItems = reportItems
        .where((i) => i.session.type == SessionType.rest && i.stats != null)
        .toList();
    final postItems = reportItems
        .where(
          (i) => i.session.type == SessionType.postActivity && i.stats != null,
        )
        .toList();

    final restAvg = restItems.isNotEmpty
        ? (restItems.map((i) => i.stats!.meanHr).reduce((a, b) => a + b) /
                  restItems.length)
              .round()
        : null;

    final postAvg = postItems.isNotEmpty
        ? (postItems.map((i) => i.stats!.meanHr).reduce((a, b) => a + b) /
                  postItems.length)
              .round()
        : null;

    return DesignCanvasScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              CircleIconButton(
                type: CircleIconType.back,
                semanticLabel: 'Back',
                onPressed: widget.onBack,
              ),
              const Expanded(
                child: Text(
                  'Biomonitoring Reports',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22.0,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 56.0),
            ],
          ),
          const SizedBox(height: 16.0),

          // Date range selector buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _RangeButton(
                  label: 'Daily',
                  isSelected: _selectedRange == ReportDateRange.daily,
                  onTap: () => setState(
                    () => _selectedRange = ReportDateRange.daily,
                  ),
                ),
                const SizedBox(width: 8.0),
                _RangeButton(
                  label: '7 Days',
                  isSelected: _selectedRange == ReportDateRange.past7Days,
                  onTap: () => setState(
                    () => _selectedRange = ReportDateRange.past7Days,
                  ),
                ),
                const SizedBox(width: 8.0),
                _RangeButton(
                  label: '30 Days',
                  isSelected: _selectedRange == ReportDateRange.past30Days,
                  onTap: () => setState(
                    () => _selectedRange = ReportDateRange.past30Days,
                  ),
                ),
                const SizedBox(width: 8.0),
                _RangeButton(
                  label: 'Yearly',
                  isSelected: _selectedRange == ReportDateRange.yearly,
                  onTap: () => setState(
                    () => _selectedRange = ReportDateRange.yearly,
                  ),
                ),
                const SizedBox(width: 8.0),
                _RangeButton(
                  label: 'All Time',
                  isSelected: _selectedRange == ReportDateRange.allTime,
                  onTap: () =>
                      setState(() => _selectedRange = ReportDateRange.allTime),
                ),
                const SizedBox(width: 14.0),
                StatusChip(
                  label: bleSource.isSimulator ? 'Sample data' : 'Hardware',
                  variant: StatusChipVariant.sample,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14.0),

          if (_exportError != null) ...[
            ErrorBanner(
              message: _exportError!,
              actionLabel: 'Retry',
              onAction: () => _generateAndSharePdf(reportItems, startDate, now),
            ),
            const SizedBox(height: 12.0),
          ],

          // Content scroll
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // Summary metrics card
                MetricCard(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Eligible Session Summary',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14.0),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryStat(
                              label: 'Total Sessions',
                              value: '${eligibleSessions.length}',
                            ),
                          ),
                          Expanded(
                            child: _SummaryStat(
                              label: 'Overall Mean',
                              value: meanHrAvg != null
                                  ? '$meanHrAvg BPM'
                                  : 'N/A',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryStat(
                              label: 'Rest Mean',
                              value: restAvg != null ? '$restAvg BPM' : 'N/A',
                            ),
                          ),
                          Expanded(
                            child: _SummaryStat(
                              label: 'Post-Activity Mean',
                              value: postAvg != null ? '$postAvg BPM' : 'N/A',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14.0),

                // Separation of Origin Notice Card
                MetricCard(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Data Transparency Declaration',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      _OriginLine(
                        category: 'Measured values',
                        description:
                            'Raw optical PPG peak intervals from MAX30102 sensor.',
                      ),
                      SizedBox(height: 4.0),
                      _OriginLine(
                        category: 'Calculated summaries',
                        description:
                            'Mean, median start/end HR, sample std_hr, recovery_drop.',
                      ),
                      SizedBox(height: 4.0),
                      _OriginLine(
                        category: 'Model output',
                        description:
                            'On-device neural network pattern label (Typical / Different).',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14.0),

                // Non-diagnostic prototype banner
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: AppColors.accentMagenta.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: AppColors.accentMagenta.withValues(alpha: 0.3),
                      width: 1.0,
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.accentMagenta,
                        size: 20.0,
                      ),
                      SizedBox(width: 10.0),
                      Expanded(
                        child: Text(
                          'PulsePatch Lite is an educational research prototype. '
                          'Measurements and AI pattern classifications are strictly non-diagnostic '
                          'and must not be used for medical decisions.',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.0,
                            color: AppColors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),

                // Action button: PDF Export & Share
                PillButton(
                  label: _isGeneratingPdf
                      ? 'Generating PDF...'
                      : 'Export & Share PDF Report',
                  style: PillButtonStyle.white,
                  width: double.infinity,
                  height: 52.0,
                  icon: Icons.picture_as_pdf_rounded,
                  onPressed: _isGeneratingPdf
                      ? null
                      : () => _generateAndSharePdf(reportItems, startDate, now),
                ),
                const SizedBox(height: 10.0),
                PillButton(
                  label: 'Export for Training (CSV)',
                  style: PillButtonStyle.dark,
                  width: double.infinity,
                  height: 52.0,
                  icon: Icons.model_training_rounded,
                  onPressed: () => _exportTrainingCsv(sessionRepo),
                ),
                const SizedBox(height: 24.0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportTrainingCsv(SessionRepository repo) async {
    final csvData = repo.exportTrainingCsv(anonymousSubjectId: 'VOL_01');
    await SharePlus.instance.share(
      ShareParams(text: csvData, subject: 'PulsePatch Lite Training Dataset'),
    );
  }

  Future<void> _generateAndSharePdf(
    List<SessionReportData> items,
    DateTime start,
    DateTime end,
  ) async {
    setState(() {
      _isGeneratingPdf = true;
      _exportError = null;
    });

    try {
      final pdfBytes = await PdfReportGenerator.generate(
        userName: 'PulsePatch User',
        startDate: start,
        endDate: end,
        items: items,
      );

      final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'PulsePatch_Lite_Report_$dateStr.pdf',
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _exportError = 'Failed to generate PDF: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }
}

class _RangeButton extends StatelessWidget {
  const _RangeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : AppColors.cardBgNavy,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: isSelected ? Colors.white : AppColors.cardBorder,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13.0,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.bgBase : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12.0,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _OriginLine extends StatelessWidget {
  const _OriginLine({required this.category, required this.description});

  final String category;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• $category: ',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            color: AppColors.accentCyan,
          ),
        ),
        Expanded(
          child: Text(
            description,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.0,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
