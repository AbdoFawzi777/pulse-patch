import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// 22 px rounded navy gradient card matching design canvas specifications.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20.0),
    this.gradient,
    this.borderColor,
    this.onTap,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final effectiveGradient =
        gradient ??
        const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.cardBgGradientStart, AppColors.cardBgGradientEnd],
        );

    final cardContent = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: effectiveGradient,
        borderRadius: BorderRadius.circular(22.0),
        border: Border.all(
          color: borderColor ?? AppColors.cardBorder,
          width: 1.0,
        ),
      ),
      child: child,
    );

    if (onTap == null) {
      return cardContent;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(22.0),
        onTap: onTap,
        child: cardContent,
      ),
    );
  }
}
