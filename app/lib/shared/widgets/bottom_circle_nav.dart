import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum NavDestination { home, history, insights, device, services, monitoring, profile }

/// Floating bottom navigation bar made of responsive circular buttons.
/// Inactive: #0B1840 background with #C9D0F5 icon.
/// Active: #FFFFFF background with #0B1840 icon.
class BottomCircleNav extends StatelessWidget {
  const BottomCircleNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<({String label, NavDestination dest})>? items;

  static const List<({String label, NavDestination dest})> defaultNavItems = [
    (label: 'Home', dest: NavDestination.home),
    (label: 'History', dest: NavDestination.history),
    (label: 'Insights', dest: NavDestination.insights),
    (label: 'Device', dest: NavDestination.device),
  ];

  static const List<({String label, NavDestination dest})> fiveDestinations = [
    (label: 'Home', dest: NavDestination.home),
    (label: 'Monitoring', dest: NavDestination.monitoring),
    (label: 'Insights', dest: NavDestination.insights),
    (label: 'Services', dest: NavDestination.services),
    (label: 'Profile', dest: NavDestination.profile),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    final navList = items ?? defaultNavItems;
    final count = navList.length;

    // Responsive circle button size to prevent horizontal overflow on narrow screens
    final double buttonSize = count >= 5
        ? (screenWidth < 380 ? 48.0 : 54.0)
        : (screenWidth < 380 ? 56.0 : 64.0);
    final double spacing = count >= 5 ? 8.0 : 12.0;

    return Padding(
      padding: EdgeInsets.only(
        top: 8.0,
        bottom: bottomInset > 0 ? bottomInset + 6.0 : 10.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          final item = navList[index];
          final isActive = index == currentIndex;
          final isLast = index == count - 1;

          return Padding(
            padding: EdgeInsets.only(right: isLast ? 0.0 : spacing),
            child: Semantics(
              button: true,
              selected: isActive,
              label: item.label,
              child: GestureDetector(
                onTap: () => onTap(index),
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.bottomCircleActive
                        : AppColors.bottomCircleInactive,
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.25),
                              blurRadius: 10.0,
                              spreadRadius: 1.0,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: CustomPaint(
                      size: Size(buttonSize * 0.38, buttonSize * 0.38),
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

      case NavDestination.monitoring:
        // Pulse waveform: M3 12h4l3-7 4 14 3-7h4
        final p = Path();
        p.moveTo(3, 12);
        p.lineTo(7, 12);
        p.lineTo(10, 5);
        p.lineTo(14, 19);
        p.lineTo(17, 12);
        p.lineTo(21, 12);
        canvas.drawPath(p, strokePaint);
        break;

      case NavDestination.services:
        // Medical cross inside rounded shield: M12 2l8 4v6c0 5.5-3.5 10-8 12-4.5-2-8-6.5-8-12V6l8-4z
        final shield = Path();
        shield.moveTo(12, 3);
        shield.lineTo(19, 6.5);
        shield.lineTo(19, 11.5);
        shield.cubicTo(19, 16.0, 16.0, 19.5, 12, 21);
        shield.cubicTo(8.0, 19.5, 5, 16.0, 5, 11.5);
        shield.lineTo(5, 6.5);
        shield.close();
        canvas.drawPath(shield, strokePaint);
        // Cross inside
        final cross = Path();
        cross.moveTo(12, 8);
        cross.lineTo(12, 16);
        cross.moveTo(8, 12);
        cross.lineTo(16, 12);
        canvas.drawPath(cross, strokePaint);
        break;

      case NavDestination.profile:
        // User silhouette: head circle + shoulders arc
        canvas.drawCircle(const Offset(12, 8), 3.5, strokePaint);
        final shoulders = Path();
        shoulders.moveTo(5.5, 20);
        shoulders.cubicTo(6, 15.5, 9, 14, 12, 14);
        shoulders.cubicTo(15, 14, 18, 15.5, 18.5, 20);
        canvas.drawPath(shoulders, strokePaint);
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NavIconPainter oldDelegate) {
    return oldDelegate.destination != destination || oldDelegate.color != color;
  }
}
