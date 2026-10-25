import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/preferences_repository.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
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
    return DesignCanvasScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleIconButton(
                type: CircleIconType.back,
                semanticLabel: 'Back',
                onPressed: widget.onBack,
              ),
              const Text(
                'Personalize',
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
          const SizedBox(height: 16.0),
          const Text(
            'Configure your profile and measurement display preferences.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.0,
              fontWeight: FontWeight.w300,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20.0),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                MetricCard(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Name or Alias',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.0,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      const Text(
                        'Used to personalize your reports and greeting.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.0,
                          fontWeight: FontWeight.w300,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12.0),
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.0),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 14.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14.0),
                MetricCard(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pulse Unit Preference',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.0,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      const Text(
                        'Choose between standard BPM or interval in milliseconds.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.0,
                          fontWeight: FontWeight.w300,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      Row(
                        children: [
                          Expanded(
                            child: PillButton(
                              label: 'BPM',
                              style: _useBpm
                                  ? PillButtonStyle.white
                                  : PillButtonStyle.dark,
                              onPressed: () => setState(() => _useBpm = true),
                            ),
                          ),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: PillButton(
                              label: 'ms (Interval)',
                              style: !_useBpm
                                  ? PillButtonStyle.white
                                  : PillButtonStyle.dark,
                              onPressed: () => setState(() => _useBpm = false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          PillButton(
            label: 'Save & Continue',
            style: PillButtonStyle.white,
            width: double.infinity,
            height: 48.0,
            onPressed: _handleSaveAndNext,
          ),
          const SizedBox(height: 10.0),
        ],
      ),
    );
  }
}
