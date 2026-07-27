import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cut_above/core/network/api_result.dart';
import 'package:cut_above/core/supabase/supabase_provider.dart';
import 'package:cut_above/features/auth/data/auth_repository.dart';
import 'package:cut_above/features/auth/domain/auth_state.dart';
import 'package:cut_above/features/settings/presentation/settings_providers.dart';

part 'auth_notifier.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
