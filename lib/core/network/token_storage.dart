/// Persists auth tokens for [DioClient] interceptors.
abstract class TokenStorage {
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();

  Future<void> saveTokens(String access, String refresh);

  Future<void> clearTokens();
}
