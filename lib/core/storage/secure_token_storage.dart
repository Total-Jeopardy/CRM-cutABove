import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:cut_above/core/network/token_storage.dart';

/// Persists JWTs with platform secure storage (encrypted prefs on Android).
class SecureTokenStorage implements TokenStorage {
  static const String _accessKey = 'access_token';
  static const String _refreshKey = 'refresh_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      // Encrypted prefs were requested for the template; v10+ migrates legacy storage automatically.
      // ignore: deprecated_member_use
      encryptedSharedPreferences: true,
    ),
  );

  @override
  Future<String?> getAccessToken() => _storage.read(key: _accessKey);

  @override
  Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);

  @override
  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
