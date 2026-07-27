part of 'auth_providers.dart';

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repo;

  @override
  AuthState build() {
    _repo = ref.read(authRepositoryProvider);

    final sub = supabaseClient.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      final current = state;
      if (user != null) {
        if (current is AuthLoading) return;
        if (current is! AuthAuthenticated) {
          state = AuthAuthenticated(user: user);
        } else if (current.user.id != user.id) {
          state = AuthAuthenticated(user: user);
        }
      } else if (current is AuthAuthenticated) {
        state = const AuthInitial();
      }
    });
    ref.onDispose(sub.cancel);

    final user = _repo.currentUser;
    return user != null
        ? AuthAuthenticated(user: user)
        : const AuthInitial();
  }

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    final result = await _repo.signIn(email: email, password: password);

    switch (result) {
      case ApiSuccess(:final data):
        state = AuthAuthenticated(user: data);
        try {
          await ref.read(profileRepositoryProvider).upsertProfile(
                fullName: data.email?.split('@').first ?? 'User',
                role: 'field',
              );
        } catch (_) {
          // Profile table / RLS may block; auth still succeeds.
        }
        ref.invalidate(currentProfileProvider);
        ref.invalidate(teamProvider);
      case ApiError(:final message):
        state = AuthError(message);
    }
  }

  Future<void> logout() async {
    await _repo.signOut();
    state = const AuthInitial();
  }
}
