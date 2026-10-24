import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Circular countdown / progress timer calibrated directly from Measuring.png.
class CircularTimer extends StatelessWidget {
  const CircularTimer({
    super.key,
    required this.duration,
    required this.elapsed,
    this.isPaused = false,
    this.onTogglePause,
    this.diameter = 145.0,
    this.strokeWidth = 3.5,
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
              // Custom painted track and active arc
              CustomPaint(
                size: Size(diameter, diameter),
                painter: _CircularTimerPainter(
                  progress: progress,
                  strokeWidth: strokeWidth,
                  innerDiscColor: AppColors.timerInnerDisc,
                  trackColor: AppColors.timerTrackRing,
                  arcColor: AppColors.timerArcBlue,
                ),
              ),
              // Inner timer content (Time and Pause/Play icon)
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    formattedTime,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 28.0,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Icon(
                    isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: AppColors.textPrimary,
                    size: 20.0,
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
    required this.innerDiscColor,
    required this.trackColor,
    required this.arcColor,
  });

  final double progress;
  final double strokeWidth;
  final Color innerDiscColor;
  final Color trackColor;
  final Color arcColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 1. Draw inner solid disc
    final discPaint = Paint()
      ..color = innerDiscColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, discPaint);

    // 2. Draw inactive track ring
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // 3. Draw active progress arc (starting from -90 deg / 12 o'clock clockwise)
    if (progress > 0.0) {
      final arcPaint = Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularTimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.innerDiscColor != innerDiscColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.arcColor != arcColor;
  }
}
