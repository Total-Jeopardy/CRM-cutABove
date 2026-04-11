import 'package:flutter/material.dart';

/// Typography tokens — HymNa PRD v1.0 §7.2.
///
/// Uses platform default font (no extra font packages).
abstract final class AppTypography {
  AppTypography._();

  static const FontWeight _bold = FontWeight.w700;

  /// PRD `type.h1` — 32sp bold. Screen titles (not used in header).
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: _bold,
  );

  /// PRD `type.h2` — 28sp bold. Major section titles.
  static const TextStyle h2 = TextStyle(
    fontSize: 28,
    fontWeight: _bold,
  );

  /// PRD `type.h3` — 24sp bold. Detail screen title in AppDetailHeader.
  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: _bold,
  );

  /// PRD `type.bodyLg` — 18sp regular. HymnListRow primary title.
  static const TextStyle bodyLg = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
  );

  /// PRD `type.bodyMd` — 16sp regular. Standard body text.
  static const TextStyle bodyMd = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  /// Alias matching common UI naming; same as [bodyMd] (PRD uses `bodyMd`).
  static const TextStyle body = bodyMd;

  /// PRD `type.bodySm` — 14sp regular. Secondary / subdued text.
  static const TextStyle bodySm = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  /// PRD `type.caption` — 12sp regular. Bottom nav labels.
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  // --- Lyrics (PRD §7.2 `type.lyrics` + settings presets) ---

  /// Hive / Text & Display presets — PRD §3.3 `settings.fontSize`: 16sp.
  static const double lyricsSp16 = 16;

  /// 18sp.
  static const double lyricsSp18 = 18;

  /// 20sp.
  static const double lyricsSp20 = 20;

  /// 22sp.
  static const double lyricsSp22 = 22;

  /// 24sp.
  static const double lyricsSp24 = 24;

  /// Ordered presets matching PRD: 16 / 18 / 20 / 22 / 24 sp.
  static const List<double> lyricsFontSizesSp = <double>[
    lyricsSp16,
    lyricsSp18,
    lyricsSp20,
    lyricsSp22,
    lyricsSp24,
  ];

  /// PRD `type.lyrics`: base [TextStyle] for VerseBlock lines at [fontSizeSp].
  /// Actual size comes from user settings (one of [lyricsFontSizesSp]).
  static TextStyle lyrics({required double fontSizeSp}) => TextStyle(
        fontSize: fontSizeSp,
        fontWeight: FontWeight.w400,
      );
}
