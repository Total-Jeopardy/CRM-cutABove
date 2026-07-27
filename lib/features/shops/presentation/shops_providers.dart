import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cut_above/features/auth/domain/auth_state.dart';
import 'package:cut_above/features/auth/presentation/auth_providers.dart';
import 'package:cut_above/features/shops/data/audit_repository.dart';
import 'package:cut_above/features/shops/data/note_model.dart';
import 'package:cut_above/features/shops/data/notes_repository.dart';
import 'package:cut_above/features/shops/data/score_answers_model.dart';
import 'package:cut_above/features/shops/data/shop_model.dart';
import 'package:cut_above/features/shops/data/shops_repository.dart';

final shopsRepositoryProvider =
    Provider<ShopsRepository>((_) => ShopsRepository());

final notesRepositoryProvider =
    Provider<NotesRepository>((_) => NotesRepository());

/// Re-fetches when [authNotifierProvider] transitions (e.g. session restored).
final shopsListProvider =
    AsyncNotifierProvider<ShopsListNotifier, List<ShopModel>>(
  ShopsListNotifier.new,
);

class ShopsListNotifier extends AsyncNotifier<List<ShopModel>> {
  @override
  Future<List<ShopModel>> build() async {
    final auth = ref.watch(authNotifierProvider);
    if (auth is! AuthAuthenticated) {
      return <ShopModel>[];
    }
    return ref.read(shopsRepositoryProvider).fetchAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final auth = ref.read(authNotifierProvider);
      if (auth is! AuthAuthenticated) {
        return <ShopModel>[];
      }
      return ref.read(shopsRepositoryProvider).fetchAll();
    });
  }
}

final shopDetailProvider =
    FutureProvider.family<ShopModel, String>((ref, id) {
  return ref.read(shopsRepositoryProvider).fetchOne(id);
});

final shopScoreAnswersProvider =
    FutureProvider.family<ScoreAnswersModel?, String>((ref, shopId) {
  return ref.read(shopsRepositoryProvider).fetchAnswers(shopId);
});

typedef ShopFormBundle = ({ShopModel shop, ScoreAnswersModel? answers});

final shopFormBundleProvider =
    FutureProvider.autoDispose.family<ShopFormBundle, String>((ref, id) async {
  final shops = ref.read(shopsRepositoryProvider);
  final shop = await shops.fetchOne(id);
  final answers = await shops.fetchAnswers(id);
  return (shop: shop, answers: answers);
});

final shopNotesProvider =
    FutureProvider.family<List<NoteModel>, String>((ref, shopId) {
  return ref.read(notesRepositoryProvider).fetchForShop(shopId);
});

final shopAuditProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, shopId) {
  return AuditRepository().fetchForShop(shopId);
});

final repNamesProvider = Provider<AsyncValue<List<String>>>((ref) {
  return ref.watch(shopsListProvider).whenData((shops) {
    final names = shops
        .map((s) => s.createdByName ?? 'Unknown')
        .toSet()
        .toList()
      ..sort();
    return names;
  });
});
