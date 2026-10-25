import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

/// Canvas container matching the artboard design:
/// 390x844 base dimensions, #04030C base with top-left (#1A0F44) and bottom-right (#3A1566) radial glows,
/// outer padding 28px top, 20px horizontal, 20px bottom.
class DesignCanvasScaffold extends StatelessWidget {
  const DesignCanvasScaffold({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20.0, 33.0, 20.0, 20.0),
    this.bottomNavigationBar,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.bgBase,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bgBase,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Exact canvas background with dual radial glows
            const CustomPaint(
              painter: _CanvasBackgroundPainter(),
            ),
            SafeArea(
              top: true,
              bottom: true,
              child: Padding(
                padding: padding,
                child: Column(
                  children: [
                    Expanded(child: child),
                    ?bottomNavigationBar,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CanvasBackgroundPainter extends CustomPainter {
  const _CanvasBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Base background: #04030C
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.bgBase,
    );

    // Glow 1: Top-Left radial-gradient(80% 35% at 0% 0%, #1A0F44 0%, transparent 70%)
    final rectTL = Rect.fromLTWH(-size.width * 0.2, -size.height * 0.1, size.width * 1.0, size.height * 0.7);
    final paintTL = Paint()
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 0.85,
        colors: [
          const Color(0xFF1A0F44).withValues(alpha: 0.95),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7],
      ).createShader(rectTL);
    canvas.drawRect(Offset.zero & size, paintTL);

    // Glow 2: Bottom-Right radial-gradient(90% 45% at 100% 100%, #3A1566 0%, transparent 70%)
    final rectBR = Rect.fromLTWH(size.width * 0.1, size.height * 0.4, size.width * 1.0, size.height * 0.7);
    final paintBR = Paint()
      ..shader = RadialGradient(
        center: Alignment.bottomRight,
        radius: 0.95,
        colors: [
          const Color(0xFF3A1566).withValues(alpha: 0.95),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7],
      ).createShader(rectBR);
    canvas.drawRect(Offset.zero & size, paintBR);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
