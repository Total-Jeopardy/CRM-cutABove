import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cut_above/core/network/token_storage.dart';
import 'package:cut_above/core/storage/secure_token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return SecureTokenStorage();
});
