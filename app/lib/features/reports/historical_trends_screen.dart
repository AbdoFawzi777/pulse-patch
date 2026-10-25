import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/entities/session_record.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/date_range_filter.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/status_chip.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/trend_chart.dart';
import '../device/heart_rate_source.dart';

class HistoricalTrendsScreen extends ConsumerStatefulWidget {
  const HistoricalTrendsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  ConsumerState<HistoricalTrendsScreen> createState() =>
      _HistoricalTrendsScreenState();
}

class _HistoricalTrendsScreenState
    extends ConsumerState<HistoricalTrendsScreen> {
  DateRangeOption _dateFilter = DateRangeOption.week;
  SessionType? _protocolFilter; // null = all, rest, postActivity

  @override
  Widget build(BuildContext context) {
    final sessionRepo = ref.watch(sessionRepositoryProvider);
    final bleSource = ref.watch(heartRateSourceProvider);
    final allSessions = sessionRepo.getAllSessions();

    final now = DateTime.now();

    // Generate daily bins for past 7 days (or 24 hourly bins for past day)
    final List<String> labels = [];
    final List<double?> values = [];

    if (_dateFilter == DateRangeOption.week) {
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final dayFormat = DateFormat('E').format(day);
        labels.add(dayFormat);

        final daySessions = allSessions.where((s) {
          final isSameDay =
              s.startedAt.year == day.year &&
              s.startedAt.month == day.month &&
              s.startedAt.day == day.day;
          if (!isSameDay) return false;
          if (_protocolFilter != null && s.type != _protocolFilter) {
            return false;
          }
          return true;
        }).toList();

        if (daySessions.isEmpty) {
          values.add(null); // Explicit gap for unrecorded days
        } else {
          final hrList = daySessions
              .map((s) => sessionRepo.getStatsForSession(s.id)?.meanHr)
              .whereType<double>()
              .toList();
          if (hrList.isNotEmpty) {
            final avg = hrList.reduce((a, b) => a + b) / hrList.length;
            values.add(avg);
          } else {
            values.add(null);
          }
        }
      }
    } else {
      // Day: 6 bins across 24h
      const hours = [0, 4, 8, 12, 16, 20];
      for (final h in hours) {
        labels.add('${h}h');
        final binSessions = allSessions.where((s) {
          final isToday =
              s.startedAt.year == now.year &&
              s.startedAt.month == now.month &&
              s.startedAt.day == now.day;
          if (!isToday) return false;
          if (_protocolFilter != null && s.type != _protocolFilter) {
            return false;
          }
          return s.startedAt.hour >= h && s.startedAt.hour < h + 4;
        }).toList();

        if (binSessions.isEmpty) {
          values.add(null);
        } else {
          final hrList = binSessions
              .map((s) => sessionRepo.getStatsForSession(s.id)?.meanHr)
              .whereType<double>()
              .toList();
          if (hrList.isNotEmpty) {
            values.add(hrList.reduce((a, b) => a + b) / hrList.length);
          } else {
            values.add(null);
          }
        }
      }
    }

    final validValues = values.whereType<double>().toList();
    final periodAvg = validValues.isNotEmpty
        ? (validValues.reduce((a, b) => a + b) / validValues.length).round()
        : null;
    final periodMin = validValues.isNotEmpty
        ? validValues.reduce((a, b) => a < b ? a : b).round()
        : null;
    final periodMax = validValues.isNotEmpty
        ? validValues.reduce((a, b) => a > b ? a : b).round()
        : null;

    return DesignCanvasScaffold(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
                    'Historical Trends',
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
            // Filters: Date range & Sample data tag
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 6.0,
              children: [
                DateRangeFilter(
                  selectedOption: _dateFilter,
                  onChanged: (sel) => setState(() => _dateFilter = sel),
                ),
                StatusChip(
                  label: bleSource.isSimulator ? 'Sample data' : 'Hardware',
                  variant: StatusChipVariant.sample,
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            // Protocol Selector Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _FilterPill(
                    label: 'All Protocols',
                    isSelected: _protocolFilter == null,
                    onTap: () => setState(() => _protocolFilter = null),
                  ),
                  const SizedBox(width: 8.0),
                  _FilterPill(
                    label: 'Resting',
                    isSelected: _protocolFilter == SessionType.rest,
                    onTap: () =>
                        setState(() => _protocolFilter = SessionType.rest),
                  ),
                  const SizedBox(width: 8.0),
                  _FilterPill(
                    label: 'Post-Activity',
                    isSelected: _protocolFilter == SessionType.postActivity,
                    onTap: () => setState(
                      () => _protocolFilter = SessionType.postActivity,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18.0),
            // Trend Chart Card
            MetricCard(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 4.0,
                    children: [
                      const Text(
                        'Optical Pulse Rate Trend',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (periodAvg != null)
                        Text(
                          'Avg $periodAvg BPM',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.0,
                            fontWeight: FontWeight.w400,
                            color: AppColors.accentCyan,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  TrendChart(
                    values: values,
                    labels: labels,
                    height: 140.0,
                    lineColor: AppColors.accentBlue,
                  ),
                  const SizedBox(height: 10.0),
                  const Center(
                    child: Text(
                      'Missing days show gaps · no fabricated data',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.0,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            // Summary Statistics Grid
            Row(
              children: [
                Expanded(
                  child: _StatSummaryBox(
                    title: 'Lowest recorded',
                    value: periodMin != null ? '$periodMin BPM' : 'N/A',
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: _StatSummaryBox(
                    title: 'Highest recorded',
                    value: periodMax != null ? '$periodMax BPM' : 'N/A',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14.0),
            // Written Educational Summary
            MetricCard(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.accentCyan,
                    size: 20.0,
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Observation Summary',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          validValues.isNotEmpty
                              ? 'Based on ${validValues.length} recorded time bins, heart rate averaged $periodAvg BPM across the selected interval. '
                                    'All measurements were recorded locally on your device.'
                              : 'Insufficient recordings in this date range. Record more sessions to view longitudinal trends.',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.0,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12.0),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
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
            fontSize: 12.0,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.bgBase : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _StatSummaryBox extends StatelessWidget {
  const _StatSummaryBox({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return MetricCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.0,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6.0),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20.0,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
