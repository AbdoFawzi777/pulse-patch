import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// 22 px rounded navy gradient card matching design canvas specifications.
/// CSS: background: linear-gradient(160deg, #0F2160, #08122E); border-radius: 22px; padding: 16px;
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.gradient,
    this.borderColor,
    this.onTap,
    this.width,
    this.height,
    this.minHeight,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    // 160 degrees in linear gradient
    final effectiveGradient =
        gradient ??
        const LinearGradient(
          begin: Alignment(-0.34, -0.94),
          end: Alignment(0.34, 0.94),
          colors: [AppColors.cardBgGradientStart, AppColors.cardBgGradientEnd],
        );

    final cardContent = Container(
      width: width,
      height: height,
      constraints: minHeight != null
          ? BoxConstraints(minHeight: minHeight!)
          : null,
      padding: padding,
      decoration: BoxDecoration(
        gradient: effectiveGradient,
        borderRadius: BorderRadius.circular(22.0),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1.0)
            : null,
      ),
      child: child,
    );

    if (onTap == null) {
      return cardContent;
    }

    return GestureDetector(
      onTap: onTap,
      child: cardContent,
    );
  }
}
