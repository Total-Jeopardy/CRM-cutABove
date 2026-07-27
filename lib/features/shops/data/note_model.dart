class NoteModel {
  const NoteModel({
    this.id,
    required this.shopId,
    required this.createdAt,
    required this.createdBy,
    required this.authorName,
    required this.note,
  });

  final String? id;
  final String shopId;
  final DateTime createdAt;
  final String createdBy;
  final String authorName;
  final String note;

  factory NoteModel.fromJson(Map<String, dynamic> j) => NoteModel(
        id: j['id'] as String?,
        shopId: j['shop_id'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
        createdBy: j['created_by'] as String? ?? '',
        authorName: j['author_name'] as String? ?? 'Unknown',
        note: j['note'] as String,
      );

  Map<String, dynamic> toJson() => {
        'shop_id': shopId,
        'created_at': createdAt.toIso8601String(),
        'created_by': createdBy,
        'author_name': authorName,
        'note': note,
      };
}
