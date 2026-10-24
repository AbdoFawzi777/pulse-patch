import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'heart_rate_hero_number.dart';
import 'metric_card.dart';

/// Session list item matching History.png layout.
class SessionTile extends StatelessWidget {
  const SessionTile({
    super.key,
    required this.title,
    required this.qualityText,
    required this.patternText,
    required this.bpm,
    this.onTap,
  });

  final String title;
  final String qualityText;
  final String patternText;
  final int bpm;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MetricCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 17.0,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Quality: $qualityText · Pattern: $patternText',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          HeartRateHeroNumber(bpm: bpm, size: HeroNumberSize.compact),
        ],
      ),
    );
  }
}
