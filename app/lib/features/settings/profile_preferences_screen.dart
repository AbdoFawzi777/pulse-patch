import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/preferences_repository.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/pill_button.dart';

/// Screen managing user profile and UI display preferences.
/// Derived screen #18 adhering strictly to design tokens.
class ProfilePreferencesScreen extends ConsumerStatefulWidget {
  const ProfilePreferencesScreen({super.key});

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
          backgroundColor: AppColors.cardBgNavy,
          duration: Duration(seconds: 2),
        ),
      );
    }
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
                        'Profile & Preferences',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 56.0),
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
                    // User Name Field
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'User Profile',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
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
                                  color: AppColors.cardBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.0),
                                borderSide: const BorderSide(
                                  color: AppColors.cardBorder,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16.0),

                    // Units & Metrics Card
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Measurement Units',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
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

                    const SizedBox(height: 16.0),

                    // Language Selector Card
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Language & Directionality',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
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

                    const SizedBox(height: 16.0),

                    // Theme Selector Card
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
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w600,
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
          color: isSelected ? AppColors.accentPurple : const Color(0xFF070F2B),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: isSelected ? AppColors.accentPurple : AppColors.cardBorder,
            width: 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.0,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
