import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum HeroNumberSize {
  large(96.0, 16.0),
  medium(84.0, 16.0),
  card(56.0, 14.0),
  compact(48.0, 13.0);

  const HeroNumberSize(this.fontSize, this.unitSize);
  final double fontSize;
  final double unitSize;
}

/// Large thin numeral component adhering to Outfit 300 tabular figures specification.
class HeartRateHeroNumber extends StatelessWidget {
  const HeartRateHeroNumber({
    super.key,
    required this.bpm,
    this.unit = 'BPM',
    this.size = HeroNumberSize.large,
    this.stacked = false,
    this.color = AppColors.textPrimary,
    this.isStale = false,
  });

  final int? bpm;
  final String unit;
  final HeroNumberSize size;
  final bool stacked;
  final Color color;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final displayText = bpm != null ? bpm.toString() : '--';
    final effectiveColor = isStale ? color.withValues(alpha: 0.7) : color;

    final numberWidget = Text(
      displayText,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: size.fontSize,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.5,
        color: effectiveColor,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );

    final unitWidget = Text(
      unit,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: size.unitSize,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
    );

    if (stacked) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [numberWidget, const SizedBox(height: 2.0), unitWidget],
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [numberWidget, const SizedBox(width: 8.0), unitWidget],
      ),
    );
  }
}
