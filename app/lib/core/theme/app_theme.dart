import 'package:flutter/material.dart';
import 'app_colors.dart';

@immutable
class PulsePatchThemeTokens extends ThemeExtension<PulsePatchThemeTokens> {
  const PulsePatchThemeTokens({
    required this.bgBase,
    required this.bgGlowTopLeft,
    required this.bgGlowBottomRight,
    required this.cardBgNavy,
    required this.cardBgGradientStart,
    required this.cardBgGradientEnd,
    required this.cardBorder,
    required this.cardAiGradientStart,
    required this.cardAiGradientEnd,
    required this.timerArcBlue,
    required this.timerInnerDisc,
    required this.timerTrackRing,
    required this.buttonStopSave,
    required this.accentPurple,
    required this.accentMagenta,
    required this.accentBlue,
    required this.accentCyan,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  final Color bgBase;
  final Color bgGlowTopLeft;
  final Color bgGlowBottomRight;
  final Color cardBgNavy;
  final Color cardBgGradientStart;
  final Color cardBgGradientEnd;
  final Color cardBorder;
  final Color cardAiGradientStart;
  final Color cardAiGradientEnd;
  final Color timerArcBlue;
  final Color timerInnerDisc;
  final Color timerTrackRing;
  final Color buttonStopSave;
  final Color accentPurple;
  final Color accentMagenta;
  final Color accentBlue;
  final Color accentCyan;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  static const dark = PulsePatchThemeTokens(
    bgBase: AppColors.bgBase,
    bgGlowTopLeft: AppColors.bgGlowTopLeft,
    bgGlowBottomRight: AppColors.bgGlowBottomRight,
    cardBgNavy: AppColors.cardBgNavy,
    cardBgGradientStart: AppColors.cardBgGradientStart,
    cardBgGradientEnd: AppColors.cardBgGradientEnd,
    cardBorder: AppColors.cardBorder,
    cardAiGradientStart: AppColors.cardAiGradientStart,
    cardAiGradientEnd: AppColors.cardAiGradientEnd,
    timerArcBlue: AppColors.timerArcBlue,
    timerInnerDisc: AppColors.timerInnerDisc,
    timerTrackRing: AppColors.timerTrackRing,
    buttonStopSave: AppColors.buttonStopSave,
    accentPurple: AppColors.accentPurple,
    accentMagenta: AppColors.accentMagenta,
    accentBlue: AppColors.accentBlue,
    accentCyan: AppColors.accentCyan,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
  );

  static const light = PulsePatchThemeTokens(
    bgBase: Color(0xFFF8FAFC),
    bgGlowTopLeft: Color(0xFFEDE9FE),
    bgGlowBottomRight: Color(0xFFFCE7F3),
    cardBgNavy: Color(0xFFFFFFFF),
    cardBgGradientStart: Color(0xFFFFFFFF),
    cardBgGradientEnd: Color(0xFFF1F5F9),
    cardBorder: Color(0xFFE2E8F0),
    cardAiGradientStart: Color(0xFF6D28D9),
    cardAiGradientEnd: Color(0xFF2563EB),
    timerArcBlue: Color(0xFF2563EB),
    timerInnerDisc: Color(0xFFEFF6FF),
    timerTrackRing: Color(0xFFDBEAFE),
    buttonStopSave: Color(0xFF1E293B),
    accentPurple: Color(0xFF6D28D9),
    accentMagenta: Color(0xFFE11D9B),
    accentBlue: Color(0xFF2563EB),
    accentCyan: Color(0xFF0891B2),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF94A3B8),
  );

  @override
  PulsePatchThemeTokens copyWith({
    Color? bgBase,
    Color? bgGlowTopLeft,
    Color? bgGlowBottomRight,
    Color? cardBgNavy,
    Color? cardBgGradientStart,
    Color? cardBgGradientEnd,
    Color? cardBorder,
    Color? cardAiGradientStart,
    Color? cardAiGradientEnd,
    Color? timerArcBlue,
    Color? timerInnerDisc,
    Color? timerTrackRing,
    Color? buttonStopSave,
    Color? accentPurple,
    Color? accentMagenta,
    Color? accentBlue,
    Color? accentCyan,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
  }) {
    return PulsePatchThemeTokens(
      bgBase: bgBase ?? this.bgBase,
      bgGlowTopLeft: bgGlowTopLeft ?? this.bgGlowTopLeft,
      bgGlowBottomRight: bgGlowBottomRight ?? this.bgGlowBottomRight,
      cardBgNavy: cardBgNavy ?? this.cardBgNavy,
      cardBgGradientStart: cardBgGradientStart ?? this.cardBgGradientStart,
      cardBgGradientEnd: cardBgGradientEnd ?? this.cardBgGradientEnd,
      cardBorder: cardBorder ?? this.cardBorder,
      cardAiGradientStart: cardAiGradientStart ?? this.cardAiGradientStart,
      cardAiGradientEnd: cardAiGradientEnd ?? this.cardAiGradientEnd,
      timerArcBlue: timerArcBlue ?? this.timerArcBlue,
      timerInnerDisc: timerInnerDisc ?? this.timerInnerDisc,
      timerTrackRing: timerTrackRing ?? this.timerTrackRing,
      buttonStopSave: buttonStopSave ?? this.buttonStopSave,
      accentPurple: accentPurple ?? this.accentPurple,
      accentMagenta: accentMagenta ?? this.accentMagenta,
      accentBlue: accentBlue ?? this.accentBlue,
      accentCyan: accentCyan ?? this.accentCyan,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  PulsePatchThemeTokens lerp(
    ThemeExtension<PulsePatchThemeTokens>? other,
    double t,
  ) {
    if (other is! PulsePatchThemeTokens) return this;
    return PulsePatchThemeTokens(
      bgBase: Color.lerp(bgBase, other.bgBase, t)!,
      bgGlowTopLeft: Color.lerp(bgGlowTopLeft, other.bgGlowTopLeft, t)!,
      bgGlowBottomRight: Color.lerp(
        bgGlowBottomRight,
        other.bgGlowBottomRight,
        t,
      )!,
      cardBgNavy: Color.lerp(cardBgNavy, other.cardBgNavy, t)!,
      cardBgGradientStart: Color.lerp(
        cardBgGradientStart,
        other.cardBgGradientStart,
        t,
      )!,
      cardBgGradientEnd: Color.lerp(
        cardBgGradientEnd,
        other.cardBgGradientEnd,
        t,
      )!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      cardAiGradientStart: Color.lerp(
        cardAiGradientStart,
        other.cardAiGradientStart,
        t,
      )!,
      cardAiGradientEnd: Color.lerp(
        cardAiGradientEnd,
        other.cardAiGradientEnd,
        t,
      )!,
      timerArcBlue: Color.lerp(timerArcBlue, other.timerArcBlue, t)!,
      timerInnerDisc: Color.lerp(timerInnerDisc, other.timerInnerDisc, t)!,
      timerTrackRing: Color.lerp(timerTrackRing, other.timerTrackRing, t)!,
      buttonStopSave: Color.lerp(buttonStopSave, other.buttonStopSave, t)!,
      accentPurple: Color.lerp(accentPurple, other.accentPurple, t)!,
      accentMagenta: Color.lerp(accentMagenta, other.accentMagenta, t)!,
      accentBlue: Color.lerp(accentBlue, other.accentBlue, t)!,
      accentCyan: Color.lerp(accentCyan, other.accentCyan, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}

class AppTheme {
  const AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Outfit',
      scaffoldBackgroundColor: AppColors.bgBase,
      primaryColor: AppColors.accentBlue,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentBlue,
        secondary: AppColors.accentMagenta,
        surface: AppColors.cardBgNavy,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        fontFamily: 'Outfit',
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      extensions: const [PulsePatchThemeTokens.dark],
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: 'Outfit',
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      primaryColor: AppColors.accentBlue,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accentBlue,
        secondary: AppColors.accentMagenta,
        surface: Colors.white,
        onSurface: Color(0xFF0F172A),
      ),
      textTheme: ThemeData.light().textTheme.apply(
        fontFamily: 'Outfit',
        bodyColor: const Color(0xFF0F172A),
        displayColor: const Color(0xFF0F172A),
      ),
      extensions: const [PulsePatchThemeTokens.light],
    );
  }
}
