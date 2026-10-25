import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum CircleIconType { back, profile, notifications, close, custom }

/// 56 px circular icon button matching design canvas header actions.
/// Background: #0B1840, border: 0, icon stroke: 1.6 #FFFFFF.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    this.type = CircleIconType.custom,
    this.icon,
    required this.onPressed,
    this.semanticLabel,
    this.backgroundColor = AppColors.headerCircleBg,
    this.iconColor = AppColors.textPrimary,
    this.size = 56.0,
    this.iconSize = 24.0,
  });

  final CircleIconType type;
  final IconData? icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: type != CircleIconType.custom
                ? CustomPaint(
                    size: Size(iconSize, iconSize),
                    painter: _HeaderIconPainter(type: type, color: iconColor),
                  )
                : Icon(icon ?? Icons.circle, color: iconColor, size: iconSize),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconPainter extends CustomPainter {
  const _HeaderIconPainter({required this.type, required this.color});

  final CircleIconType type;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final scaleX = size.width / 24.0;
    final scaleY = size.height / 24.0;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    switch (type) {
      case CircleIconType.back:
        // M15 5l-7 7 7 7
        final p = Path();
        p.moveTo(15, 5);
        p.lineTo(8, 12);
        p.lineTo(15, 19);
        canvas.drawPath(p, strokePaint);
        break;

      case CircleIconType.profile:
        // circle cx="12" cy="8" r="4"
        canvas.drawCircle(const Offset(12, 8), 4, strokePaint);
        // path M4 21c1-5 15-5 16 0
        final p = Path();
        p.moveTo(4, 21);
        p.cubicTo(5, 16, 19, 16, 20, 21);
        canvas.drawPath(p, strokePaint);
        break;

      case CircleIconType.notifications:
        // path M6 17V11a6 6 0 0112 0v6l2 2H4z
        final p = Path();
        p.moveTo(6, 17);
        p.lineTo(6, 11);
        p.cubicTo(6, 7.7, 8.7, 5, 12, 5);
        p.cubicTo(15.3, 5, 18, 7.7, 18, 11);
        p.lineTo(18, 17);
        p.lineTo(20, 19);
        p.lineTo(4, 19);
        p.close();
        canvas.drawPath(p, strokePaint);
        break;

      case CircleIconType.close:
        final p = Path();
        p.moveTo(6, 6);
        p.lineTo(18, 18);
        p.moveTo(18, 6);
        p.lineTo(6, 18);
        canvas.drawPath(p, strokePaint);
        break;

      case CircleIconType.custom:
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HeaderIconPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.color != color;
  }
}
