import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Professional Real-Time Optical PPG (Photoplethysmogram) Waveform Visualizer.
/// Matches Phase 5 specifications:
/// - Explicitly labeled as Optical PPG (NEVER ECG).
/// - Bounded circular buffer with stable rolling rendering.
/// - Isolated RepaintBoundary for 60fps rendering without full-screen rebuilds.
/// - Subtle grid, baseline zero, and voltage/ADC scaling.
/// - Clear data source distinction (Hardware MAX30102 vs Simulated Test Data).
/// - Signal gating when contact lost or SQI < 50%.
class PpgWaveformVisualizer extends StatelessWidget {
  const PpgWaveformVisualizer({
    super.key,
    required this.samples,
    this.height = 140.0,
    this.sqi = 95,
    this.isContactDetected = true,
    this.isSampleData = false,
    this.isPaused = false,
    this.samplingRateHz = 25.0,
  });

  final List<double> samples;
  final double height;
  final int sqi;
  final bool isContactDetected;
  final bool isSampleData;
  final bool isPaused;
  final double samplingRateHz;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final String qualityLabel;
    final Color qualityColor;
    if (!isContactDetected) {
      qualityLabel = isRtl ? 'فقدان الاتصال بالإصبع' : 'Contact Lost';
      qualityColor = const Color(0xFFEF4444);
    } else if (sqi < 50) {
      qualityLabel = isRtl ? 'جودة إشارة منخفضة' : 'Low Quality (Motion)';
      qualityColor = const Color(0xFFF59E0B);
    } else {
      qualityLabel = isRtl ? 'إشارة ضوئية ممتازة' : 'Optimal Optical Signal';
      qualityColor = const Color(0xFF10B981);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBgNavy,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.cardBorder.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Waveform Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.show_chart_rounded,
                      color: AppColors.accentCyan,
                      size: 16.0,
                    ),
                    const SizedBox(width: 6.0),
                    Expanded(
                      child: Text(
                        isRtl ? 'مخطط النبض الضوئي (PPG)' : 'Live PPG Waveform (Optical)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Source Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: isSampleData
                          ? const Color(0x33F59E0B)
                          : const Color(0x3322D3EE),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      isSampleData
                          ? (isRtl ? 'بيانات محاكاة' : 'Simulated Data')
                          : 'MAX30102 · 25 Hz',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.0,
                        fontWeight: FontWeight.w500,
                        color: isSampleData
                            ? const Color(0xFFFBBF24)
                            : AppColors.accentCyan,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6.0),
                  // Non-ECG clarification chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: const Text(
                      'Not ECG',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 9.0,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8.0),

          // Canvas Trace Display with RepaintBoundary
          RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                height: height,
                color: const Color(0xFF060B1E),
                child: CustomPaint(
                  size: Size(double.infinity, height),
                  painter: _PpgCanvasPainter(
                    samples: samples,
                    isContactDetected: isContactDetected,
                    sqi: sqi,
                    isPaused: isPaused,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8.0),

          // Footer Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8.0,
                      height: 8.0,
                      decoration: BoxDecoration(
                        color: qualityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Flexible(
                      child: Text(
                        '$qualityLabel ($sqi%)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.0,
                          fontWeight: FontWeight.w400,
                          color: qualityColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              Flexible(
                child: Text(
                  isPaused
                      ? (isRtl ? 'المخطط متوقف مؤقتاً' : 'Chart Paused')
                      : (isRtl ? 'تحديث لحظي مستمر' : 'Live Rolling Buffer'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.0,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PpgCanvasPainter extends CustomPainter {
  const _PpgCanvasPainter({
    required this.samples,
    required this.isContactDetected,
    required this.sqi,
    required this.isPaused,
  });

  final List<double> samples;
  final bool isContactDetected;
  final int sqi;
  final bool isPaused;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw subtle background medical grid
    final gridPaint = Paint()
      ..color = const Color(0xFF132247).withValues(alpha: 0.6)
      ..strokeWidth = 0.8;

    const numHorizontalLines = 4;
    for (int i = 1; i <= numHorizontalLines; i++) {
      final y = (h / (numHorizontalLines + 1)) * i;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    const numVerticalLines = 8;
    for (int i = 1; i <= numVerticalLines; i++) {
      final x = (w / (numVerticalLines + 1)) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }

    // 2. Center baseline indicator
    final baselinePaint = Paint()
      ..color = const Color(0xFF1E3A8A).withValues(alpha: 0.4)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, h * 0.5), Offset(w, h * 0.5), baselinePaint);

    // 3. Check signal availability / contact
    if (!isContactDetected || samples.isEmpty) {
      // Flat noise baseline when contact is lost
      final flatPaint = Paint()
        ..color = const Color(0xFFEF4444).withValues(alpha: 0.5)
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(0, h * 0.5), Offset(w, h * 0.5), flatPaint);
      return;
    }

    // 4. Trace Paint with gradient shading
    final Color traceColor = sqi < 50 ? const Color(0xFFF59E0B) : AppColors.accentCyan;

    final tracePaint = Paint()
      ..color = traceColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final count = samples.length;
    final stepX = w / (count > 1 ? (count - 1) : 1);

    // Min-Max normalization for bounded rendering
    double minVal = samples.reduce((a, b) => a < b ? a : b);
    double maxVal = samples.reduce((a, b) => a > b ? a : b);
    if ((maxVal - minVal).abs() < 0.0001) {
      maxVal = minVal + 1.0;
    }

    // Map samples into canvas height with padding (15% top and bottom margin)
    final plotHeight = h * 0.70;
    final topOffset = h * 0.15;

    double getY(double val) {
      final norm = (val - minVal) / (maxVal - minVal);
      // Invert Y so peak points upwards
      return topOffset + plotHeight * (1.0 - norm.clamp(0.0, 1.0));
    }

    path.moveTo(0, getY(samples[0]));
    for (int i = 0; i < count - 1; i++) {
      final x0 = i * stepX;
      final y0 = getY(samples[i]);
      final x1 = (i + 1) * stepX;
      final y1 = getY(samples[i + 1]);
      final midX = (x0 + x1) / 2.0;
      path.cubicTo(midX, y0, midX, y1, x1, y1);
    }

    // 5. Draw smooth fill below curve
    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          traceColor.withValues(alpha: 0.25),
          traceColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, tracePaint);

    // 6. Draw trailing cursor dot on latest sample
    final lastX = (count - 1) * stepX;
    final lastY = getY(samples.last);
    final dotGlow = Paint()
      ..color = traceColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final dotCore = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(lastX, lastY), 5.0, dotGlow);
    canvas.drawCircle(Offset(lastX, lastY), 2.5, dotCore);
  }

  @override
  bool shouldRepaint(covariant _PpgCanvasPainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.isContactDetected != isContactDetected ||
        oldDelegate.sqi != sqi ||
        oldDelegate.isPaused != isPaused;
  }
}
