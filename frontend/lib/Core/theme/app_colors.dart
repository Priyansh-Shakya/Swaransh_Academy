import 'package:flutter/material.dart';

/// Brand palette derived from the Swaransh Academy logo:
/// ink navy (treble clef / figure), antique gold (violin/mic gradient),
/// warm ivory (background). One theme only - no light/dark split.
class AppColors {
  AppColors._();

  // ---- Brand ----
  static const Color navy = Color(0xFF1C2B4A); // primary
  static const Color navyDark = Color(0xFF101A2E); // pressed/dark variant
  static const Color gold = Color(0xFFC28E3A); // secondary / accents
  static const Color goldLight = Color(0xFFE3C281); // gold tints, highlights
  static const Color ivory = Color(0xFFFBF6EC); // background
  static const Color ivoryDeep = Color(0xFFF3EBDA); // cards, subtle contrast

  // ---- Department accents ----
  // Used as badge/chip colors so a department reads instantly, not just as text.
  static const Color deptMusic = navy;
  static const Color deptDance = Color(0xFFC9587A); // rose
  static const Color deptActing = Color(0xFF3C8C7A); // teal-green
  static const Color deptProduction = Color(0xFFD9A23B); // mustard
  static const Color deptOther = Color(0xFF6B6E7A); // neutral slate

  static Color departmentColor(String department) {
    switch (department) {
      case 'Music':
        return deptMusic;
      case 'Dance':
        return deptDance;
      case 'Acting':
        return deptActing;
      case 'Music_Video_Production':
        return deptProduction;
      default:
        return deptOther;
    }
  }

  // ---- Status ----
  static const Color success = Color(0xFF3C8C5A);
  static const Color warning = Color(0xFFD9A23B);
  static const Color error = Color(0xFFC1473B);
  static const Color pendingPayment = Color(0xFFD9A23B);
  static const Color active = Color(0xFF3C8C5A);
  static const Color inactive = Color(0xFF6B6E7A);

  // ---- Text ----
  static const Color textPrimary = Color(0xFF1C2B4A);
  static const Color textSecondary = Color(0xFF5B6378);
  static const Color textOnNavy = ivory;
  static const Color textOnGold = navyDark;

  // ---- Surfaces / lines ----
  static const Color surface = Colors.white;
  static const Color divider = Color(0xFFE3D9C4);
  static const Color staffLine = Color(0xFFC28E3A); // for the staff-line divider motif
}
