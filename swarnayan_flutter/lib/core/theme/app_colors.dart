import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static bool isLight = false;

  static void useLightMode(bool light) {
    isLight = light;
  }

  // ── Base Backgrounds ──
  static Color get background => isLight ? const Color(0xFFF6F8FA) : const Color(0xFF000000);
  static Color get surface => isLight ? const Color(0xFFFFFFFF) : const Color(0xFF131313);
  static Color get surfaceDim => isLight ? const Color(0xFFF1F3F5) : const Color(0xFF0D0D0D);
  static Color get surfaceContainer => isLight ? const Color(0xFFEAEEF2) : const Color(0xFF1A1A1A);
  static Color get surfaceContainerHigh => isLight ? const Color(0xFFE1E6EB) : const Color(0xFF2A2A2A);
  static Color get surfaceContainerHighest => isLight ? const Color(0xFFD5DCE3) : const Color(0xFF353534);

  // ── Primary (PayPulse Red #C10303) ──
  static Color get primary => const Color(0xFFC10303);
  static Color get primaryLight => const Color(0xFFE02D2D);
  static Color get primaryDark => const Color(0xFF8B0000);
  static Color get primaryContainer => isLight ? const Color(0xFFFEECEF) : const Color(0xFF3B0101);

  // ── Text ──
  static Color get onBackground => isLight ? const Color(0xFF1F2328) : const Color(0xFFFFFFFF);
  static Color get onSurface => isLight ? const Color(0xFF24292F) : const Color(0xFFE0E0E0);
  static Color get onSurfaceMuted => isLight ? const Color(0xFF57606A) : const Color(0xFFA0A0A0);
  static Color get onSurfaceDim => isLight ? const Color(0xFF8C959F) : const Color(0xFF666666);

  // ── Borders ──
  static Color get border => isLight ? const Color(0xFFD0D7DE) : const Color(0xFF2A2A2A);
  static Color get borderLight => isLight ? const Color(0xFFE1E4E6) : const Color(0xFF3A3A3A);

  // ── Glassmorphism ──
  static Color get glassBackground => isLight ? const Color(0xE6FFFFFF) : const Color(0xB31A1A1A);
  static Color get glassBorder => isLight ? const Color(0x1F000000) : const Color(0x14FFFFFF);
  static Color get glassHighlight => isLight ? const Color(0x0A000000) : const Color(0x0DFFFFFF);
  static Color get glassShadow => isLight ? const Color(0x0F000000) : const Color(0x66000000);

  // ── Status ──
  static Color get success => const Color(0xFF2ECC71);
  static Color get error => const Color(0xFFE74C3C);
  static Color get warning => const Color(0xFFFF8C00);
  static Color get info => const Color(0xFF3498DB);

  // ── Status Badges ──
  static Color get paid => const Color(0xFF2ECC71);
  static Color get partial => const Color(0xFFFF8C00);
  static Color get pending => const Color(0xFFE74C3C);

  // ── Tier Colors ──
  static Color get tierGold => const Color(0xFFC5A059);
  static Color get tierSilver => const Color(0xFFC0C0C0);
  static Color get tierBronze => const Color(0xFFCD7F32);

  // ── Premium Gradients ──
  static List<Color> get primaryGradient => const [
    Color(0xFFC10303),
    Color(0xFFE02D2D),
  ];

  static List<Color> get primaryGradientSoft => const [
    Color(0xFFC10303),
    Color(0xFFF35151),
  ];

  static List<Color> get darkGradient => isLight 
      ? const [Color(0xFFFFFFFF), Color(0xFFF6F8FA)]
      : const [Color(0xFF1A1A1A), Color(0xFF000000)];

  static List<Color> get glassGradient => isLight
      ? const [Color(0x0A000000), Color(0x02000000)]
      : const [Color(0x1AFFFFFF), Color(0x05FFFFFF)];

  // ── Glow Effect ──
  static Color get primaryGlow => const Color(0xFFC10303).withValues(alpha: 0.3);
}
