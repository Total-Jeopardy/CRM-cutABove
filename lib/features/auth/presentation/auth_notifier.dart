part of 'auth_providers.dart';

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthInitial();

  Future<void> login(String phone, String password) async {
    state = const AuthLoading();
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.login(phone, password);

    switch (result) {
      case ApiSuccess(:final data):
        await ref.read(tokenStorageProvider).saveTokens(
              data.accessToken,
              data.refreshToken,
            );
        state = AuthAuthenticated(data.userName, data.role);
      case ApiError(:final message):
        state = AuthError(message);
    }
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clearTokens();
    state = const AuthInitial();
  }
}
