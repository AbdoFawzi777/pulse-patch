import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum StatusChipVariant { neutral, active, sample, experimental }

/// Pill chip matching design canvas:
/// border: 1px solid #3B4270, border-radius: 8px, padding: 2px 6px,
/// text: 11px Outfit 300 #9AA0C4.
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppColors.chipBorder, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leadingDot) ...[
            Container(
              width: 5.0,
              height: 5.0,
              margin: const EdgeInsets.only(right: 4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor ?? AppColors.textSecondary,
              ),
            ),
          ],
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.0,
              fontWeight: FontWeight.w300,
              color: AppColors.chipText,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
