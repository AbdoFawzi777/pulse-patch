import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// 56 px circular icon button matching design canvas header actions (Back, Profile, Notifications).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
    this.backgroundColor = AppColors.headerCircleBg,
    this.iconColor = AppColors.textPrimary,
    this.size = 56.0,
    this.iconSize = 24.0,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.0,
            ),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Center(
              child: Icon(icon, color: iconColor, size: iconSize),
            ),
          ),
        ),
      ),
    );
  }
}
