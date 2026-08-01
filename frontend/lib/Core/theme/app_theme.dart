import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// One theme, no light/dark split. Every value here is derived from
/// app_colors.dart / app_typography.dart - don't hardcode a color or font
/// directly on a widget if a token already exists for it.
class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.ivory,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navy,
        brightness: Brightness.light,
        primary: AppColors.navy,
        secondary: AppColors.gold,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
    );

    return base.copyWith(
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        titleLarge: AppTypography.titleLarge,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.label,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.ivory,
        foregroundColor: AppColors.navy,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMedium,
        surfaceTintColor: Colors.transparent,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.divider, width: 1),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: AppSpacing.md,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.textOnNavy,
          textStyle: AppTypography.button,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.textOnGold,
          textStyle: AppTypography.button,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          textStyle: AppTypography.button,
          side: const BorderSide(color: AppColors.navy, width: 1.4),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.navy,
          textStyle: AppTypography.button,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        errorStyle: AppTypography.bodySmall.copyWith(color: AppColors.error),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.ivoryDeep,
        labelStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.goldLight.withOpacity(0.4),
        labelTextStyle: WidgetStateProperty.all(AppTypography.caption),
        height: 64,
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.goldLight.withOpacity(0.4),
        selectedLabelTextStyle: AppTypography.caption.copyWith(
          color: AppColors.navy,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: AppTypography.caption,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navy,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textOnNavy,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: AppTypography.headlineMedium,
        contentTextStyle: AppTypography.bodyMedium,
      ),
    );
  }
}
