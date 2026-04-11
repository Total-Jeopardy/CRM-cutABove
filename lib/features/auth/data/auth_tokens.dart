class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.userName = '',
    this.role = '',
  });

  final String accessToken;
  final String refreshToken;

  /// Filled when the API includes a user object or top-level profile fields.
  final String userName;
  final String role;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    String? pickToken(Iterable<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v is String && v.isNotEmpty) return v;
      }
      return null;
    }

    final access = pickToken(const ['access_token', 'accessToken']);
    final refresh = pickToken(const ['refresh_token', 'refreshToken']);
    if (access == null || refresh == null) {
      throw const FormatException('Missing access or refresh token in login JSON');
    }

    var userName = '';
    var role = '';
    final user = json['user'];
    if (user is Map) {
      final u = Map<String, dynamic>.from(user);
      userName = u['name']?.toString() ??
          u['user_name']?.toString() ??
          u['userName']?.toString() ??
          '';
      role = u['role']?.toString() ?? '';
    }
    if (userName.isEmpty) {
      userName = json['user_name']?.toString() ?? json['userName']?.toString() ?? '';
    }
    if (role.isEmpty) {
      role = json['role']?.toString() ?? '';
    }

    return AuthTokens(
      accessToken: access,
      refreshToken: refresh,
      userName: userName.isEmpty ? 'User' : userName,
      role: role.isEmpty ? 'user' : role,
    );
  }
}
