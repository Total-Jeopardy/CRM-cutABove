import 'package:cut_above/core/supabase/supabase_provider.dart';

class AuditRepository {
  Future<void> log({
    required String shopId,
    required String action,
    required String changedByName,
    String? oldValue,
    String? newValue,
  }) async {
    try {
      await supabaseClient.from('shop_audit').insert({
        'shop_id': shopId,
        'action': action,
        'changed_by': supabaseClient.auth.currentUser!.id,
        'changed_by_name': changedByName,
        'old_value': oldValue,
        'new_value': newValue,
      });
    } catch (_) {
      // Audit failure must never break the main flow
    }
  }

  Future<List<Map<String, dynamic>>> fetchForShop(String shopId) async {
    final data = await supabaseClient
        .from('shop_audit')
        .select()
        .eq('shop_id', shopId)
        .order('created_at', ascending: true);
    return (data as List)
        .map((j) => Map<String, dynamic>.from(j as Map))
        .toList();
  }
}
