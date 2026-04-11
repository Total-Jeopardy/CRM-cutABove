import 'package:flutter/material.dart';

abstract final class AppColors {
  AppColors._();

  // --- Brand ---

  /// PRD `brand.primary` — Navy. Header backgrounds, primary buttons.
  static const Color brandPrimary = Color(0xFF1B3A5C);

  /// PRD `brand.accent` — Gold. Active indicators, highlights.
  static const Color brandAccent = Color(0xFFC9A84C);

  // --- Surfaces ---

  /// PRD `surface.bg` — light.
  static const Color surfaceBgLight = Color(0xFFFFFFFF);

  /// PRD `surface.bg` — dark.
  static const Color surfaceBgDark = Color(0xFF0F2035);

  /// PRD `surface.card` — light.
  static const Color surfaceCardLight = Color(0xFFF0F4F8);

  /// PRD `surface.card` — dark.
  static const Color surfaceCardDark = Color(0xFF1A2E45);

  // --- Text ---

  /// PRD `text.primary` — light.
  static const Color textPrimaryLight = Color(0xFF111111);

  /// PRD `text.primary` — dark.
  static const Color textPrimaryDark = Color(0xFFF0F4F8);

  /// PRD `text.secondary` — light.
  static const Color textSecondaryLight = Color(0xFF666666);

  /// PRD `text.secondary` — dark.
  static const Color textSecondaryDark = Color(0xFFA0B0C0);

  /// PRD `text.onPrimary` — always white on navy.
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // --- Border ---

  /// PRD `border.subtle` — dividers (single locked hex).
  static const Color borderSubtle = Color(0xFFD0DCE8);

  // --- Semantic ---

  /// PRD `semantic.error` — error states.
  static const Color semanticError = Color(0xFFC0392B);

  /// PRD `semantic.success` — success states.
  static const Color semanticSuccess = Color(0xFF1A7A4A);
}
