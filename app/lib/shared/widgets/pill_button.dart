import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum PillButtonStyle { white, dark, stopSave }

/// Pill button adhering to design specification for white, dark, and stop/save variants.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = PillButtonStyle.white,
    this.width,
    this.height,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final PillButtonStyle style;
  final double? width;
  final double? height;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    Border? border;
    double defaultHeight = 44.0;
    double defaultMinWidth = 88.0;

    switch (style) {
      case PillButtonStyle.white:
        bg = AppColors.pillWhite;
        textColor = AppColors.bgBase;
        border = null;
        break;
      case PillButtonStyle.dark:
        bg = AppColors.pillDark;
        textColor = AppColors.textPrimary;
        border = Border.all(color: const Color(0xFF22335E), width: 1.0);
        break;
      case PillButtonStyle.stopSave:
        bg = AppColors.buttonStopSave;
        textColor = AppColors.textPrimary;
        border = Border.all(color: AppColors.cardBorder, width: 1.0);
        defaultHeight = 50.0;
        defaultMinWidth = 165.0;
        break;
    }

    final effectiveHeight = height ?? defaultHeight;

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: width ?? defaultMinWidth,
          minHeight: 48.0, // Accessible touch target
        ),
        child: SizedBox(
          width: width,
          height: effectiveHeight,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(999.0),
            child: Ink(
              decoration: BoxDecoration(
                color: onPressed == null ? bg.withValues(alpha: 0.5) : bg,
                borderRadius: BorderRadius.circular(999.0),
                border: border,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(999.0),
                onTap: onPressed,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 18.0, color: textColor),
                          const SizedBox(width: 6.0),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15.0,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
