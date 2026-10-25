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
    this.padding = const EdgeInsets.fromLTRB(20.0, 28.0, 20.0, 20.0),
    this.bottomNavigationBar,
    this.useSafeArea = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Widget? bottomNavigationBar;
  final bool useSafeArea;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final effectivePadding =
        (useSafeArea &&
            topInset > 0 &&
            padding == const EdgeInsets.fromLTRB(20.0, 28.0, 20.0, 20.0))
        ? const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 12.0)
        : padding;

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
            const CustomPaint(painter: _CanvasBackgroundPainter()),
            SafeArea(
              top: useSafeArea,
              bottom: false,
              child: Padding(
                padding: effectivePadding,
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
      Paint()..color = const Color(0xFF04030C),
    );

    // Glow 1: Top-Left radial-gradient(80% 35% at 0% 0%, #1A0F44 0%, transparent 70%)
    final rxTL = 0.80 * size.width * 0.70;
    final ryTL = 0.35 * size.height * 0.70;
    final rectTL = Rect.fromCenter(
      center: Offset.zero,
      width: rxTL * 2,
      height: ryTL * 2,
    );
    final paintTL = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF1A0F44), Color(0x001A0F44)],
        stops: [0.0, 1.0],
      ).createShader(rectTL);
    canvas.drawRect(Offset.zero & size, paintTL);

    // Glow 2: Bottom-Right radial-gradient(90% 45% at 100% 100%, #3A1566 0%, transparent 70%)
    final rxBR = 0.90 * size.width * 0.70;
    final ryBR = 0.45 * size.height * 0.70;
    final rectBR = Rect.fromCenter(
      center: Offset(size.width, size.height),
      width: rxBR * 2,
      height: ryBR * 2,
    );
    final paintBR = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF3A1566), Color(0x003A1566)],
        stops: [0.0, 1.0],
      ).createShader(rectBR);
    canvas.drawRect(Offset.zero & size, paintBR);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
