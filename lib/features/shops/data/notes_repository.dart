import 'package:cut_above/core/supabase/supabase_provider.dart';
import 'package:cut_above/features/shops/data/audit_repository.dart';
import 'package:cut_above/features/shops/data/note_model.dart';

class NotesRepository {
  final _audit = AuditRepository();

  Future<List<NoteModel>> fetchForShop(String shopId) async {
    final data = await supabaseClient
        .from('notes')
        .select()
        .eq('shop_id', shopId)
        .order('created_at', ascending: true);
    final list = data as List<dynamic>;
    return list
        .map((j) => NoteModel.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList();
  }

  Future<NoteModel> add({
    required String shopId,
    required String note,
    required String authorName,
  }) async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) {
      throw StateError('Not authenticated');
    }
    final inserted = await supabaseClient
        .from('notes')
        .insert(
          NoteModel(
            shopId: shopId,
            createdAt: DateTime.now().toUtc(),
            createdBy: user.id,
            authorName: authorName,
            note: note,
          ).toJson(),
        )
        .select()
        .single();
    await supabaseClient.rpc(
      'increment_notes_count',
      params: {'shop_id_input': shopId},
    );
    final preview =
        note.length > 80 ? '${note.substring(0, 80)}...' : note;
    await _audit.log(
      shopId: shopId,
      action: 'note_added',
      changedByName: authorName,
      newValue: preview,
    );
    return NoteModel.fromJson(Map<String, dynamic>.from(inserted));
  }
}
