import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/preferences_repository.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/pill_button.dart';
import '../bp/bp_monitoring_screen.dart';
import '../doctors/doctor_discovery_screen.dart';
import '../knowledge/medical_knowledge_assistant_screen.dart';
import '../profile/user_profile_screen.dart';
import '../reports/health_analytics_screen.dart';
import '../reports/reports_screen.dart';
import 'application_settings_screen.dart';

/// Screen managing user profile and UI display preferences.
/// Derived screen #18 adhering strictly to design tokens.
class ProfilePreferencesScreen extends ConsumerStatefulWidget {
  const ProfilePreferencesScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  ConsumerState<ProfilePreferencesScreen> createState() =>
      _ProfilePreferencesScreenState();
}

class _ProfilePreferencesScreenState
    extends ConsumerState<ProfilePreferencesScreen> {
  late TextEditingController _nameController;
  bool _useBpm = true;
  bool _isDarkTheme = true;
  String _selectedLocale = 'en';

  @override
  void initState() {
    super.initState();
    final prefsRepo = ref.read(preferencesRepositoryProvider);
    _nameController = TextEditingController(text: prefsRepo.userName);
    _useBpm = prefsRepo.useBpmUnits;
    _isDarkTheme = prefsRepo.isDarkTheme;
    _selectedLocale = prefsRepo.selectedLocale;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    final prefsRepo = ref.read(preferencesRepositoryProvider);
    await prefsRepo.setUserName(_nameController.text.trim());
    await prefsRepo.setUseBpmUnits(_useBpm);
    await prefsRepo.setDarkTheme(_isDarkTheme);
    await ref.read(localeProvider.notifier).setLocale(_selectedLocale);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preferences saved locally.',
            style: TextStyle(fontFamily: 'Outfit'),
          ),
          backgroundColor: Color(0xFF0F2160),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesignCanvasScaffold(
      child: Column(
        children: [
          // Top Bar
          Row(
            children: [
              CircleIconButton(
                type: CircleIconType.back,
                semanticLabel: 'Back',
                onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Profile & Preferences',
                    style: TextStyle(
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
          const SizedBox(height: 12.0),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Name Field
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
                          'User Profile',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18.0,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15.0,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Display Name',
                            labelStyle: const TextStyle(
                              fontFamily: 'Outfit',
                              color: AppColors.textSecondary,
                            ),
                            hintText: 'e.g. Alex',
                            hintStyle: const TextStyle(
                              fontFamily: 'Outfit',
                              color: AppColors.textMuted,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF070F2B),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.0),
                              borderSide: const BorderSide(
                                color: Color(0xFF1B2A66),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.0),
                              borderSide: const BorderSide(
                                color: Color(0xFF1B2A66),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14.0),

                  // Units & Metrics Card
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
                          'Measurement Units',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18.0,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        Row(
                          children: [
                            Expanded(
                              child: _buildChoicePill(
                                label: 'Beats/Min (BPM)',
                                isSelected: _useBpm,
                                onTap: () => setState(() => _useBpm = true),
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: _buildChoicePill(
                                label: 'Interval (ms)',
                                isSelected: !_useBpm,
                                onTap: () => setState(() => _useBpm = false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14.0),

                  // Language Selector Card
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
                          'Language & Directionality',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18.0,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        const Text(
                          'Supports English (LTR) and Arabic (RTL).',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        Row(
                          children: [
                            Expanded(
                              child: _buildChoicePill(
                                label: 'English',
                                isSelected: _selectedLocale == 'en',
                                onTap: () =>
                                    setState(() => _selectedLocale = 'en'),
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: _buildChoicePill(
                                label: 'العربية (RTL)',
                                isSelected: _selectedLocale == 'ar',
                                onTap: () =>
                                    setState(() => _selectedLocale = 'ar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14.0),

                  // Theme Selector Card
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dark Atmosphere Theme',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2.0),
                              Text(
                                'Calibrated to canvas visual tokens',
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
                          value: _isDarkTheme,
                          activeTrackColor: AppColors.accentPurple,
                          activeThumbColor: AppColors.accentCyan,
                          onChanged: (val) =>
                              setState(() => _isDarkTheme = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24.0),

                  // Save Button
                  PillButton(
                    label: 'Save Preferences',
                    style: PillButtonStyle.white,
                    onPressed: _savePreferences,
                  ),

                  const SizedBox(height: 12.0),

                  // Health & Biometrics Demographic Profile
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const UserProfileScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14.0,
                        horizontal: 16.0,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F2160), Color(0xFF1B2A66)],
                        ),
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.health_and_safety_outlined,
                            color: AppColors.accentCyan,
                            size: 20.0,
                          ),
                          SizedBox(width: 8.0),
                          Flexible(
                            child: Text(
                              'Health Profile (BMI, Age, BP)',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.0,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12.0),

                  // Open Medical Knowledge Assistant
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MedicalKnowledgeAssistantScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14.0,
                        horizontal: 16.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2160),
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            color: AppColors.accentCyan,
                            size: 19.0,
                          ),
                          SizedBox(width: 8.0),
                          Flexible(
                            child: Text(
                              'Medical Knowledge Assistant (RAG)',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.0,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12.0),

                  // Open Application Settings
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ApplicationSettingsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14.0,
                        horizontal: 16.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1840),
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(color: const Color(0xFF1B2A66)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.settings_outlined,
                            color: Color(0xFFC9D0F5),
                            size: 18.0,
                          ),
                          SizedBox(width: 8.0),
                          Text(
                            'Application Settings',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.0,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFC9D0F5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12.0),

                  // Health Services (Blood Pressure & Clinic Discovery)
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const BpMonitoringScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B1840),
                              borderRadius: BorderRadius.circular(14.0),
                              border: Border.all(color: const Color(0xFF1B2A66)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.monitor_heart_outlined, color: AppColors.accentCyan, size: 18.0),
                                SizedBox(width: 6.0),
                                Flexible(
                                  child: Text(
                                    'Blood Pressure',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 13.0,
                                      color: Color(0xFFC9D0F5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const DoctorDiscoveryScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B1840),
                              borderRadius: BorderRadius.circular(14.0),
                              border: Border.all(color: const Color(0xFF1B2A66)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.local_hospital_outlined, color: AppColors.accentBlue, size: 18.0),
                                SizedBox(width: 6.0),
                                Flexible(
                                  child: Text(
                                    'Find Clinics',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 13.0,
                                      color: Color(0xFFC9D0F5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10.0),

                  // Health Analytics & Reports
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const HealthAnalyticsScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B1840),
                              borderRadius: BorderRadius.circular(14.0),
                              border: Border.all(color: const Color(0xFF1B2A66)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.analytics_outlined, color: AppColors.accentCyan, size: 18.0),
                                SizedBox(width: 6.0),
                                Flexible(
                                  child: Text(
                                    'Health Analytics',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 13.0,
                                      color: Color(0xFFC9D0F5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ReportsScreen(onBack: () => Navigator.of(context).pop())),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B1840),
                              borderRadius: BorderRadius.circular(14.0),
                              border: Border.all(color: const Color(0xFF1B2A66)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.picture_as_pdf_outlined, color: AppColors.accentBlue, size: 18.0),
                                SizedBox(width: 6.0),
                                Flexible(
                                  child: Text(
                                    'Clinical Reports',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 13.0,
                                      color: Color(0xFFC9D0F5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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

  Widget _buildChoicePill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFFFFF) : const Color(0xFF0B1840),
          borderRadius: BorderRadius.circular(14.0),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.0,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              color: isSelected
                  ? const Color(0xFF0B1840)
                  : const Color(0xFFC9D0F5),
            ),
          ),
        ),
      ),
    );
  }
}
