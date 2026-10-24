import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class DotPoint {
  const DotPoint({required this.normalizedY, required this.isMagenta});

  /// 0.0 (top) to 1.0 (bottom)
  final double normalizedY;
  final bool isMagenta;
}

/// Dot variability scatter chart matching Heart Rate.png canvas.
class DotVariabilityChart extends StatelessWidget {
  const DotVariabilityChart({
    super.key,
    required this.columns,
    this.timeLabels = const ['6am', '9am', '12pm', '3pm', '6pm', '9pm'],
    this.height = 140.0,
  });

  final List<List<DotPoint>> columns;
  final List<String> timeLabels;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _DotVariabilityPainter(columns: columns),
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: timeLabels
                .map(
                  (label) => Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.0,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
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
  const _DotVariabilityPainter({required this.columns});

  final List<List<DotPoint>> columns;

  @override
  void paint(Canvas canvas, Size size) {
    if (columns.isEmpty) return;

    final magentaPaint = Paint()
      ..color = AppColors.accentMagenta
      ..style = PaintingStyle.fill;

    final bluePaint = Paint()
      ..color = AppColors.accentBlue
      ..style = PaintingStyle.fill;

    const dotRadius = 5.0;
    final numCols = columns.length;
    final colSpacing = size.width / (numCols > 1 ? (numCols - 1) : 1);

    for (int col = 0; col < numCols; col++) {
      final x = col * colSpacing;
      final dots = columns[col];

      for (final dot in dots) {
        final y = dot.normalizedY * (size.height - 2 * dotRadius) + dotRadius;
        canvas.drawCircle(
          Offset(x, y),
          dotRadius,
          dot.isMagenta ? magentaPaint : bluePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotVariabilityPainter oldDelegate) {
    return oldDelegate.columns != columns;
  }
}
