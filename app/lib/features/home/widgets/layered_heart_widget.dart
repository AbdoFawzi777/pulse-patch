import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Layered gradient heart illustration matching Home.png canvas.
class LayeredHeartWidget extends StatelessWidget {
  const LayeredHeartWidget({
    super.key,
    this.width = 280.0,
    this.height = 280.0,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer dark indigo layered heart silhouette
          CustomPaint(
            size: Size(width, height),
            painter: _HeartPainter(
              color: const Color(0xFF171B42),
              isGradient: false,
            ),
          ),
          // Inner vibrant magenta-to-blue gradient heart
          CustomPaint(
            size: Size(width * 0.72, height * 0.72),
            painter: _HeartPainter(
              isGradient: true,
              gradientColors: const [
                AppColors.accentMagenta,
                AppColors.accentBlue,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartPainter extends CustomPainter {
  const _HeartPainter({
    this.color = Colors.white,
    this.isGradient = false,
    this.gradientColors = const [Color(0xFFE11D9B), Color(0xFF2563EB)],
  });

  final Color color;
  final bool isGradient;
  final List<Color> gradientColors;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    // Standard smooth parametric heart Bézier curve
    path.moveTo(w * 0.5, h * 0.85);

    // Left bottom to left top lobe
    path.cubicTo(w * 0.05, h * 0.55, w * 0.0, h * 0.25, w * 0.25, h * 0.15);

    // Left top lobe to center cleft
    path.cubicTo(w * 0.40, h * 0.08, w * 0.50, h * 0.28, w * 0.50, h * 0.35);

    // Right top cleft to right lobe
    path.cubicTo(w * 0.50, h * 0.28, w * 0.60, h * 0.08, w * 0.75, h * 0.15);

    // Right lobe down to bottom tip
    path.cubicTo(w * 1.0, h * 0.25, w * 0.95, h * 0.55, w * 0.5, h * 0.85);

    path.close();

    final paint = Paint()..style = PaintingStyle.fill;
    if (isGradient) {
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradientColors,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    } else {
      paint.color = color;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.isGradient != isGradient ||
        oldDelegate.gradientColors != gradientColors;
  }
}
