import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Display ──
  static TextStyle get displayLg => GoogleFonts.poppins(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: AppColors.onBackground,
        letterSpacing: -0.02 * 48,
        height: 56 / 48,
      );

  // ── Headlines ──
  static TextStyle get headlineLg => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: AppColors.onBackground,
        height: 40 / 32,
      );

  static TextStyle get headlineLgMobile => GoogleFonts.poppins(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: AppColors.onBackground,
        height: 32 / 26,
      );

  // ── Titles ──
  static TextStyle get titleLg => GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.onBackground,
      );

  static TextStyle get titleMd => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.onBackground,
        height: 24 / 18,
      );

  static TextStyle get titleSm => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.onBackground,
      );

  // ── Body ──
  static TextStyle get bodyLg => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
        height: 24 / 16,
      );

  static TextStyle get bodyMd => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
        height: 20 / 14,
      );

  static TextStyle get bodySm => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurfaceMuted,
      );

  // ── Labels ──
  static TextStyle get labelLg => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.onBackground,
      );

  static TextStyle get labelMd => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurfaceMuted,
        letterSpacing: 0.05 * 12,
        height: 16 / 12,
      );

  static TextStyle get labelSm => GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurfaceMuted,
        letterSpacing: 0.05 * 10,
      );

  // ── Section Headers ──
  static TextStyle get sectionTitle => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.onBackground,
      );

  static TextStyle get sectionSubtitle => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurfaceMuted,
      );

  // ── Card Specific ──
  static TextStyle get cardTitle => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.onBackground,
      );

  static TextStyle get cardSubtitle => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurfaceMuted,
      );

  // ── Navigation ──
  static TextStyle get navLabel => GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurfaceMuted,
      );

  static TextStyle get navLabelActive => GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      );

  // ── Numeric / Currency (Inter for cleaner number rendering) ──
  static TextStyle get amountXl => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      );

  static TextStyle get amountLg => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      );

  static TextStyle get amount => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      );

  static TextStyle get amountMd => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.onBackground,
      );

  static TextStyle get amountSm => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      );
}
