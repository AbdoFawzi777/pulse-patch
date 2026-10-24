import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Floating bottom navigation bar made of four 64 px circular buttons.
class BottomCircleNav extends StatelessWidget {
  const BottomCircleNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<
    ({IconData activeIcon, IconData inactiveIcon, String label})
  >
  _navItems = [
    (
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
      label: 'Home',
    ),
    (
      activeIcon: Icons.access_time_filled_rounded,
      inactiveIcon: Icons.access_time_rounded,
      label: 'History',
    ),
    (
      activeIcon: Icons.bar_chart_rounded,
      inactiveIcon: Icons.bar_chart_outlined,
      label: 'AI Insights',
    ),
    (
      activeIcon: Icons.favorite_rounded,
      inactiveIcon: Icons.favorite_border_rounded,
      label: 'Device',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_navItems.length, (index) {
          final item = _navItems[index];
          final isActive = index == currentIndex;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Semantics(
              button: true,
              selected: isActive,
              label: item.label,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: Ink(
                  width: 64.0,
                  height: 64.0,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.bottomCircleActive
                        : AppColors.bottomCircleInactive,
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.15),
                              blurRadius: 16.0,
                              spreadRadius: 2.0,
                            ),
                          ]
                        : null,
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => onTap(index),
                    child: Center(
                      child: Icon(
                        isActive ? item.activeIcon : item.inactiveIcon,
                        size: 28.0,
                        color: isActive
                            ? AppColors.bgBase
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
