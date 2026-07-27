import 'package:flutter/material.dart';

/// Foundation is still dark ink + light surfaces, but the brand and data
/// visuals use intentional color — not a strictly monochrome UI.
abstract final class AppColors {
  AppColors._();

  /// Primary brand — deep ink with a blue undertone (headers, emphasis).
  static const Color brandPrimary = Color(0xFF101828);

  /// Accent — teal for CTAs, selected chips, key highlights.
  static const Color brandAccent = Color(0xFF0F9D8A);

  /// Gradient / secondary brand — deep blue-slate (pairs with [brandAccent] teal).
  static const Color brandPrimaryLight = Color(0xFF1B4B6B);

  /// Soft tinted wash for panels (subtle cool mist, not flat gray).
  static const Color brandSurface = Color(0xFFF0F7FF);

  static const Color surfaceBgLight = Color(0xFFFFFFFF);
  static const Color surfaceBgDark = Color(0xFF0C0E14);
  static const Color surfaceCardLight = Color(0xFFF8FAFD);
  static const Color surfaceCardDark = Color(0xFF151822);

  static const Color textPrimaryLight = Color(0xFF101828);
  static const Color textPrimaryDark = Color(0xFFF2F4F8);
  static const Color textSecondaryLight = Color(0xFF5C6B7A);
  static const Color textSecondaryDark = Color(0xFF9CA8B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  /// On teal / light accent fills.
  static const Color textOnAccent = Color(0xFFFFFFFF);

  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color borderMedium = Color(0xFFCBD5E1);

  static const Color semanticError = Color(0xFFDC2626);
  static const Color semanticSuccess = Color(0xFF15803D);
  static const Color semanticWarning = Color(0xFFD97706);

  /// Tier ramp: warm copper → amber → teal → cool slate (readable, not neon).
  static const Color scoreHot = Color(0xFFC2410C);
  static const Color scoreWarm = Color(0xFFD97706);
  static const Color scoreNurture = Color(0xFF0F766E);
  static const Color scoreCold = Color(0xFF64748B);

  /// Positive completion state — aligns with success family.
  static const Color statusEnrolled = Color(0xFF047857);
}
