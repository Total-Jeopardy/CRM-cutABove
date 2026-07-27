import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cut_above/core/components/app_shell.dart';
import 'package:cut_above/core/router/app_routes.dart';
import 'package:cut_above/features/auth/domain/auth_state.dart';
import 'package:cut_above/features/auth/presentation/auth_providers.dart';
import 'package:cut_above/features/auth/presentation/login_screen.dart';
import 'package:cut_above/features/shops/presentation/shop_detail_screen.dart';
import 'package:cut_above/features/shops/presentation/shop_form_screen.dart';
import 'package:cut_above/features/dashboard/dashboard_screen.dart';
import 'package:cut_above/features/map/map_screen.dart';
import 'package:cut_above/features/settings/presentation/settings_screen.dart';
import 'package:cut_above/features/shops/presentation/shops_list_screen.dart';

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
  // Do not watch auth here: rebuilding GoRouter on every auth transition
  // disposes navigation state and can trigger debugger breaks. Redirects
  // still run via [GoRouterRefreshStream] + refreshListenable.
  final refresh = GoRouterRefreshStream(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authNotifierProvider);
      final path = state.matchedLocation;
      final onLogin = path == AppRoutes.login;

      if ((auth is AuthInitial || auth is AuthError) && !onLogin) {
        return AppRoutes.login;
      }
      if (auth is AuthAuthenticated && onLogin) {
        return AppRoutes.dashboard;
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
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.shopAdd,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              child: const ShopFormScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.shopEdit,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              child: ShopFormScreen(
                shopId: state.pathParameters['id']!,
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.shopDetail,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              child: ShopDetailScreen(
                shopId: state.pathParameters['id']!,
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.shops,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              child: const ShopsListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.map,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              child: const MapScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});
