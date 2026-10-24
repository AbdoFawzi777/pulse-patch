import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/preferences_repository.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/pill_button.dart';

class UserPreferencesScreen extends ConsumerStatefulWidget {
  const UserPreferencesScreen({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  ConsumerState<UserPreferencesScreen> createState() =>
      _UserPreferencesScreenState();
}

class _UserPreferencesScreenState extends ConsumerState<UserPreferencesScreen> {
  late final TextEditingController _nameController;
  bool _useBpm = true;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(preferencesRepositoryProvider);
    _nameController = TextEditingController(text: prefs.userName);
    _useBpm = prefs.useBpmUnits;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveAndNext() async {
    final prefs = ref.read(preferencesRepositoryProvider);
    await prefs.setUserName(_nameController.text.trim());
    await prefs.setUseBpmUnits(_useBpm);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        children: [
          // Background corner glow
          Positioned(
            top: -100,
            left: -100,
            width: 350,
            height: 350,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.bgGlowTopLeft.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12.0),
                  CircleIconButton(
                    icon: Icons.chevron_left_rounded,
                    semanticLabel: 'Back',
                    onPressed: widget.onBack,
                  ),
                  const SizedBox(height: 20.0),
                  const Text(
                    'Preferences',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 28.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  const Text(
                    'Set up your display preferences. No account is required.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Display Name
                        const Text(
                          'Your Name (Optional)',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.0,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. Alex',
                            hintStyle: const TextStyle(
                              fontFamily: 'Outfit',
                              color: AppColors.textMuted,
                            ),
                            filled: true,
                            fillColor: AppColors.cardBgNavy,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18.0,
                              vertical: 16.0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.0),
                              borderSide: const BorderSide(
                                color: AppColors.cardBorder,
                                width: 1.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.0),
                              borderSide: const BorderSide(
                                color: AppColors.cardBorder,
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.0),
                              borderSide: const BorderSide(
                                color: AppColors.accentBlue,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        // Preferred Unit
                        const Text(
                          'Primary Measurement Unit',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Row(
                          children: [
                            Expanded(
                              child: _UnitSelectionCard(
                                title: 'BPM',
                                subtitle: 'Beats per minute',
                                isSelected: _useBpm,
                                onTap: () => setState(() => _useBpm = true),
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: _UnitSelectionCard(
                                title: 'ms',
                                subtitle: 'Pulse interval',
                                isSelected: !_useBpm,
                                onTap: () => setState(() => _useBpm = false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24.0),
                        // Local Privacy Notice Card
                        MetricCard(
                          padding: const EdgeInsets.all(18.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.lock_outline_rounded,
                                color: AppColors.accentCyan,
                                size: 24.0,
                              ),
                              const SizedBox(width: 14.0),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Privacy & Local Storage',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 15.0,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 4.0),
                                    Text(
                                      'All pulse data and AI evaluations are strictly stored on this phone in a private SQLite database. No analytics or metrics are uploaded.',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.w400,
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
                      ],
                    ),
                  ),
                  PillButton(
                    label: 'Continue without account',
                    style: PillButtonStyle.white,
                    width: double.infinity,
                    height: 52.0,
                    onPressed: _handleSaveAndNext,
                  ),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitSelectionCard extends StatelessWidget {
  const _UnitSelectionCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MetricCard(
        borderColor: isSelected ? AppColors.accentBlue : AppColors.cardBorder,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20.0,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.accentBlue,
                    size: 18.0,
                  ),
              ],
            ),
            const SizedBox(height: 4.0),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.0,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
