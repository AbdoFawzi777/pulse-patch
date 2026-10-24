import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'metric_card.dart';
import 'status_chip.dart';

/// AI Insight hero and feature cards matching AI Insights.png.
class InsightCard extends StatelessWidget {
  const InsightCard.modelResult({
    super.key,
    required this.patternTitle,
    required this.explanation,
    this.badgeText = 'Experimental',
  }) : isHero = true,
       featureName = null,
       featureValue = null;

  const InsightCard.feature({
    super.key,
    required this.featureName,
    required this.featureValue,
  }) : isHero = false,
       patternTitle = null,
       explanation = null,
       badgeText = null;

  final bool isHero;
  final String? patternTitle;
  final String? explanation;
  final String? badgeText;
  final String? featureName;
  final String? featureValue;

  @override
  Widget build(BuildContext context) {
    if (isHero) {
      return MetricCard(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cardAiGradientStart, AppColors.cardAiGradientEnd],
        ),
        borderColor: const Color(0xFF6D28D9).withValues(alpha: 0.4),
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Model result',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.0,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFC4B5FD),
                  ),
                ),
                if (badgeText != null)
                  StatusChip(
                    label: badgeText!,
                    variant: StatusChipVariant.experimental,
                  ),
              ],
            ),
            const SizedBox(height: 16.0),
            Text(
              patternTitle ?? 'Typical pattern',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 32.0,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              explanation ?? '',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.0,
                fontWeight: FontWeight.w400,
                color: Color(0xFFCBD5E1),
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return MetricCard(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            featureName ?? '',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.0,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            featureValue ?? '',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 24.0,
              fontWeight: FontWeight.w300,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
