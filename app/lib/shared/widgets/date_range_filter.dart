import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum DateRangeOption { week, day }

/// Segmented pill toggle matching History.png (Week vs Day selector).
class DateRangeFilter extends StatelessWidget {
  const DateRangeFilter({
    super.key,
    required this.selectedOption,
    required this.onChanged,
    this.trailing,
  });

  final DateRangeOption selectedOption;
  final ValueChanged<DateRangeOption> onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            color: const Color(0xFF070E24),
            borderRadius: BorderRadius.circular(999.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSegment(
                label: 'Week',
                isSelected: selectedOption == DateRangeOption.week,
                onTap: () => onChanged(DateRangeOption.week),
              ),
              const SizedBox(width: 4.0),
              _buildSegment(
                label: 'Day',
                isSelected: selectedOption == DateRangeOption.day,
                onTap: () => onChanged(DateRangeOption.day),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }

  Widget _buildSegment({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(999.0),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: 22.0,
              vertical: 10.0,
            ),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(999.0),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.0,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.bgBase : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
