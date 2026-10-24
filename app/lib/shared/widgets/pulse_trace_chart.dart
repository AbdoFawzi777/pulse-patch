import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Smooth optical pulse trace waveform matching Measuring.png and Heart Rate.png.
class PulseTraceChart extends StatelessWidget {
  const PulseTraceChart({
    super.key,
    required this.points,
    this.height = 100.0,
    this.strokeWidth = 2.5,
    this.lineColor = Colors.white,
    this.showGlow = true,
  });

  /// Normalized points where y ranges from 0.0 (top) to 1.0 (bottom).
  final List<double> points;
  final double height;
  final double strokeWidth;
  final Color lineColor;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _PulseTracePainter(
          points: points,
          strokeWidth: strokeWidth,
          lineColor: lineColor,
          showGlow: showGlow,
        ),
      ),
    );
  }
}

class _PulseTracePainter extends CustomPainter {
  const _PulseTracePainter({
    required this.points,
    required this.strokeWidth,
    required this.lineColor,
    required this.showGlow,
  });

  final List<double> points;
  final double strokeWidth;
  final Color lineColor;
  final bool showGlow;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final path = Path();
    final stepX = size.width / (points.length - 1).clamp(1, 1000);

    // Initial point
    path.moveTo(0.0, points[0] * size.height);

    for (int i = 0; i < points.length - 1; i++) {
      final currentX = i * stepX;
      final currentY = points[i] * size.height;
      final nextX = (i + 1) * stepX;
      final nextY = points[i + 1] * size.height;

      final controlX1 = currentX + (nextX - currentX) / 2;
      final controlY1 = currentY;
      final controlX2 = currentX + (nextX - currentX) / 2;
      final controlY2 = nextY;

      path.cubicTo(controlX1, controlY1, controlX2, controlY2, nextX, nextY);
    }

    // Optional subtle glow behind the optical trace
    if (showGlow) {
      final glowPaint = Paint()
        ..color = AppColors.accentCyan.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 2.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawPath(path, glowPaint);
    }

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _PulseTracePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
