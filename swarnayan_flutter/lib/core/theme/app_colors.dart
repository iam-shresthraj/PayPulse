import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Base Backgrounds ──
  static const Color background = Color(0xFF000000); // Pure Black (OLED)
  static const Color surface = Color(0xFF131313);
  static const Color surfaceDim = Color(0xFF0D0D0D);
  static const Color surfaceContainer = Color(0xFF1A1A1A);
  static const Color surfaceContainerHigh = Color(0xFF2A2A2A);
  static const Color surfaceContainerHighest = Color(0xFF353534);

  // ── Primary (Dark Orange) ──
  static const Color primary = Color(0xFFFF8C00);
  static const Color primaryLight = Color(0xFFFFB77D);
  static const Color primaryDark = Color(0xFFCC7000);
  static const Color primaryContainer = Color(0xFF3D2200);

  // ── Text ──
  static const Color onBackground = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFFE0E0E0);
  static const Color onSurfaceMuted = Color(0xFFA0A0A0);
  static const Color onSurfaceDim = Color(0xFF666666);

  // ── Borders ──
  static const Color border = Color(0xFF2A2A2A);
  static const Color borderLight = Color(0xFF3A3A3A);

  // ── Glassmorphism ──
  static const Color glassBackground = Color(0xB31A1A1A); // #1A1A1A at 70%
  static const Color glassBorder = Color(0x14FFFFFF); // white at 8%
  static const Color glassHighlight = Color(0x0DFFFFFF); // white at 5%
  static const Color glassShadow = Color(0x66000000); // black at 40%

  // ── Status ──
  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFFF8C00);
  static const Color info = Color(0xFF3498DB);

  // ── Status Badges ──
  static const Color paid = Color(0xFF2ECC71);
  static const Color partial = Color(0xFFFF8C00);
  static const Color pending = Color(0xFFE74C3C);

  // ── Tier Colors ──
  static const Color tierGold = Color(0xFFFF8C00);
  static const Color tierSilver = Color(0xFFC0C0C0);
  static const Color tierBronze = Color(0xFFCD7F32);

  // ── Premium Gradients ──
  static const List<Color> primaryGradient = [
    Color(0xFFFF8C00), // Dark Orange
    Color(0xFFFF6B00), // Fire Orange
  ];

  static const List<Color> primaryGradientSoft = [
    Color(0xFFFF8C00),
    Color(0xFFFFAA44),
  ];

  static const List<Color> darkGradient = [
    Color(0xFF1A1A1A),
    Color(0xFF000000),
  ];

  static const List<Color> glassGradient = [
    Color(0x1AFFFFFF), // white 10%
    Color(0x05FFFFFF), // white 2%
  ];

  // ── Glow Effect ──
  static Color primaryGlow = const Color(0xFFFF8C00).withValues(alpha: 0.3);
}
