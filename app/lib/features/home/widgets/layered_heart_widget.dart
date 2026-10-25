import 'package:flutter/material.dart';

/// Layered gradient heart illustration matching Home.png canvas exactly:
/// viewBox="0 0 200 180", width=330, height=300.
/// Outer path: M100 172C14 112 12 48 62 36c24-5 38 19 38 19s14-24 38-19c50 12 48 76-38 136z
/// Inner path: translate(40 36) scale(.6)
class LayeredHeartWidget extends StatelessWidget {
  const LayeredHeartWidget({
    super.key,
    this.width = 330.0,
    this.height = 300.0,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        size: Size(width, height),
        painter: const _HeartSvgPainter(),
      ),
    );
  }
}

class _HeartSvgPainter extends CustomPainter {
  const _HeartSvgPainter();

  Path _buildBaseHeartPath() {
    // M100 172C14 112 12 48 62 36c24-5 38 19 38 19s14-24 38-19c50 12 48 76-38 136z
    final p = Path();
    p.moveTo(100.0, 172.0);
    p.cubicTo(14.0, 112.0, 12.0, 48.0, 62.0, 36.0);
    // c24-5 38 19 38 19 -> cp1=(86, 31), cp2=(100, 55), ep=(100, 55)
    p.cubicTo(86.0, 31.0, 100.0, 55.0, 100.0, 55.0);
    // s14-24 38-19 -> cp1=reflection of cp2=(100, 55), cp2=(114, 31), ep=(138, 36)
    p.cubicTo(100.0, 55.0, 114.0, 31.0, 138.0, 36.0);
    // c50 12 48 76 -38 136 -> cp1=(188, 48), cp2=(186, 112), ep=(100, 172)
    p.cubicTo(188.0, 48.0, 186.0, 112.0, 100.0, 172.0);
    p.close();
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // ViewBox is 200 x 180
    final scaleX = size.width / 200.0;
    final scaleY = size.height / 180.0;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    final basePath = _buildBaseHeartPath();
    final bounds = basePath.getBounds();

    // 1. Outer Heart
    // linearGradient id="a" x1="0" y1="0" x2="0" y2="1" (top to bottom)
    // stop 0: #3A2A8F opacity .7, stop 1: #0B2A7A opacity .6
    final outerPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xB33A2A8F), Color(0x990B2A7A)],
      ).createShader(bounds);

    canvas.drawPath(basePath, outerPaint);

    // 2. Inner Heart
    // transform="translate(40 36) scale(.6)"
    // linearGradient id="b" x1="0" y1="0" x2="0" y2="1" (top to bottom)
    // stop 0: #C0148F, stop .5: #4B1E9E, stop 1: #1D4ED8
    canvas.save();
    canvas.translate(40.0, 36.0);
    canvas.scale(0.6, 0.6);

    final innerPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFC0148F), Color(0xFF4B1E9E), Color(0xFF1D4ED8)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(bounds);

    canvas.drawPath(basePath, innerPaint);
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
