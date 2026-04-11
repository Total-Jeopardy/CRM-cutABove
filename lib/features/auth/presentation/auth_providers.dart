import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cut_above/core/auth/token_storage_provider.dart';
import 'package:cut_above/core/network/api_result.dart';
import 'package:cut_above/core/network/dio_providers.dart';
import 'package:cut_above/features/auth/data/auth_repository.dart';
import 'package:cut_above/features/auth/domain/auth_state.dart';

part 'auth_notifier.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioClientProvider));
});

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
