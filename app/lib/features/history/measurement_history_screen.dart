import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/entities/session_record.dart';
import '../../shared/widgets/bottom_circle_nav.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/pill_button.dart';
import '../../shared/widgets/status_chip.dart';
import '../device/heart_rate_source.dart';

enum HistoryFilter { week, day }

/// History screen matching History.dc.html and History.png exactly.
class MeasurementHistoryScreen extends ConsumerStatefulWidget {
  const MeasurementHistoryScreen({
    super.key,
    required this.onBack,
    this.onSelectSession,
    this.onSelectTab,
    this.currentNavIndex = 1,
    this.showBottomNav = true,
  });

  final VoidCallback onBack;
  final void Function(SessionRecord session)? onSelectSession;
  final ValueChanged<int>? onSelectTab;
  final int currentNavIndex;
  final bool showBottomNav;

  @override
  ConsumerState<MeasurementHistoryScreen> createState() =>
      _MeasurementHistoryScreenState();
}

class _MeasurementHistoryScreenState
    extends ConsumerState<MeasurementHistoryScreen> {
  HistoryFilter _filter = HistoryFilter.week;

  static const List<
      ({String dateStr, String quality, String pattern, int bpm})>
  _defaultSessions = [
    (
      dateStr: 'Today 18:05',
      quality: 'Good',
      pattern: 'typical',
      bpm: 74,
    ),
    (
      dateStr: 'Sun 09:30',
      quality: 'Good',
      pattern: 'typical',
      bpm: 71,
    ),
    (
      dateStr: 'Fri 20:12',
      quality: 'Fair',
      pattern: 'typical',
      bpm: 82,
    ),
    (
      dateStr: 'Thu 07:45',
      quality: 'Good',
      pattern: 'typical',
      bpm: 68,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final sessionRepo = ref.watch(sessionRepositoryProvider);
    final bleSource = ref.watch(heartRateSourceProvider);
    final allSessions = sessionRepo.getAllSessions();

    return DesignCanvasScaffold(
      bottomNavigationBar: widget.showBottomNav
          ? BottomCircleNav(
              currentIndex: widget.currentNavIndex,
              onTap: widget.onSelectTab ?? (_) {},
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row (.r)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleIconButton(
                type: CircleIconType.back,
                semanticLabel: 'Back',
                onPressed: widget.onBack,
              ),
              const Text(
                'History',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 22.0,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textPrimary,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 56.0),
            ],
          ),

          // Filter Row (.w + .w + .tg)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            child: Row(
              children: [
                PillButton(
                  label: 'Week',
                  style: _filter == HistoryFilter.week
                      ? PillButtonStyle.white
                      : PillButtonStyle.dark,
                  onPressed: () => setState(() => _filter = HistoryFilter.week),
                ),
                const SizedBox(width: 8.0),
                PillButton(
                  label: 'Day',
                  style: _filter == HistoryFilter.day
                      ? PillButtonStyle.white
                      : PillButtonStyle.dark,
                  onPressed: () => setState(() => _filter = HistoryFilter.day),
                ),
                const Spacer(),
                StatusChip(
                  label: bleSource.isSimulator ? 'Sample data' : 'Hardware',
                ),
              ],
            ),
          ),

          // 4 Session Cards
          Expanded(
            child: allSessions.isNotEmpty
                ? ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: allSessions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10.0),
                    itemBuilder: (context, index) {
                      final s = allSessions[index];
                      final stats = sessionRepo.getStatsForSession(s.id);
                      final ai = sessionRepo.getAiResultForSession(s.id);
                      final bpm = stats?.meanHr.round() ?? 74;
                      final quality = s.qualitySummary.name;
                      final pattern = ai?.label ?? 'typical';
                      final dateLabel = _formatDate(s.startedAt);

                      return _buildSessionCard(
                        dateStr: dateLabel,
                        quality: quality,
                        pattern: pattern,
                        bpm: bpm,
                        onTap: () => widget.onSelectSession?.call(s),
                      );
                    },
                  )
                : ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _defaultSessions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10.0),
                    itemBuilder: (context, index) {
                      final item = _defaultSessions[index];
                      return _buildSessionCard(
                        dateStr: item.dateStr,
                        quality: item.quality,
                        pattern: item.pattern,
                        bpm: item.bpm,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard({
    required String dateStr,
    required String quality,
    required String pattern,
    required int bpm,
    VoidCallback? onTap,
  }) {
    return MetricCard(
      padding: const EdgeInsets.all(16.0),
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18.0,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Quality: $quality · Pattern: $pattern',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.0,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textMuted,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$bpm',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 40.0,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textPrimary,
                  height: 1.0,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 4.0),
              const Text(
                'BPM',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.0,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textMuted,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final day = days[dt.weekday - 1];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$day $h:$m';
  }
}
