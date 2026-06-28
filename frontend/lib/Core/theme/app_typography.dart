import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Display face: Fraunces - warm, slightly old-world serif, echoes the
/// logo's script wordmark. Used with restraint: page titles, hero text,
/// section headers. Never body copy or form labels.
///
/// Body face: Manrope - clean humanist sans, stays legible at small sizes.
/// Used for everything else: body text, labels, buttons, form fields.
class AppTypography {
  AppTypography._();

  static TextStyle _display({
    required double size,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle _body({
    required double size,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // ---- Display (Fraunces) ----
  static TextStyle displayLarge = _display(size: 40, weight: FontWeight.w600, height: 1.15);
  static TextStyle displayMedium = _display(size: 32, weight: FontWeight.w600, height: 1.18);
  static TextStyle headlineLarge = _display(size: 26, weight: FontWeight.w600, height: 1.22);
  static TextStyle headlineMedium = _display(size: 22, weight: FontWeight.w600, height: 1.25);
  static TextStyle titleLarge = _display(size: 18, weight: FontWeight.w600, height: 1.3);

  // ---- Body (Manrope) ----
  static TextStyle bodyLarge = _body(size: 16, height: 1.4);
  static TextStyle bodyMedium = _body(size: 14, height: 1.4);
  static TextStyle bodySmall = _body(
    size: 12.5,
    height: 1.4,
    color: AppColors.textSecondary,
  );
  static TextStyle label = _body(
    size: 13,
    weight: FontWeight.w600,
    letterSpacing: 0.2,
    color: AppColors.textSecondary,
  );
  static TextStyle button = _body(
    size: 15,
    weight: FontWeight.w700,
    letterSpacing: 0.2,
  );
  static TextStyle caption = _body(
    size: 11.5,
    weight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );
}
