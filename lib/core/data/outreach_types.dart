abstract final class OutreachTypes {
  static const List<String> all = [
    'In Person',
    'Phone Call',
    'WhatsApp',
    'Instagram',
    'Referral',
  ];

  /// Emoji icons (Unicode escapes avoid editor/tooling mojibake).
  static const Map<String, String> icons = {
    'In Person': '\u{1F6B6}',
    'Phone Call': '\u{1F4DE}',
    'WhatsApp': '\u{1F4AC}',
    'Instagram': '\u{1F4F8}',
    'Referral': '\u{1F91D}',
  };
}
