import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cut_above/core/design_system/app_color_scheme.dart';
import 'package:cut_above/features/auth/domain/auth_state.dart';
import 'package:cut_above/features/auth/presentation/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return Scaffold(
      backgroundColor: colors.surfaceBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sign in',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: colors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    autocorrect: false,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      labelStyle: TextStyle(color: colors.textSecondary),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: colors.borderSubtle),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: colors.accentIndicator),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autocorrect: false,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: colors.textSecondary),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: colors.borderSubtle),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: colors.accentIndicator),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: colors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                  ),
                  if (auth case AuthError(:final message)) ...[
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.semanticError,
                          ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: auth is AuthLoading
                        ? null
                        : () {
                            final phone = _phoneController.text.trim();
                            final password = _passwordController.text;
                            ref
                                .read(authNotifierProvider.notifier)
                                .login(phone, password);
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.accentIndicator,
                      foregroundColor: colors.textOnPrimary,
                      disabledBackgroundColor: colors.borderSubtle,
                      disabledForegroundColor: colors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: auth is AuthLoading
                        ? SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.textOnPrimary,
                            ),
                          )
                        : Text(
                            'Log in',
                            style: TextStyle(color: colors.textOnPrimary),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
