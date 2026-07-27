class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.fullName,
    required this.role,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String role;
  final DateTime? createdAt;

  factory ProfileModel.fromJson(Map<String, dynamic> j) => ProfileModel(
        id: j['id'] as String,
        fullName: j['full_name'] as String? ?? 'Unknown',
        role: j['role'] as String? ?? 'field',
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'role': role,
      };
}
