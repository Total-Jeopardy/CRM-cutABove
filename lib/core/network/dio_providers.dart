import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cut_above/core/auth/token_storage_provider.dart';
import 'package:cut_above/core/network/dio_client.dart';
import 'package:cut_above/features/auth/presentation/auth_providers.dart';

/// HTTP client; requires `--dart-define=API_BASE_URL=https://...`.
///
/// [onLogout] uses [ref.read] so [authNotifierProvider] is resolved only when
/// refresh fails — not while this provider is constructed.
final dioClientProvider = Provider<DioClient>((ref) {
  const baseUrl = String.fromEnvironment('API_BASE_URL');
  if (baseUrl.isEmpty) {
    throw StateError(
      'Set API_BASE_URL via --dart-define=API_BASE_URL=https://... when using dioClientProvider.',
    );
  }
  return DioClient(
    baseUrl: baseUrl,
    tokenStorage: ref.watch(tokenStorageProvider),
    onLogout: () => ref.read(authNotifierProvider.notifier).logout(),
  );
});
