import 'package:flutter/material.dart';

/// App icon widget matching Icon.dc.html and App icon.png exactly:
/// viewBox: 0 0 100 100.
/// Background: radial gradient cx=0.5 cy=0.38 r=0.85 from #2A1A7A to #0B0A2A to #04030C.
/// Outer heart: M50 84C14 58 12 30 31 24c10-3 17 5 19 9 2-4 9-12 19-9 19 6 17 34-19 60z scale 1.4 from center.
/// Mid heart: stroke #6D5BD0 width 0.8 opacity 0.7 scale 1.12.
/// Inner heart: gradient #E11D9B to #6D28D9 to #2563EB.
/// Pulse wave: M16 57H35L41 57L46 41L53 71L59 50L63 57H84 (cyan glow width 7 opacity .28, white line width 3.4).
class AppIconWidget extends StatelessWidget {
  const AppIconWidget({
    super.key,
    this.size = 360.0,
    this.borderRadius,
    this.clipToSquircle = true,
  });

  final double size;
  final double? borderRadius;
  final bool clipToSquircle;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? (size * 0.22);

    Widget content = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: const _AppIconPainter(),
      ),
    );

    if (clipToSquircle) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: content,
      );
    }

    return content;
  }
}

class _AppIconPainter extends CustomPainter {
  const _AppIconPainter();

  Path _buildHeartPath() {
    // M50 84C14 58 12 30 31 24c10-3 17 5 19 9 2-4 9-12 19-9 19 6 17 34-19 60z
    final p = Path();
    p.moveTo(50, 84);
    p.cubicTo(14, 58, 12, 30, 31, 24);
    // c10-3 17 5 19 9 -> from (31, 24)
    p.cubicTo(41, 21, 48, 29, 50, 33);
    // c2-4 9-12 19-9 -> from (50, 33)
    p.cubicTo(52, 29, 59, 21, 69, 24);
    // c19 6 17 34 -19 60 -> from (69, 24)
    p.cubicTo(88, 30, 86, 58, 50, 84);
    p.close();
    return p;
  }

  Path _buildWavePath() {
    // M16 57H35L41 57L46 41L53 71L59 50L63 57H84
    final p = Path();
    p.moveTo(16, 57);
    p.lineTo(35, 57);
    p.lineTo(41, 57);
    p.lineTo(46, 41);
    p.lineTo(53, 71);
    p.lineTo(59, 50);
    p.lineTo(63, 57);
    p.lineTo(84, 57);
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 100.0;
    final scaleY = size.height / 100.0;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    // 1. Background Rect: radialGradient cx=.5 cy=.38 r=.85
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.24), // cx=.5, cy=.38
        radius: 0.85,
        colors: const [Color(0xFF2A1A7A), Color(0xFF0B0A2A), Color(0xFF04030C)],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(const Rect.fromLTWH(0, 0, 100, 100));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), bgPaint);

    final heartPath = _buildHeartPath();
    final heartBounds = heartPath.getBounds();

    // 2. Outer Heart: scale(1.4) around (50, 54)
    canvas.save();
    canvas.translate(50, 54);
    canvas.scale(1.4, 1.4);
    canvas.translate(-50, -54);

    final h2Paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x807C3AED), // #7C3AED stop-opacity .5
          Color(0x401D4ED8), // #1D4ED8 stop-opacity .25
        ],
      ).createShader(heartBounds);
    canvas.drawPath(heartPath, h2Paint);
    canvas.restore();

    // 3. Mid Heart Stroke: scale(1.12) around (50, 54)
    canvas.save();
    canvas.translate(50, 54);
    canvas.scale(1.12, 1.12);
    canvas.translate(-50, -54);

    final midStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xB36D5BD0); // #6D5BD0 opacity .7
    canvas.drawPath(heartPath, midStrokePaint);
    canvas.restore();

    // 4. Inner Heart: gradient #E11D9B to #6D28D9 to #2563EB
    final h1Paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment(-0.6, -1.0), // x1=.2, y1=0 -> Alignment(-0.6, -1.0)
        end: Alignment(0.6, 1.0), // x2=.8, y2=1 -> Alignment(0.6, 1.0)
        colors: [Color(0xFFE11D9B), Color(0xFF6D28D9), Color(0xFF2563EB)],
        stops: [0.0, 0.55, 1.0],
      ).createShader(heartBounds);
    canvas.drawPath(heartPath, h1Paint);

    // 5. Optical Wave Cyan Glow: stroke #22D3EE strokeWidth 7 opacity .28
    final wavePath = _buildWavePath();
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0x4722D3EE); // opacity .28
    canvas.drawPath(wavePath, glowPaint);

    // 6. Foreground White Wave: stroke #FFFFFF strokeWidth 3.4
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white;
    canvas.drawPath(wavePath, linePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
