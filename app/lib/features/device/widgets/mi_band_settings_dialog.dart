import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/preferences_repository.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/pill_button.dart';

class MiBandSettingsDialog extends ConsumerStatefulWidget {
  const MiBandSettingsDialog({super.key});

  @override
  ConsumerState<MiBandSettingsDialog> createState() =>
      _MiBandSettingsDialogState();
}

class _MiBandSettingsDialogState extends ConsumerState<MiBandSettingsDialog> {
  late final TextEditingController _keyController;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _keyController = TextEditingController(
      text: prefs.getString('mi_band_auth_key') ?? '',
    );
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _saveKey() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final key = _keyController.text.trim();
    await prefs.setString('mi_band_auth_key', key);
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            key.isEmpty ? 'Auth key cleared' : 'Auth key saved locally',
          ),
          backgroundColor: AppColors.cardBgNavy,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 24.0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF070E28),
          borderRadius: BorderRadius.circular(22.0),
          border: Border.all(color: AppColors.cardBorder, width: 1.2),
        ),
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mi Smart Band 5 Setup',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18.0,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),

              // Method 1
              MetricCard(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: AppColors.accentCyan,
                          size: 18.0,
                        ),
                        SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            'Method 1: Heart Rate Broadcast (Recommended)',
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
                    const SizedBox(height: 6.0),
                    const Text(
                      '1. Open Zepp Life (formerly Mi Fit) on your phone.\n'
                      '2. Go to Profile -> Mi Smart Band 5.\n'
                      '3. Tap "Heart rate sharing" (or "Activity heart rate sharing") and turn it ON.\n'
                      '4. Return to PulsePatch Lite and tap Connect. No pairing keys required!',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12.0),

              // Method 2
              MetricCard(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.vpn_key_outlined,
                          color: AppColors.accentMagenta,
                          size: 18.0,
                        ),
                        SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            'Method 2: Direct Huami Auth Key (Advanced)',
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
                    const SizedBox(height: 6.0),
                    const Text(
                      'If using direct Huami connection without Zepp Life, enter your extracted 16-byte key below. Stored locally only; never committed or transmitted.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textMuted,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    TextField(
                      controller: _keyController,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.0,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '32 hex characters (16 bytes)',
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.cardBgNavy,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 10.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16.0),

              Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: 'Save Key',
                      style: PillButtonStyle.white,
                      onPressed: _saveKey,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: PillButton(
                      label: 'Done',
                      style: PillButtonStyle.dark,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
