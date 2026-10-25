import 'package:flutter/material.dart';

/// Calibrated color tokens extracted directly from design canvas images.
class AppColors {
  const AppColors._();

  // Base canvas and corner glows
  static const Color bgBase = Color(0xFF04030C);
  static const Color bgGlowTopLeft = Color(0xFF1A0F44);
  static const Color bgGlowBottomRight = Color(0xFF3A1566);

  // Surface and card tokens
  static const Color cardBgNavy = Color(0xFF0B1840);
  static const Color cardBgGradientStart = Color(0xFF0F2160);
  static const Color cardBgGradientEnd = Color(0xFF08122E);
  static const Color cardBorder = Color(0xFF3B4270);
  static const Color cardAiGradientStart = Color(0xFF4A1A8F);
  static const Color cardAiGradientEnd = Color(0xFF0F2160);

  // Feature and timer tokens
  static const Color timerArcBlue = Color(0xFF4C8DF5);
  static const Color timerInnerDisc = Color(0xFF070F2B);
  static const Color timerTrackRing = Color(0xFF1B2A66);
  static const Color buttonStopSave = Color(0xFF0B1840);

  // Accent tokens
  static const Color accentPurple = Color(0xFF6D28D9);
  static const Color accentMagenta = Color(0xFFC0148F);
  static const Color accentMagentaAlt = Color(0xFFC026D3);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color accentCyan = Color(0xFF22D3EE);
  static const Color radarRing = Color(0xFF3A2A8F);

  // Text tokens
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9AA0C4);
  static const Color textMuted = Color(0xFF9AA0C4);
  static const Color textSubtitle = Color(0xFF6B6F95);
  static const Color navInactiveIcon = Color(0xFFC9D0F5);
  static const Color navActiveIcon = Color(0xFF0B1840);

  // Interactive component tokens
  static const Color pillWhite = Color(0xFFFFFFFF);
  static const Color pillDark = Color(0xFF0B1840);
  static const Color headerCircleBg = Color(0xFF0B1840);
  static const Color bottomCircleInactive = Color(0xFF0B1840);
  static const Color bottomCircleActive = Color(0xFFFFFFFF);
  static const Color chipBg = Colors.transparent;
  static const Color chipBorder = Color(0xFF3B4270);
  static const Color chipText = Color(0xFF9AA0C4);
}
