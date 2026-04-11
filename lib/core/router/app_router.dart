import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cut_above/core/components/app_shell.dart';
import 'package:cut_above/core/router/app_routes.dart';
import 'package:cut_above/core/router/placeholder_route_screen.dart';
import 'package:cut_above/features/auth/domain/auth_state.dart';
import 'package:cut_above/features/auth/presentation/auth_providers.dart';
import 'package:cut_above/features/auth/presentation/login_screen.dart';

/// Notifies [GoRouter] when [authNotifierProvider] changes so [redirect] runs again.
final class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref.listen<AuthState>(
      authNotifierProvider,
      (_, _) => notifyListeners(),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(authNotifierProvider);

  final refresh = GoRouterRefreshStream(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authNotifierProvider);
      final path = state.matchedLocation;
      final onLogin = path == AppRoutes.login;

      if ((auth is AuthInitial || auth is AuthError) && !onLogin) {
        return AppRoutes.login;
      }
      if (auth is AuthAuthenticated && onLogin) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          _buildTabRoute(path: AppRoutes.home, page: PlaceholderPage.home),
          _buildTabRoute(path: AppRoutes.search, page: PlaceholderPage.search),
          _buildTabRoute(
            path: AppRoutes.favorites,
            page: PlaceholderPage.favorites,
          ),
          _buildTabRoute(
            path: AppRoutes.discover,
            page: PlaceholderPage.discover,
          ),
          _buildTabRoute(
            path: AppRoutes.settings,
            page: PlaceholderPage.settings,
          ),
        ],
      ),
    ],
  );
});

GoRoute _buildTabRoute({required String path, required PlaceholderPage page}) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => NoTransitionPage<void>(
      child: PlaceholderRouteScreen(page: page, useScaffold: false),
    ),
  );
}
