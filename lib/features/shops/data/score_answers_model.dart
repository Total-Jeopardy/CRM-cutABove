class ScoreAnswersModel {
  const ScoreAnswersModel({
    this.id,
    required this.shopId,
    required this.workers,
    required this.cashier,
    required this.tracking,
    required this.ownerMet,
    required this.reaction,
    required this.establishment,
    required this.flow,
  });

  final String? id;
  final String shopId;
  final int workers;
  final int cashier;
  final int tracking;
  final int ownerMet;
  final int reaction;
  final int establishment;
  final int flow;

  int get total =>
      workers +
      cashier +
      tracking +
      ownerMet +
      reaction +
      establishment +
      flow;

  factory ScoreAnswersModel.fromJson(Map<String, dynamic> j) =>
      ScoreAnswersModel(
        id: j['id'] as String?,
        shopId: j['shop_id'] as String,
        workers: j['workers'] as int? ?? 0,
        cashier: j['cashier'] as int? ?? 0,
        tracking: j['tracking'] as int? ?? 0,
        ownerMet: j['owner_met'] as int? ?? 0,
        reaction: j['reaction'] as int? ?? 0,
        establishment: j['establishment'] as int? ?? 0,
        flow: j['flow'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'shop_id': shopId,
        'workers': workers,
        'cashier': cashier,
        'tracking': tracking,
        'owner_met': ownerMet,
        'reaction': reaction,
        'establishment': establishment,
        'flow': flow,
      };

  ScoreAnswersModel copyWith({
    String? id,
    String? shopId,
    int? workers,
    int? cashier,
    int? tracking,
    int? ownerMet,
    int? reaction,
    int? establishment,
    int? flow,
  }) =>
      ScoreAnswersModel(
        id: id ?? this.id,
        shopId: shopId ?? this.shopId,
        workers: workers ?? this.workers,
        cashier: cashier ?? this.cashier,
        tracking: tracking ?? this.tracking,
        ownerMet: ownerMet ?? this.ownerMet,
        reaction: reaction ?? this.reaction,
        establishment: establishment ?? this.establishment,
        flow: flow ?? this.flow,
      );
}
