import 'package:flutter/material.dart';

/// Calibrated color tokens extracted directly from design canvas images.
class AppColors {
  const AppColors._();

  // Base canvas and corner glows
  static const Color bgBase = Color(0xFF04030C);
  static const Color bgGlowTopLeft = Color(0xFF190E41);
  static const Color bgGlowBottomRight = Color(0xFF381463);

  // Surface and card tokens
  static const Color cardBgNavy = Color(0xFF0B1947);
  static const Color cardBgGradientStart = Color(0xFF0C1A4A);
  static const Color cardBgGradientEnd = Color(0xFF0B1844);
  static const Color cardBorder = Color(0xFF1E2D60);
  static const Color cardAiGradientStart = Color(0xFF451A8B);
  static const Color cardAiGradientEnd = Color(0xFF112061);

  // Feature and timer tokens
  static const Color timerArcBlue = Color(0xFF4C8DF5);
  static const Color timerInnerDisc = Color(0xFF070F2B);
  static const Color timerTrackRing = Color(0xFF1B2A66);
  static const Color buttonStopSave = Color(0xFF0B1840);

  // Accent tokens
  static const Color accentPurple = Color(0xFF6D28D9);
  static const Color accentMagenta = Color(0xFFE11D9B);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color accentCyan = Color(0xFF22D3EE);

  // Text tokens
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Interactive component tokens
  static const Color pillWhite = Color(0xFFFFFFFF);
  static const Color pillDark = Color(0xFF0F1C3F);
  static const Color headerCircleBg = Color(0xFF0F172A);
  static const Color bottomCircleInactive = Color(0xFF0D1632);
  static const Color bottomCircleActive = Color(0xFFFFFFFF);
  static const Color chipBg = Color(0xFF0B1229);
  static const Color chipBorder = Color(0xFF1E2B52);
}
