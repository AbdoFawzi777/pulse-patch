import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class DotPoint {
  const DotPoint({required this.normalizedY, required this.isMagenta});

  /// 0.0 (top) to 1.0 (bottom)
  final double normalizedY;
  final bool isMagenta;
}

/// Dot variability scatter chart matching Heart Rate.png canvas:
/// 318x120 viewBox, 48 dots at exact coordinates, #C026D3 and #2563EB at r=5, opacity .85,
/// labels: 6am, 9am, 12pm, 3pm, 6pm, 9pm in #9AA0C4 14px.
class DotVariabilityChart extends StatelessWidget {
  const DotVariabilityChart({
    super.key,
    this.columns = const [],
    this.timeLabels = const ['6am', '9am', '12pm', '3pm', '6pm', '9pm'],
    this.width = 318.0,
    this.height = 145.0,
  });

  final List<List<DotPoint>> columns;
  final List<String> timeLabels;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Column(
        children: [
          SizedBox(
            width: width,
            height: 120.0,
            child: CustomPaint(
              size: Size(width, 120.0),
              painter: const _DotVariabilityPainter(),
            ),
          ),
          const SizedBox(height: 4.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: timeLabels
                .map(
                  (label) => Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.0,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textMuted,
                      height: 1.0,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _DotVariabilityPainter extends CustomPainter {
  const _DotVariabilityPainter();

  static const List<({double cx, double cy, Color color})> _designDots = [
    (cx: 12, cy: 20, color: Color(0xD9C026D3)),
    (cx: 12, cy: 43, color: Color(0xD92563EB)),
    (cx: 12, cy: 66, color: Color(0xD92563EB)),
    (cx: 12, cy: 89, color: Color(0xD9C026D3)),

    (cx: 38, cy: 57, color: Color(0xD92563EB)),
    (cx: 38, cy: 80, color: Color(0xD92563EB)),
    (cx: 38, cy: 28, color: Color(0xD9C026D3)),
    (cx: 38, cy: 51, color: Color(0xD92563EB)),

    (cx: 64, cy: 94, color: Color(0xD92563EB)),
    (cx: 64, cy: 42, color: Color(0xD9C026D3)),
    (cx: 64, cy: 65, color: Color(0xD92563EB)),
    (cx: 64, cy: 88, color: Color(0xD92563EB)),

    (cx: 90, cy: 56, color: Color(0xD9C026D3)),
    (cx: 90, cy: 79, color: Color(0xD92563EB)),
    (cx: 90, cy: 27, color: Color(0xD92563EB)),
    (cx: 90, cy: 50, color: Color(0xD9C026D3)),

    (cx: 116, cy: 93, color: Color(0xD92563EB)),
    (cx: 116, cy: 41, color: Color(0xD92563EB)),
    (cx: 116, cy: 64, color: Color(0xD9C026D3)),
    (cx: 116, cy: 87, color: Color(0xD92563EB)),

    (cx: 142, cy: 55, color: Color(0xD92563EB)),
    (cx: 142, cy: 78, color: Color(0xD9C026D3)),
    (cx: 142, cy: 26, color: Color(0xD92563EB)),
    (cx: 142, cy: 49, color: Color(0xD92563EB)),

    (cx: 168, cy: 92, color: Color(0xD9C026D3)),
    (cx: 168, cy: 40, color: Color(0xD92563EB)),
    (cx: 168, cy: 63, color: Color(0xD92563EB)),
    (cx: 168, cy: 86, color: Color(0xD9C026D3)),

    (cx: 194, cy: 54, color: Color(0xD92563EB)),
    (cx: 194, cy: 77, color: Color(0xD92563EB)),
    (cx: 194, cy: 25, color: Color(0xD9C026D3)),
    (cx: 194, cy: 48, color: Color(0xD92563EB)),

    (cx: 220, cy: 91, color: Color(0xD92563EB)),
    (cx: 220, cy: 39, color: Color(0xD9C026D3)),
    (cx: 220, cy: 62, color: Color(0xD92563EB)),
    (cx: 220, cy: 85, color: Color(0xD92563EB)),

    (cx: 246, cy: 53, color: Color(0xD9C026D3)),
    (cx: 246, cy: 76, color: Color(0xD92563EB)),
    (cx: 246, cy: 24, color: Color(0xD92563EB)),
    (cx: 246, cy: 47, color: Color(0xD9C026D3)),

    (cx: 272, cy: 90, color: Color(0xD92563EB)),
    (cx: 272, cy: 38, color: Color(0xD92563EB)),
    (cx: 272, cy: 61, color: Color(0xD9C026D3)),
    (cx: 272, cy: 84, color: Color(0xD92563EB)),

    (cx: 298, cy: 52, color: Color(0xD92563EB)),
    (cx: 298, cy: 75, color: Color(0xD9C026D3)),
    (cx: 298, cy: 23, color: Color(0xD92563EB)),
    (cx: 298, cy: 46, color: Color(0xD92563EB)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 318.0;
    final scaleY = size.height / 120.0;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    for (final dot in _designDots) {
      final paint = Paint()
        ..color = dot.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dot.cx, dot.cy), 5.0, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
