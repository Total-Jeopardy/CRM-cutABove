import 'package:supabase_flutter/supabase_flutter.dart';

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
  AuthAuthenticated({required this.user});

  final User user;
}

final class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;
}
