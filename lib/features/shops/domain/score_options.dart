class ScoreOption {
  const ScoreOption({required this.label, required this.points});

  final String label;
  final int points;
}

abstract final class ScoreOptions {
  static const workers = [
    ScoreOption(label: '1–3 workers', points: 10),
    ScoreOption(label: '4–8 workers', points: 20),
    ScoreOption(label: '9+ workers', points: 30),
  ];

  static const cashier = [
    ScoreOption(label: 'Yes — dedicated cashier', points: 10),
    ScoreOption(label: 'No — barbers handle payment', points: 0),
  ];

  static const tracking = [
    ScoreOption(label: 'Exercise book / manual', points: 15),
    ScoreOption(label: 'Memory / nothing', points: 15),
    ScoreOption(label: 'Phone notes / WhatsApp', points: 10),
    ScoreOption(label: 'Another app', points: 5),
  ];

  static const ownerMet = [
    ScoreOption(label: 'Yes — spoke to owner directly', points: 10),
    ScoreOption(label: 'No — spoke to cashier or barber', points: 0),
  ];

  static const reaction = [
    ScoreOption(label: 'Very interested — asked questions', points: 15),
    ScoreOption(label: 'Curious — open to hearing more', points: 10),
    ScoreOption(label: 'Neutral — polite but guarded', points: 5),
    ScoreOption(label: 'Dismissive — not interested', points: 0),
  ];

  static const establishment = [
    ScoreOption(label: 'Permanent location, branded signage', points: 10),
    ScoreOption(label: 'Established but basic setup', points: 7),
    ScoreOption(label: 'New or informal', points: 3),
  ];

  static const flow = [
    ScoreOption(label: 'Busy — most chairs occupied', points: 10),
    ScoreOption(label: 'Moderate — some activity', points: 6),
    ScoreOption(label: 'Quiet — few customers', points: 3),
    ScoreOption(label: 'Empty during visit', points: 0),
  ];
}
