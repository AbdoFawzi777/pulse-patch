import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/entities/session_record.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/date_range_filter.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/session_tile.dart';
import '../../shared/widgets/status_chip.dart';
import '../device/heart_rate_source.dart';

class MeasurementHistoryScreen extends ConsumerStatefulWidget {
  const MeasurementHistoryScreen({
    super.key,
    required this.onBack,
    required this.onSelectSession,
    this.onOpenTrends,
    this.onOpenReports,
  });

  final VoidCallback onBack;
  final void Function(SessionRecord session) onSelectSession;
  final VoidCallback? onOpenTrends;
  final VoidCallback? onOpenReports;

  @override
  ConsumerState<MeasurementHistoryScreen> createState() =>
      _MeasurementHistoryScreenState();
}

class _MeasurementHistoryScreenState
    extends ConsumerState<MeasurementHistoryScreen> {
  DateRangeOption _dateFilter = DateRangeOption.week;
  SessionType? _protocolFilter; // null = all, rest, postActivity
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final sessionRepo = ref.watch(sessionRepositoryProvider);
    final bleSource = ref.watch(heartRateSourceProvider);

    final allSessions = sessionRepo.getAllSessions();

    // Filter by date range
    final now = DateTime.now();
    final filteredSessions = allSessions.where((s) {
      if (_dateFilter == DateRangeOption.day) {
        final isToday =
            s.startedAt.year == now.year &&
            s.startedAt.month == now.month &&
            s.startedAt.day == now.day;
        if (!isToday) return false;
      } else {
        // Week: past 7 days
        final diff = now.difference(s.startedAt).inDays;
        if (diff > 7) return false;
      }

      // Filter by protocol
      if (_protocolFilter != null && s.type != _protocolFilter) {
        return false;
      }

      // Filter by search query (timestamp or type)
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final typeStr = s.type.name.toLowerCase();
        final dateStr = s.startedAt.toIso8601String().toLowerCase();
        if (!typeStr.contains(q) && !dateStr.contains(q)) {
          return false;
        }
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        children: [
          // Background corner glows
          Positioned(
            top: -120,
            left: -120,
            width: 360,
            height: 360,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.bgGlowTopLeft.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -120,
            width: 360,
            height: 360,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.bgGlowBottomRight.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12.0),
                  // Top Header Row
                  Row(
                    children: [
                      CircleIconButton(
                        icon: Icons.chevron_left_rounded,
                        semanticLabel: 'Back',
                        onPressed: widget.onBack,
                      ),
                      const Expanded(
                        child: Text(
                          'History',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 22.0,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.onOpenTrends != null)
                            CircleIconButton(
                              icon: Icons.show_chart_rounded,
                              semanticLabel: 'Trends',
                              onPressed: widget.onOpenTrends,
                            ),
                          if (widget.onOpenReports != null) ...[
                            const SizedBox(width: 8.0),
                            CircleIconButton(
                              icon: Icons.description_outlined,
                              semanticLabel: 'Reports',
                              onPressed: widget.onOpenReports,
                            ),
                          ],
                          if (widget.onOpenTrends == null &&
                              widget.onOpenReports == null)
                            const SizedBox(width: 56.0),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18.0),
                  // Filter Bar matching History.png: Week vs Day + Sample data chip
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
                        label: bleSource.isSimulator
                            ? 'Sample data'
                            : 'Hardware',
                        variant: StatusChipVariant.sample,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  // Search & Protocol Filter Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 42.0,
                          padding: const EdgeInsets.symmetric(horizontal: 14.0),
                          decoration: BoxDecoration(
                            color: AppColors.cardBgNavy,
                            borderRadius: BorderRadius.circular(14.0),
                            border: Border.all(
                              color: AppColors.cardBorder,
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search_rounded,
                                color: AppColors.textMuted,
                                size: 18.0,
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: TextField(
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 14.0,
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Search sessions...',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14.0,
                                      color: AppColors.textMuted,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (val) =>
                                      setState(() => _searchQuery = val),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      // Protocol Toggle Dropdown / Chip
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_protocolFilter == null) {
                              _protocolFilter = SessionType.rest;
                            } else if (_protocolFilter == SessionType.rest) {
                              _protocolFilter = SessionType.postActivity;
                            } else {
                              _protocolFilter = null;
                            }
                          });
                        },
                        child: Container(
                          height: 42.0,
                          padding: const EdgeInsets.symmetric(horizontal: 14.0),
                          decoration: BoxDecoration(
                            color: _protocolFilter != null
                                ? AppColors.accentBlue.withValues(alpha: 0.2)
                                : AppColors.cardBgNavy,
                            borderRadius: BorderRadius.circular(14.0),
                            border: Border.all(
                              color: _protocolFilter != null
                                  ? AppColors.accentBlue
                                  : AppColors.cardBorder,
                              width: 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _protocolFilter == null
                                ? 'All'
                                : (_protocolFilter == SessionType.rest
                                      ? 'Rest'
                                      : 'Post-Activity'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.0,
                              fontWeight: FontWeight.w500,
                              color: _protocolFilter != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  // Session List
                  Expanded(
                    child: filteredSessions.isEmpty
                        ? const EmptyState(
                            title: 'No Measurements Found',
                            description:
                                'No optical pulse recordings match your current filter.',
                            icon: Icons.history_rounded,
                          )
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredSessions.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10.0),
                            itemBuilder: (context, index) {
                              final session = filteredSessions[index];
                              final stats = sessionRepo.getStatsForSession(
                                session.id,
                              );
                              final ai = sessionRepo.getAiResultForSession(
                                session.id,
                              );

                              final title = _formatDateTitle(session.startedAt);
                              final qualityLabel =
                                  session.qualitySummary == QualitySummary.good
                                  ? 'Good'
                                  : (session.qualitySummary ==
                                            QualitySummary.fair
                                        ? 'Fair'
                                        : 'Weak');
                              final patternLabel = ai?.label ?? 'typical';

                              return SessionTile(
                                title: title,
                                qualityText: qualityLabel,
                                patternText: patternLabel,
                                bpm: stats?.meanHr.round() ?? 74,
                                onTap: () => widget.onSelectSession(session),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTitle(DateTime dt) {
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(dt);
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today $timeStr';
    }
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayStr = days[dt.weekday - 1];
    return '$dayStr $timeStr';
  }
}
