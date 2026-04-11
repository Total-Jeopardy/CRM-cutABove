import 'package:flutter/material.dart';

import 'app_color_scheme.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static const TextTheme _textTheme = TextTheme(
    displayLarge: AppTypography.h1,
    displayMedium: AppTypography.h2,
    displaySmall: AppTypography.h3,
    bodyLarge: AppTypography.bodyLg,
    bodyMedium: AppTypography.bodyMd,
    bodySmall: AppTypography.bodySm,
    labelSmall: AppTypography.caption,
  );

  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.brandPrimary,
        secondary: AppColors.brandAccent,
        surface: AppColors.surfaceBgLight,
        error: AppColors.semanticError,
      ),
      textTheme: _textTheme, // ← added
      extensions: const [AppColorScheme.light],
    );
  }

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.brandPrimary,
        secondary: AppColors.brandAccent,
        surface: AppColors.surfaceBgDark,
        error: AppColors.semanticError,
      ),
      textTheme: _textTheme,
      extensions: const [AppColorScheme.dark],
    );
  }
}
