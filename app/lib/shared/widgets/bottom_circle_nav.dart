import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum NavDestination { home, history, insights, device }

/// Floating bottom navigation bar made of four 64 px circular buttons.
/// Inactive: #0B1840 background with #C9D0F5 icon.
/// Active: #FFFFFF background with #0B1840 icon.
class BottomCircleNav extends StatelessWidget {
  const BottomCircleNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<({String label, NavDestination dest})> _navItems = [
    (label: 'Home', dest: NavDestination.home),
    (label: 'History', dest: NavDestination.history),
    (label: 'Insights', dest: NavDestination.insights),
    (label: 'Device', dest: NavDestination.device),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(
        top: 12.0,
        bottom: bottomInset > 0 ? bottomInset + 8.0 : 12.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_navItems.length, (index) {
          final item = _navItems[index];
          final isActive = index == currentIndex;
          final isLast = index == _navItems.length - 1;

          return Padding(
            padding: EdgeInsets.only(right: isLast ? 0.0 : 12.0),
            child: Semantics(
              button: true,
              selected: isActive,
              label: item.label,
              child: GestureDetector(
                onTap: () => onTap(index),
                child: Container(
                  width: 64.0,
                  height: 64.0,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.bottomCircleActive
                        : AppColors.bottomCircleInactive,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CustomPaint(
                      size: const Size(24.0, 24.0),
                      painter: _NavIconPainter(
                        destination: item.dest,
                        color: isActive
                            ? AppColors.navActiveIcon
                            : AppColors.navInactiveIcon,
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

class _NavIconPainter extends CustomPainter {
  const _NavIconPainter({required this.destination, required this.color});

  final NavDestination destination;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final scaleX = size.width / 24.0;
    final scaleY = size.height / 24.0;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    switch (destination) {
      case NavDestination.home:
        // M4 11l8-7 8 7v8a1 1 0 01-1 1H5a1 1 0 01-1-1z
        final p = Path();
        p.moveTo(4, 11);
        p.lineTo(12, 4);
        p.lineTo(20, 11);
        p.lineTo(20, 19);
        p.arcToPoint(const Offset(19, 20), radius: const Radius.circular(1));
        p.lineTo(5, 20);
        p.arcToPoint(const Offset(4, 19), radius: const Radius.circular(1));
        p.close();
        canvas.drawPath(p, strokePaint);
        break;

      case NavDestination.history:
        // circle cx="12" cy="12" r="8"
        canvas.drawCircle(const Offset(12, 12), 8, strokePaint);
        // path M12 7v5l3 2
        final p = Path();
        p.moveTo(12, 7);
        p.lineTo(12, 12);
        p.lineTo(15, 14);
        canvas.drawPath(p, strokePaint);
        break;

      case NavDestination.insights:
        // M5 20V10M12 20V4M19 20v-7
        final p = Path();
        p.moveTo(5, 20);
        p.lineTo(5, 10);
        p.moveTo(12, 20);
        p.lineTo(12, 4);
        p.moveTo(19, 20);
        p.lineTo(19, 13);
        canvas.drawPath(p, strokePaint);
        break;

      case NavDestination.device:
        // M12 20s-7-4.500-7-10a4 4 0 017-2.500A4 4 0 0119 10c0 5.500-7 10-7 10z
        final p = Path();
        p.moveTo(12, 20);
        p.cubicTo(12, 20, 5, 15.5, 5, 10);
        p.cubicTo(5, 7.5, 7, 5, 9.5, 5);
        p.cubicTo(10.5, 5, 11.5, 6, 12, 7.5);
        p.cubicTo(12.5, 6, 13.5, 5, 14.5, 5);
        p.cubicTo(17, 5, 19, 7.5, 19, 10);
        p.cubicTo(19, 15.5, 12, 20, 12, 20);
        canvas.drawPath(p, strokePaint);
        // Cross inside: M12 9v4M10 11h4
        final cross = Path();
        cross.moveTo(12, 9);
        cross.lineTo(12, 13);
        cross.moveTo(10, 11);
        cross.lineTo(14, 11);
        canvas.drawPath(cross, strokePaint);
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NavIconPainter oldDelegate) {
    return oldDelegate.destination != destination || oldDelegate.color != color;
  }
}
