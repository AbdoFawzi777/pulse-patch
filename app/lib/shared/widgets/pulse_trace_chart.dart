import 'package:flutter/material.dart';

/// Smooth optical pulse trace waveform matching Measuring.png and Heart Rate.png:
/// ViewBox: 0 0 350 130, stroke: #fff, strokeWidth: 1.3, strokeJoin: round.
/// Path: M0 90C20 90 25 30 45 30S65 95 85 90 105 24 125 28 145 95 165 90 185 22 205 26 225 96 245 90 265 28 285 30 305 95 325 90 340 50 350 60
class PulseTraceChart extends StatelessWidget {
  const PulseTraceChart({
    super.key,
    this.points = const [],
    this.width = 350.0,
    this.height = 130.0,
    this.strokeWidth = 1.3,
    this.lineColor = Colors.white,
    this.showGlow = false,
    this.useDesignPath = false,
  });

  final List<double> points;
  final double width;
  final double height;
  final double strokeWidth;
  final Color lineColor;
  final bool showGlow;
  final bool useDesignPath;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        size: Size(width, height),
        painter: _PulseTracePainter(
          points: points,
          strokeWidth: strokeWidth,
          lineColor: lineColor,
          showGlow: showGlow,
          useDesignPath: useDesignPath || points.isEmpty,
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
    required this.useDesignPath,
  });

  final List<double> points;
  final double strokeWidth;
  final Color lineColor;
  final bool showGlow;
  final bool useDesignPath;

  Path _buildDesignPath() {
    final p = Path();
    p.moveTo(0, 90);
    // C20 90 25 30 45 30
    p.cubicTo(20, 90, 25, 30, 45, 30);
    // S65 95 85 90
    p.cubicTo(65, 30, 65, 95, 85, 90);
    // S105 24 125 28
    p.cubicTo(105, 85, 105, 24, 125, 28);
    // S145 95 165 90
    p.cubicTo(145, 32, 145, 95, 165, 90);
    // S185 22 205 26
    p.cubicTo(185, 85, 185, 22, 205, 26);
    // S225 96 245 90
    p.cubicTo(225, 30, 225, 96, 245, 90);
    // S265 28 285 30
    p.cubicTo(265, 84, 265, 28, 285, 30);
    // S305 95 325 90
    p.cubicTo(305, 32, 305, 95, 325, 90);
    // S340 50 350 60
    p.cubicTo(345, 85, 340, 50, 350, 60);
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (useDesignPath || points.isEmpty) {
      final scaleX = size.width / 350.0;
      final scaleY = size.height / 130.0;
      canvas.save();
      canvas.scale(scaleX, scaleY);
      canvas.drawPath(_buildDesignPath(), paint);
      canvas.restore();
      return;
    }

    final path = Path();
    final stepX = size.width / (points.length - 1).clamp(1, 1000);
    path.moveTo(0.0, points[0] * size.height);

    for (int i = 0; i < points.length - 1; i++) {
      final x0 = i * stepX;
      final y0 = points[i] * size.height;
      final x1 = (i + 1) * stepX;
      final y1 = points[i + 1] * size.height;
      final midX = (x0 + x1) / 2.0;
      path.cubicTo(midX, y0, midX, y1, x1, y1);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PulseTracePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.useDesignPath != useDesignPath;
  }
}
