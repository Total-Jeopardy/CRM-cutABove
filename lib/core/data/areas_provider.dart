import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cut_above/core/data/custom_areas_repository.dart';
import 'package:cut_above/core/data/greater_accra_areas.dart';

final customAreasRepositoryProvider =
    Provider<CustomAreasRepository>((_) => CustomAreasRepository());

/// Merged list: hardcoded master list + custom areas from Supabase
/// Sorted alphabetically, deduplicated, 'Other' always last
final allAreasProvider = FutureProvider<List<String>>((ref) async {
  final custom = await ref.read(customAreasRepositoryProvider).fetchAll();

  final merged = {
    ...GreaterAccraAreas.all.where((a) => a != 'Other'),
    ...custom,
  }.toList()
    ..sort();

  return [...merged, 'Other'];
});
