sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.userName, this.role);

  final String userName;
  final String role;
}

final class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;
}
