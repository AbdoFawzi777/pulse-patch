import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/notifications/notification_event.dart';
import '../../domain/notifications/notification_service.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/empty_state.dart';

/// Screen displaying real event logs and user alerts.
/// Derived screen #16 adhering strictly to design tokens.
class NotificationsCenterScreen extends ConsumerStatefulWidget {
  const NotificationsCenterScreen({super.key});

  @override
  ConsumerState<NotificationsCenterScreen> createState() =>
      _NotificationsCenterScreenState();
}

class _NotificationsCenterScreenState
    extends ConsumerState<NotificationsCenterScreen> {
  NotificationCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(notificationServiceProvider);
    final filteredEvents = _selectedCategory == null
        ? events
        : events.where((e) => e.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  CircleIconButton(
                    icon: Icons.delete_sweep_rounded,
                    onPressed: events.isNotEmpty
                        ? () => ref
                              .read(notificationServiceProvider.notifier)
                              .clearAll()
                        : null,
                  ),
                ],
              ),
            ),

            // Category Filter Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  _buildCategoryChip('All', null),
                  const SizedBox(width: 8.0),
                  _buildCategoryChip(
                    'Measurements',
                    NotificationCategory.measurement,
                  ),
                  const SizedBox(width: 8.0),
                  _buildCategoryChip('Device', NotificationCategory.device),
                  const SizedBox(width: 8.0),
                  _buildCategoryChip('System', NotificationCategory.system),
                  const SizedBox(width: 8.0),
                  _buildCategoryChip(
                    'Reminders',
                    NotificationCategory.reminder,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8.0),

            // Event List
            Expanded(
              child: filteredEvents.isEmpty
                  ? const Center(
                      child: EmptyState(
                        title: 'No Notifications',
                        description:
                            'Only verified telemetry and system events will appear here.',
                        icon: Icons.notifications_none_rounded,
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 8.0,
                      ),
                      itemCount: filteredEvents.length,
                      itemBuilder: (context, index) {
                        final event = filteredEvents[index];
                        return _buildEventTile(event);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, NotificationCategory? category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentPurple : AppColors.cardBgNavy,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: isSelected ? AppColors.accentPurple : AppColors.cardBorder,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13.0,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEventTile(NotificationEvent event) {
    IconData icon;
    Color iconColor;

    switch (event.category) {
      case NotificationCategory.measurement:
        icon = Icons.favorite_rounded;
        iconColor = AppColors.accentCyan;
        break;
      case NotificationCategory.device:
        icon = Icons.bluetooth_rounded;
        iconColor = AppColors.accentPurple;
        break;
      case NotificationCategory.system:
        icon = Icons.psychology_rounded;
        iconColor = AppColors.accentMagenta;
        break;
      case NotificationCategory.reminder:
        icon = Icons.alarm_rounded;
        iconColor = const Color(0xFFF59E0B);
        break;
    }

    final timeStr = DateFormat('MMM d, HH:mm').format(event.timestamp);

    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(notificationServiceProvider.notifier).removeEvent(event.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        margin: const EdgeInsets.only(bottom: 10.0),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(18.0),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.cardBgNavy,
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(color: AppColors.cardBorder, width: 1.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20.0),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.0,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    event.message,
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
    );
  }
}
