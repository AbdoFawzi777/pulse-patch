import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum PillButtonStyle { white, dark, stopSave }

/// Pill button matching design canvas:
/// Height 48px, border-radius 24px, border 0, font Outfit 500 16px, padding 0 24px.
/// White: #FFFFFF background, #0B1840 text.
/// Dark: #0B1840 background, #FFFFFF text.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = PillButtonStyle.white,
    this.width,
    this.height = 48.0,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final PillButtonStyle style;
  final double? width;
  final double height;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;

    switch (style) {
      case PillButtonStyle.white:
        bg = AppColors.pillWhite;
        textColor = AppColors.pillDark;
        break;
      case PillButtonStyle.dark:
      case PillButtonStyle.stopSave:
        bg = AppColors.pillDark;
        textColor = AppColors.textPrimary;
        break;
    }

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: width,
          height: height,
          padding: EdgeInsets.symmetric(
            horizontal: width != null && width! < 120 ? 8.0 : 16.0,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24.0),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18.0, color: textColor),
                const SizedBox(width: 8.0),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
