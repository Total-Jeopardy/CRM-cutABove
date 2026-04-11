/// Corner radius tokens — HymNa PRD v1.0 §7.4.
///
/// Values are logical pixels (dp) per PRD.
abstract final class AppRadii {
  AppRadii._();

  /// PRD `radius.sm` — 4dp. Tags, small chips.
  static const double sm = 4;

  /// PRD `radius.md` — 8dp. Buttons, inputs.
  static const double md = 8;

  /// PRD `radius.lg` — 12dp. Cards (HymnCard, CategoryCard).
  static const double lg = 12;

  /// PRD `radius.xl` — 20dp. Bottom sheets.
  static const double xl = 20;

  /// PRD `radius.pill` — 999dp. Segmented controls, HymnalChip, TagChip.
  static const double pill = 999;
}
