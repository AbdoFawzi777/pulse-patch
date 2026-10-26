import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/preferences_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/entities/session_record.dart';
import '../../shared/widgets/bottom_circle_nav.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../insights/ai_model_info_screen.dart';
import '../reports/historical_trends_screen.dart';
import '../reports/recovery_analysis_screen.dart';
import '../reports/reports_screen.dart';
import 'about_screen.dart';
import 'privacy_data_management_screen.dart';
import 'profile_preferences_screen.dart';
import 'reminder_settings_screen.dart';

/// Screen managing application telemetry configurations, BLE, and deep links.
/// Derived screen #19 adhering strictly to design tokens.
class ApplicationSettingsScreen extends ConsumerStatefulWidget {
  const ApplicationSettingsScreen({super.key, this.onOpenBleConnect});

  final VoidCallback? onOpenBleConnect;

  @override
  ConsumerState<ApplicationSettingsScreen> createState() =>
      _ApplicationSettingsScreenState();
}

class _ApplicationSettingsScreenState
    extends ConsumerState<ApplicationSettingsScreen> {
  bool _autoReconnect = true;
  bool _useSmoothing = true;
  int _selectedDuration = 60;

  @override
  void initState() {
    super.initState();
    final prefsRepo = ref.read(preferencesRepositoryProvider);
    _autoReconnect = prefsRepo.autoReconnectBle;
    _useSmoothing = prefsRepo.useSmoothing;
    _selectedDuration = prefsRepo.measurementDurationSeconds;
  }

  Future<void> _updateAutoReconnect(bool val) async {
    setState(() => _autoReconnect = val);
    await ref.read(preferencesRepositoryProvider).setAutoReconnectBle(val);
  }

  Future<void> _updateSmoothing(bool val) async {
    setState(() => _useSmoothing = val);
    await ref.read(preferencesRepositoryProvider).setUseSmoothing(val);
  }

  Future<void> _updateDuration(int seconds) async {
    setState(() => _selectedDuration = seconds);
    await ref
        .read(preferencesRepositoryProvider)
        .setMeasurementDurationSeconds(seconds);
  }

  @override
  Widget build(BuildContext context) {
    return DesignCanvasScaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: BottomCircleNav(
          currentIndex: 3,
          onTap: (index) {
            if (index != 3) {
              Navigator.of(context).maybePop();
            }
          },
        ),
      ),
      child: Column(
        children: [
          // Top Bar
          Row(
            children: [
              CircleIconButton(
                type: CircleIconType.back,
                semanticLabel: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22.0,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              CircleIconButton(
                type: CircleIconType.profile,
                semanticLabel: 'Profile',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfilePreferencesScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bluetooth Connection Card
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment(-0.6, -0.8),
                        end: Alignment(0.6, 0.8),
                        colors: [Color(0xFF0F2160), Color(0xFF08122E)],
                      ),
                      borderRadius: BorderRadius.circular(22.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.bluetooth_rounded,
                              color: AppColors.accentCyan,
                              size: 22.0,
                            ),
                            SizedBox(width: 10.0),
                            Text(
                              'Hardware & Bluetooth',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18.0,
                                fontWeight: FontWeight.w300,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Auto-Reconnect',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2.0),
                                  Text(
                                    'Automatically reconnect when sensor is in range',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 12.0,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _autoReconnect,
                              activeTrackColor: AppColors.accentPurple,
                              activeThumbColor: AppColors.accentCyan,
                              onChanged: _updateAutoReconnect,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14.0),

                  // Measurement Duration Selector Card
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment(-0.6, -0.8),
                        end: Alignment(0.6, 0.8),
                        colors: [Color(0xFF0F2160), Color(0xFF08122E)],
                      ),
                      borderRadius: BorderRadius.circular(22.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Default Measurement Duration',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18.0,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        const Text(
                          'Timed session duration for optical pulse capture.',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14.0),
                        Row(
                          children: [30, 60, 90, 120].map((sec) {
                            final isSelected = _selectedDuration == sec;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: GestureDetector(
                                  onTap: () => _updateDuration(sec),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFFFFFFF)
                                          : const Color(0xFF0B1840),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${sec}s',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 13.0,
                                          fontWeight: isSelected
                                              ? FontWeight.w500
                                              : FontWeight.w400,
                                          color: isSelected
                                              ? const Color(0xFF0B1840)
                                              : const Color(0xFFC9D0F5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '5-Sample Median Smoothing',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2.0),
                                  Text(
                                    'Suppresses motion spikes without altering recorded raw telemetry',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 12.0,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _useSmoothing,
                              activeTrackColor: AppColors.accentPurple,
                              activeThumbColor: AppColors.accentCyan,
                              onChanged: _updateSmoothing,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14.0),

                  // Quick Nav Links Card
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment(-0.6, -0.8),
                        end: Alignment(0.6, 0.8),
                        colors: [Color(0xFF0F2160), Color(0xFF08122E)],
                      ),
                      borderRadius: BorderRadius.circular(22.0),
                    ),
                    child: Column(
                      children: [
                        _buildNavTile(
                          icon: Icons.picture_as_pdf_rounded,
                          title: 'Pulse Summary Reports',
                          subtitle: 'Generate offline PDF reports and exports',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReportsScreen(
                                  onBack: () =>
                                      Navigator.of(context).maybePop(),
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(color: Color(0xFF1B2A66), height: 1.0),
                        _buildNavTile(
                          icon: Icons.trending_up_rounded,
                          title: 'Historical Trends',
                          subtitle:
                              'Daily & weekly pulse patterns with gap analysis',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => HistoricalTrendsScreen(
                                  onBack: () =>
                                      Navigator.of(context).maybePop(),
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(color: Color(0xFF1B2A66), height: 1.0),
                        _buildNavTile(
                          icon: Icons.restore_rounded,
                          title: 'Recovery Analysis',
                          subtitle:
                              '60s rate recovery drop & personal baseline',
                          onTap: () {
                            final repo = ref.read(sessionRepositoryProvider);
                            final sessions = repo.getAllSessions();
                            if (sessions.isEmpty) return;
                            final targetSession = sessions.firstWhere(
                              (s) => s.type == SessionType.postActivity,
                              orElse: () => sessions.first,
                            );
                            final stats = repo.getStatsForSession(
                              targetSession.id,
                            );
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RecoveryAnalysisScreen(
                                  session: targetSession,
                                  stats: stats,
                                  onBack: () =>
                                      Navigator.of(context).maybePop(),
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(color: Color(0xFF1B2A66), height: 1.0),
                        _buildNavTile(
                          icon: Icons.lock_outline_rounded,
                          title: 'Privacy & Data Management',
                          subtitle: '100% offline SQLite storage, erase data',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const PrivacyDataManagementScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(color: Color(0xFF1B2A66), height: 1.0),
                        _buildNavTile(
                          icon: Icons.alarm_rounded,
                          title: 'Reminder Settings',
                          subtitle: 'Daily check-in schedules',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ReminderSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(color: Color(0xFF1B2A66), height: 1.0),
                        _buildNavTile(
                          icon: Icons.psychology_rounded,
                          title: 'AI Model Information',
                          subtitle:
                              'On-device neural network model card & metrics',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AiModelInfoScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(color: Color(0xFF1B2A66), height: 1.0),
                        _buildNavTile(
                          icon: Icons.info_outline_rounded,
                          title: 'About PulsePatch Lite',
                          subtitle: 'Graduation project, firmware & licenses',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AboutScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: const Color(0xFF070F2B),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Icon(icon, color: AppColors.accentCyan, size: 20.0),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 15.0,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12.0,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }
}
