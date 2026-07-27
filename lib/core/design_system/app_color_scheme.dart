import 'package:flutter/material.dart';

import 'app_colors.dart';

@immutable
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  const AppColorScheme({
    required this.headerBackground,
    required this.headerContent,
    required this.surfaceBackground,
    required this.surfaceCard,
    required this.textPrimary,
    required this.textSecondary,
    required this.textOnPrimary,
    required this.borderSubtle,
    required this.accentIndicator,
    required this.semanticError,
    required this.semanticSuccess,
    required this.swipeFavoriteBackground,
  });

  final Color headerBackground;
  final Color headerContent;
  final Color surfaceBackground;
  final Color surfaceCard;
  final Color textPrimary;
  final Color textSecondary;
  final Color textOnPrimary;
  final Color borderSubtle;
  final Color accentIndicator;
  final Color semanticError;
  final Color semanticSuccess;
  final Color swipeFavoriteBackground;

  /// Light theme mapping.
  static const light = AppColorScheme(
    headerBackground: AppColors.brandPrimary,
    headerContent: AppColors.textOnPrimary,
    surfaceBackground: AppColors.surfaceBgLight,
    surfaceCard: AppColors.surfaceCardLight,
    textPrimary: AppColors.textPrimaryLight,
    textSecondary: AppColors.textSecondaryLight,
    textOnPrimary: AppColors.textOnPrimary,
    borderSubtle: AppColors.borderSubtle,
    accentIndicator: AppColors.brandAccent,
    semanticError: AppColors.semanticError,
    semanticSuccess: AppColors.semanticSuccess,
    swipeFavoriteBackground: Color(0x33FFD600),
  );

  /// Dark theme mapping.
  static const dark = AppColorScheme(
    headerBackground: AppColors.brandPrimary,
    headerContent: AppColors.textOnPrimary,
    surfaceBackground: AppColors.surfaceBgDark,
    surfaceCard: AppColors.surfaceCardDark,
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    textOnPrimary: AppColors.textOnPrimary,
    borderSubtle: AppColors.borderSubtle,
    accentIndicator: AppColors.brandAccent,
    semanticError: AppColors.semanticError,
    semanticSuccess: AppColors.semanticSuccess,
    swipeFavoriteBackground: Color(0x33FFD600),
  );

  @override
  AppColorScheme copyWith({
    Color? headerBackground,
    Color? headerContent,
    Color? surfaceBackground,
    Color? surfaceCard,
    Color? textPrimary,
    Color? textSecondary,
    Color? textOnPrimary,
    Color? borderSubtle,
    Color? accentIndicator,
    Color? semanticError,
    Color? semanticSuccess,
    Color? swipeFavoriteBackground,
  }) {
    return AppColorScheme(
      headerBackground: headerBackground ?? this.headerBackground,
      headerContent: headerContent ?? this.headerContent,
      surfaceBackground: surfaceBackground ?? this.surfaceBackground,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textOnPrimary: textOnPrimary ?? this.textOnPrimary,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      accentIndicator: accentIndicator ?? this.accentIndicator,
      semanticError: semanticError ?? this.semanticError,
      semanticSuccess: semanticSuccess ?? this.semanticSuccess,
      swipeFavoriteBackground:
          swipeFavoriteBackground ?? this.swipeFavoriteBackground,
    );
  }

  @override
  AppColorScheme lerp(AppColorScheme? other, double t) {
    if (other == null) return this;
    return AppColorScheme(
      headerBackground: Color.lerp(
        headerBackground,
        other.headerBackground,
        t,
      )!,
      headerContent: Color.lerp(headerContent, other.headerContent, t)!,
      surfaceBackground: Color.lerp(
        surfaceBackground,
        other.surfaceBackground,
        t,
      )!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textOnPrimary: Color.lerp(textOnPrimary, other.textOnPrimary, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      accentIndicator: Color.lerp(accentIndicator, other.accentIndicator, t)!,
      semanticError: Color.lerp(semanticError, other.semanticError, t)!,
      semanticSuccess: Color.lerp(semanticSuccess, other.semanticSuccess, t)!,
      swipeFavoriteBackground: Color.lerp(
        swipeFavoriteBackground,
        other.swipeFavoriteBackground,
        t,
      )!,
    );
  }
}
