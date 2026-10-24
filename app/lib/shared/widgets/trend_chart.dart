import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Historical trend chart with explicit null gap handling (null is a gap, never zero).
class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.values,
    this.labels = const [],
    this.height = 140.0,
    this.lineColor = AppColors.accentBlue,
    this.minY = 40.0,
    this.maxY = 160.0,
  });

  /// Nullable values where null indicates a missing/unrecorded time bin (rendered as a gap).
  final List<double?> values;
  final List<String> labels;
  final double height;
  final Color lineColor;
  final double minY;
  final double maxY;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _TrendChartPainter(
                values: values,
                lineColor: lineColor,
                minY: minY,
                maxY: maxY,
              ),
            ),
          ),
          if (labels.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: labels
                  .map(
                    (l) => Text(
                      l,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  const _TrendChartPainter({
    required this.values,
    required this.lineColor,
    required this.minY,
    required this.maxY,
  });

  final List<double?> values;
  final Color lineColor;
  final double minY;
  final double maxY;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final range = (maxY - minY).clamp(1.0, 1000.0);
    final stepX = size.width / (values.length - 1).clamp(1, 1000);

    Path? currentSegment;

    for (int i = 0; i < values.length; i++) {
      final val = values[i];
      if (val == null) {
        // Break segment on null gap (never connect to 0)
        if (currentSegment != null) {
          canvas.drawPath(currentSegment, linePaint);
          currentSegment = null;
        }
        continue;
      }

      final x = i * stepX;
      final normalizedY = (1.0 - ((val - minY) / range)).clamp(0.0, 1.0);
      final y = normalizedY * size.height;

      canvas.drawCircle(Offset(x, y), 3.5, pointPaint);

      if (currentSegment == null) {
        currentSegment = Path()..moveTo(x, y);
      } else {
        currentSegment.lineTo(x, y);
      }
    }

    if (currentSegment != null) {
      canvas.drawPath(currentSegment, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.minY != minY ||
        oldDelegate.maxY != maxY;
  }
}
