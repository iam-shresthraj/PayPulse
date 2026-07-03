import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // ── Base Unit: 4px ──
  static const double unit = 4.0;

  // ── Padding & Margins ──
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // ── Layout Tokens (from DESIGN.md) ──
  static const double containerPadding = 20.0;
  static const double gutter = 16.0;
  static const double stackSm = 8.0;
  static const double stackMd = 16.0;
  static const double stackLg = 32.0;
  static const double sectionGap = 48.0;

  // ── Hit Zone ──
  static const double minTapTarget = 44.0;

  // ── Horizontal Spacing Widgets ──
  static const SizedBox hXs = SizedBox(width: xs);
  static const SizedBox hSm = SizedBox(width: sm);
  static const SizedBox hMd = SizedBox(width: md);
  static const SizedBox hLg = SizedBox(width: lg);
  static const SizedBox hXl = SizedBox(width: xl);
  static const SizedBox hXxl = SizedBox(width: xxl);

  // ── Vertical Spacing Widgets ──
  static const SizedBox vXs = SizedBox(height: xs);
  static const SizedBox vSm = SizedBox(height: sm);
  static const SizedBox vMd = SizedBox(height: md);
  static const SizedBox vLg = SizedBox(height: lg);
  static const SizedBox vXl = SizedBox(height: xl);
  static const SizedBox vXxl = SizedBox(height: xxl);
  static const SizedBox vXxxl = SizedBox(height: xxxl);
  static const SizedBox vSection = SizedBox(height: sectionGap);

  // ── Border Radii ──
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0; // ROUND_TWENTY directive
  static const double radiusXxl = 24.0;
  static const double radiusFull = 9999.0;

  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(radiusXl);
  static final BorderRadius borderRadiusXxl = BorderRadius.circular(radiusXxl);
  static final BorderRadius borderRadiusFull = BorderRadius.circular(radiusFull);

  // ── Common Padding ──
  static const EdgeInsets paddingAll = EdgeInsets.all(containerPadding);
  static const EdgeInsets paddingH = EdgeInsets.symmetric(horizontal: containerPadding);
  static const EdgeInsets paddingV = EdgeInsets.symmetric(vertical: containerPadding);
  static const EdgeInsets paddingCard = EdgeInsets.all(lg);
  static const EdgeInsets paddingCardCompact = EdgeInsets.symmetric(horizontal: lg, vertical: md);
}
