import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum StatusChipVariant { neutral, active, sample, experimental }

/// Pill chip matching design canvas (e.g. "Sample data", "Saved", "Connected · ...").
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.variant = StatusChipVariant.neutral,
    this.leadingDot = false,
    this.dotColor,
  });

  final String label;
  final StatusChipVariant variant;
  final bool leadingDot;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;

    switch (variant) {
      case StatusChipVariant.neutral:
        bg = AppColors.chipBg;
        border = AppColors.chipBorder;
        text = AppColors.textSecondary;
        break;
      case StatusChipVariant.active:
        bg = const Color(0xFF0F2445);
        border = const Color(0xFF2563EB);
        text = const Color(0xFF93C5FD);
        break;
      case StatusChipVariant.sample:
        bg = AppColors.chipBg;
        border = const Color(0xFF334155);
        text = AppColors.textMuted;
        break;
      case StatusChipVariant.experimental:
        bg = const Color(0xFF2A1657);
        border = const Color(0xFF4C1D95);
        text = const Color(0xFFDDD6FE);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999.0),
        border: Border.all(color: border, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingDot) ...[
            Container(
              width: 6.0,
              height: 6.0,
              decoration: BoxDecoration(
                color: dotColor ?? AppColors.accentCyan,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6.0),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.0,
              fontWeight: FontWeight.w400,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}
