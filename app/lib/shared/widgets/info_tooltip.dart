import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Reusable educational info tooltip matching app typography and theme.
class InfoTooltip extends StatelessWidget {
  const InfoTooltip({super.key, required this.message, this.child});

  final String message;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      decoration: BoxDecoration(
        color: const Color(0xFF131D42),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      textStyle: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 13.0,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.3,
      ),
      child:
          child ??
          const Icon(
            Icons.info_outline_rounded,
            size: 18.0,
            color: AppColors.textSecondary,
          ),
    );
  }
}
