import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/reminder_repository.dart';
import '../../domain/entities/reminder_record.dart';
import '../../domain/notifications/notification_service.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/pill_button.dart';

/// Screen managing scheduled measurement reminder prompts.
/// Derived screen #17 adhering strictly to design tokens.
class ReminderSettingsScreen extends ConsumerStatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  ConsumerState<ReminderSettingsScreen> createState() =>
      _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState
    extends ConsumerState<ReminderSettingsScreen> {
  List<ReminderRecord> _reminders = [];
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _loadReminders();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await ref
        .read(notificationServiceProvider.notifier)
        .checkPermission();
    if (mounted) {
      setState(() => _hasPermission = granted);
    }
  }

  void _loadReminders() {
    final repo = ref.read(reminderRepositoryProvider);
    final list = repo.getAllReminders();
    setState(() {
      _reminders = list;
      _isLoading = false;
    });
  }

  Future<void> _addNewReminder() async {
    final now = TimeOfDay.now();
    final pickedTime = await showTimePicker(context: context, initialTime: now);

    if (pickedTime != null) {
      final repo = ref.read(reminderRepositoryProvider);
      final newRecord = ReminderRecord(
        hour: pickedTime.hour,
        minute: pickedTime.minute,
        label: 'Pulse Check-In',
        isEnabled: true,
        daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
      );
      await repo.insertReminder(newRecord);
      _loadReminders();
    }
  }

  Future<void> _toggleReminder(ReminderRecord reminder, bool enabled) async {
    final repo = ref.read(reminderRepositoryProvider);
    final updated = reminder.copyWith(isEnabled: enabled);
    await repo.updateReminder(updated);
    _loadReminders();
  }

  Future<void> _deleteReminder(int id) async {
    final repo = ref.read(reminderRepositoryProvider);
    await repo.deleteReminder(id);
    _loadReminders();
  }

  @override
  Widget build(BuildContext context) {
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
                        'Reminder Settings',
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
                    icon: Icons.add_alarm_rounded,
                    onPressed: _addNewReminder,
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Disclaimer & Scope Card
                    Container(
                      padding: const EdgeInsets.all(18.0),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgNavy,
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(
                          color: AppColors.cardBorder,
                          width: 1.0,
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.accentCyan,
                                size: 22.0,
                              ),
                              SizedBox(width: 8.0),
                              Text(
                                'No Background Monitoring',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            'PulsePatch Lite does not run continuous background sensor monitoring. Reminders simply alert you to place the optical patch on your fingertip and manually take a timed session.',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.0,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16.0),

                    // Permission Status Card
                    if (!_hasPermission)
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A1657),
                          borderRadius: BorderRadius.circular(18.0),
                          border: Border.all(
                            color: AppColors.accentPurple,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.notifications_off_outlined,
                              color: Color(0xFFDDD6FE),
                              size: 24.0,
                            ),
                            const SizedBox(width: 12.0),
                            const Expanded(
                              child: Text(
                                'Notifications are disabled on this device.',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13.0,
                                  color: Color(0xFFDDD6FE),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await ref
                                    .read(notificationServiceProvider.notifier)
                                    .requestPermission();
                                _checkPermission();
                              },
                              child: const Text(
                                'Enable',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: AppColors.accentCyan,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Reminders List Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Scheduled Check-Ins',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        PillButton(
                          label: '+ Add',
                          style: PillButtonStyle.white,
                          onPressed: _addNewReminder,
                          width: 80.0,
                          height: 36.0,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12.0),

                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accentPurple,
                        ),
                      )
                    else if (_reminders.isEmpty)
                      const EmptyState(
                        title: 'No Reminders Scheduled',
                        description:
                            'Tap "+ Add" to create a daily reminder to take your resting pulse.',
                        icon: Icons.alarm_off_rounded,
                      )
                    else
                      ..._reminders.map(
                        (reminder) => _buildReminderTile(reminder),
                      ),

                    const SizedBox(height: 24.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderTile(ReminderRecord reminder) {
    final hourStr = reminder.hour.toString().padLeft(2, '0');
    final minStr = reminder.minute.toString().padLeft(2, '0');
    final timeStr = '$hourStr:$minStr';

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.cardBgNavy,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24.0,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  reminder.label,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.0,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: reminder.isEnabled,
            activeTrackColor: AppColors.accentPurple,
            activeThumbColor: AppColors.accentCyan,
            onChanged: (val) => _toggleReminder(reminder, val),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.textMuted,
              size: 20.0,
            ),
            onPressed: () {
              if (reminder.id != null) {
                _deleteReminder(reminder.id!);
              }
            },
          ),
        ],
      ),
    );
  }
}
