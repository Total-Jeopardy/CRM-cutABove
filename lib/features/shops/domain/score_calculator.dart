abstract final class ScoreCalculator {
  static int calculate({
    required int workers,
    required int cashier,
    required int tracking,
    required int ownerMet,
    required int reaction,
    required int establishment,
    required int flow,
  }) =>
      workers +
      cashier +
      tracking +
      ownerMet +
      reaction +
      establishment +
      flow;

  static String tier(int score) {
    if (score >= 75) return 'Hot';
    if (score >= 50) return 'Warm';
    if (score >= 25) return 'Nurture';
    return 'Cold';
  }
}
