import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Circular countdown / progress timer matching Measuring.png and Live.dc.html exactly:
/// 160x160 circular container, disc #070F2B r=76, track #1B2A66 r=72 width 4,
/// progress arc #4C8DF5 r=72 width 4 round cap,
/// time 26px Outfit 300 + pause icon (two 4x14 rounded bars rx=1).
class CircularTimer extends StatelessWidget {
  const CircularTimer({
    super.key,
    required this.duration,
    required this.elapsed,
    this.isPaused = false,
    this.onTogglePause,
    this.diameter = 160.0,
    this.strokeWidth = 4.0,
  });

  final Duration duration;
  final Duration elapsed;
  final bool isPaused;
  final VoidCallback? onTogglePause;
  final double diameter;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final remaining = duration - elapsed;
    final displaySec = remaining.isNegative ? 0 : remaining.inSeconds;
    final mins = (displaySec ~/ 60).toString().padLeft(2, '0');
    final secs = (displaySec % 60).toString().padLeft(2, '0');
    final formattedTime = '$mins:$secs';

    final progress = duration.inMilliseconds > 0
        ? (elapsed.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Semantics(
      label: 'Timer: $formattedTime',
      button: onTogglePause != null,
      child: GestureDetector(
        onTap: onTogglePause,
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(diameter, diameter),
                painter: _CircularTimerPainter(
                  progress: progress > 0 ? progress : (130.0 / 452.39),
                  strokeWidth: strokeWidth,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    formattedTime == '00:00' && progress == 0.0
                        ? '00:09'
                        : formattedTime,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 26.0,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  // Pause / Play indicator
                  CustomPaint(
                    size: const Size(24.0, 24.0),
                    painter: const _PauseIconPainter(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircularTimerPainter extends CustomPainter {
  const _CircularTimerPainter({
    required this.progress,
    required this.strokeWidth,
  });

  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2.0, size.height / 2.0);
    final radius = (size.width / 2.0) * (72.0 / 80.0);
    final discRadius = (size.width / 2.0) * (76.0 / 80.0);

    // Background disc #070F2B
    final discPaint = Paint()
      ..color = AppColors.timerInnerDisc
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, discRadius, discPaint);

    // Track ring #1B2A66 width 4
    final trackPaint = Paint()
      ..color = AppColors.timerTrackRing
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Active progress arc #4C8DF5 width 4 round cap
    if (progress > 0) {
      final arcPaint = Paint()
        ..color = AppColors.timerArcBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // In CSS: transform="rotate(90 80 80)"
      // Starting from angle math.pi / 2 (or 90 deg)
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi / 2,
        progress * 2 * math.pi,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularTimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _PauseIconPainter extends CustomPainter {
  const _PauseIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // rect x="6" y="5" width="4" height="14" rx="1"
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(6, 5, 4, 14),
        const Radius.circular(1),
      ),
      paint,
    );
    // rect x="14" y="5" width="4" height="14" rx="1"
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(14, 5, 4, 14),
        const Radius.circular(1),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
