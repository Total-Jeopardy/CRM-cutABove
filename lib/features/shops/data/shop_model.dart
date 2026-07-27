class ShopModel {
  const ShopModel({
    required this.id,
    required this.createdAt,
    required this.createdBy,
    required this.shopName,
    required this.ownerName,
    this.phone,
    this.whatsapp,
    this.area,
    this.coordinatesLat,
    this.coordinatesLng,
    required this.status,
    required this.score,
    required this.outreachType,
    this.followupDate,
    this.enrolledAt,
    this.tenantId,
    this.notesCount = 0,
    this.photoUrl,
    this.createdByName,
    this.lastUpdatedByName,
    this.lastUpdatedBy,
    this.updatedAt,
  });

  final String id;
  final DateTime createdAt;
  final String createdBy;
  final String shopName;
  final String ownerName;
  final String? phone;
  final String? whatsapp;
  final String? area;
  final double? coordinatesLat;
  final double? coordinatesLng;
  final String status;
  final int score;
  final String outreachType;
  final DateTime? followupDate;
  final DateTime? enrolledAt;
  final String? tenantId;
  final int notesCount;
  final String? photoUrl;
  final String? createdByName;
  final String? lastUpdatedByName;
  final String? lastUpdatedBy;
  final DateTime? updatedAt;

  bool get isEnrolled => enrolledAt != null;

  bool get isFollowupOverdue =>
      followupDate != null &&
      followupDate!.isBefore(DateTime.now()) &&
      !isEnrolled;

  String get scoreTier {
    if (score >= 75) return 'Hot';
    if (score >= 50) return 'Warm';
    if (score >= 25) return 'Nurture';
    return 'Cold';
  }

  factory ShopModel.fromJson(Map<String, dynamic> j) => ShopModel(
        id: j['id'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
        createdBy: j['created_by'] as String? ?? '',
        shopName: j['shop_name'] as String,
        ownerName: j['owner_name'] as String,
        phone: j['phone'] as String?,
        whatsapp: j['whatsapp'] as String?,
        area: j['area'] as String?,
        coordinatesLat: (j['coordinates_lat'] as num?)?.toDouble(),
        coordinatesLng: (j['coordinates_lng'] as num?)?.toDouble(),
        status: j['status'] as String? ?? 'Visited',
        score: (j['score'] as num?)?.toInt() ?? 0,
        outreachType: j['outreach_type'] as String? ?? 'In Person',
        followupDate: j['followup_date'] != null
            ? DateTime.parse(j['followup_date'] as String)
            : null,
        enrolledAt: j['enrolled_at'] != null
            ? DateTime.parse(j['enrolled_at'] as String)
            : null,
        tenantId: j['tenant_id'] as String?,
        notesCount: (j['notes_count'] as num?)?.toInt() ?? 0,
        photoUrl: j['photo_url'] as String?,
        createdByName: j['created_by_name'] as String?,
        lastUpdatedByName: j['last_updated_by_name'] as String?,
        lastUpdatedBy: j['last_updated_by'] as String?,
        updatedAt: j['updated_at'] != null
            ? DateTime.parse(j['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'shop_name': shopName,
        'owner_name': ownerName,
        'phone': phone,
        'whatsapp': whatsapp,
        'area': area,
        'coordinates_lat': coordinatesLat,
        'coordinates_lng': coordinatesLng,
        'status': status,
        'score': score,
        'outreach_type': outreachType,
        'followup_date': followupDate?.toIso8601String().split('T').first,
        'enrolled_at': enrolledAt?.toIso8601String(),
        'tenant_id': tenantId,
        'photo_url': photoUrl,
        'created_by_name': createdByName,
        'last_updated_by': lastUpdatedBy,
        'last_updated_by_name': lastUpdatedByName,
      };

  ShopModel copyWith({
    String? id,
    DateTime? createdAt,
    String? createdBy,
    String? shopName,
    String? ownerName,
    String? phone,
    String? whatsapp,
    String? area,
    double? coordinatesLat,
    double? coordinatesLng,
    String? status,
    int? score,
    String? outreachType,
    DateTime? followupDate,
    DateTime? enrolledAt,
    String? tenantId,
    int? notesCount,
    String? photoUrl,
    String? createdByName,
    String? lastUpdatedByName,
    String? lastUpdatedBy,
    DateTime? updatedAt,
  }) =>
      ShopModel(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        createdBy: createdBy ?? this.createdBy,
        shopName: shopName ?? this.shopName,
        ownerName: ownerName ?? this.ownerName,
        phone: phone ?? this.phone,
        whatsapp: whatsapp ?? this.whatsapp,
        area: area ?? this.area,
        coordinatesLat: coordinatesLat ?? this.coordinatesLat,
        coordinatesLng: coordinatesLng ?? this.coordinatesLng,
        status: status ?? this.status,
        score: score ?? this.score,
        outreachType: outreachType ?? this.outreachType,
        followupDate: followupDate ?? this.followupDate,
        enrolledAt: enrolledAt ?? this.enrolledAt,
        tenantId: tenantId ?? this.tenantId,
        notesCount: notesCount ?? this.notesCount,
        photoUrl: photoUrl ?? this.photoUrl,
        createdByName: createdByName ?? this.createdByName,
        lastUpdatedByName: lastUpdatedByName ?? this.lastUpdatedByName,
        lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
