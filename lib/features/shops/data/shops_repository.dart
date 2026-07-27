import 'package:cut_above/core/supabase/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cut_above/features/shops/data/audit_repository.dart';
import 'package:cut_above/features/shops/data/score_answers_model.dart';
import 'package:cut_above/features/shops/data/shop_model.dart';

class ShopsRepository {
  final _audit = AuditRepository();

  Future<List<ShopModel>> fetchAll() async {
    try {
      return await _fetchAllImpl();
    } on PostgrestException catch (e) {
      final msg = e.message.toLowerCase();
      final code = e.code ?? '';
      final looksLikeAuth = code == 'PGRST301' ||
          msg.contains('jwt') ||
          msg.contains('token') ||
          msg.contains('expired') ||
          msg.contains('not authorized');
      if (looksLikeAuth && supabaseClient.auth.currentUser != null) {
        try {
          await supabaseClient.auth.refreshSession();
        } catch (_) {}
        return _fetchAllImpl();
      }
      rethrow;
    }
  }

  Future<List<ShopModel>> _fetchAllImpl() async {
    final data = await supabaseClient
        .from('shops')
        .select()
        .order('created_at', ascending: false);
    final list = data as List<dynamic>;
    return list
        .map((j) => ShopModel.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList();
  }

  Future<ShopModel> fetchOne(String id) async {
    final data = await supabaseClient
        .from('shops')
        .select()
        .eq('id', id)
        .single();
    return ShopModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<ShopModel> create({
    required ShopModel shop,
    required ScoreAnswersModel answers,
    required String createdByName,
  }) async {
    final uid = supabaseClient.auth.currentUser!.id;
    final payload = {
      ...shop.toJson(),
      'created_by': uid,
      'created_by_name': createdByName,
      'last_updated_by': uid,
      'last_updated_by_name': createdByName,
    };
    final inserted = await supabaseClient
        .from('shops')
        .insert(payload)
        .select()
        .single();
    final created = ShopModel.fromJson(Map<String, dynamic>.from(inserted));
    await supabaseClient.from('score_answers').insert(
          answers.copyWith(shopId: created.id).toJson(),
        );
    await _audit.log(
      shopId: created.id,
      action: 'created',
      changedByName: createdByName,
      newValue: created.shopName,
    );
    return created;
  }

  Future<ShopModel> update({
    required String id,
    required ShopModel shop,
    required ScoreAnswersModel answers,
    required String updatedByName,
  }) async {
    final uid = supabaseClient.auth.currentUser!.id;
    final payload = {
      ...shop.toJson(),
      'last_updated_by': uid,
      'last_updated_by_name': updatedByName,
    };
    await supabaseClient.from('shops').update(payload).eq('id', id);
    await supabaseClient.from('score_answers').upsert(
          answers.copyWith(shopId: id).toJson(),
          onConflict: 'shop_id',
        );
    await _audit.log(
      shopId: id,
      action: 'updated',
      changedByName: updatedByName,
    );
    return fetchOne(id);
  }

  Future<void> markEnrolled({
    required String id,
    required String tenantId,
    required String enrolledByName,
  }) async {
    final uid = supabaseClient.auth.currentUser!.id;
    await supabaseClient.from('shops').update({
      'enrolled_at': DateTime.now().toIso8601String(),
      'tenant_id': tenantId,
      'status': 'Enrolled',
      'last_updated_by': uid,
      'last_updated_by_name': enrolledByName,
    }).eq('id', id);
    await _audit.log(
      shopId: id,
      action: 'enrolled',
      changedByName: enrolledByName,
      newValue: tenantId,
    );
  }

  Future<void> delete(String id) async {
    await supabaseClient.from('shops').delete().eq('id', id);
  }

  Future<ScoreAnswersModel?> fetchAnswers(String shopId) async {
    final data = await supabaseClient
        .from('score_answers')
        .select()
        .eq('shop_id', shopId)
        .maybeSingle();
    if (data == null) return null;
    return ScoreAnswersModel.fromJson(Map<String, dynamic>.from(data));
  }
}
