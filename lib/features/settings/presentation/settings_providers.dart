import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cut_above/features/settings/data/profile_repository.dart';
import 'package:cut_above/features/shops/data/profile_model.dart';

final profileRepositoryProvider =
    Provider<ProfileRepository>((_) => ProfileRepository());

final teamProvider = FutureProvider<List<ProfileModel>>((ref) {
  return ref.read(profileRepositoryProvider).fetchTeam();
});

final currentProfileProvider = FutureProvider<ProfileModel?>((ref) {
  return ref.read(profileRepositoryProvider).fetchCurrentUser();
});
