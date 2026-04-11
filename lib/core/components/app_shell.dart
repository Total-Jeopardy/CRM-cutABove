import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cut_above/core/components/app_bottom_nav.dart';
import 'package:cut_above/core/design_system/app_color_scheme.dart';
import 'package:cut_above/core/router/app_routes.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static int tabIndexForLocation(String location) {
    if (location == AppRoutes.search ||
        location.startsWith('${AppRoutes.search}/')) {
      return 1;
    }
    if (location == AppRoutes.favorites ||
        location.startsWith('${AppRoutes.favorites}/')) {
      return 2;
    }
    if (location == AppRoutes.discover ||
        location.startsWith('${AppRoutes.discover}/')) {
      return 3;
    }
    if (location == AppRoutes.settings ||
        location.startsWith('${AppRoutes.settings}/')) {
      return 4;
    }
    return 0;
  }

  static String locationForTabIndex(int index) {
    switch (index) {
      case 0:
        return AppRoutes.home;
      case 1:
        return AppRoutes.search;
      case 2:
        return AppRoutes.favorites;
      case 3:
        return AppRoutes.discover;
      case 4:
        return AppRoutes.settings;
      default:
        return AppRoutes.home;
    }
  }

  void _onTabSelected(BuildContext context, int index) {
    final targetLocation = locationForTabIndex(index);
    if (targetLocation == location) {
      return;
    }

    context.go(targetLocation);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return Scaffold(
      backgroundColor: colors.surfaceBackground,
      body: child,
      bottomNavigationBar: AppBottomNav(
        currentIndex: tabIndexForLocation(location),
        onTap: (index) => _onTabSelected(context, index),
      ),
    );
  }
}
