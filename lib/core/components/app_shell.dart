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
    if (location == AppRoutes.shops ||
        location.startsWith('${AppRoutes.shops}/')) {
      return 1;
    }
    if (location == AppRoutes.map || location.startsWith('${AppRoutes.map}/')) {
      return 2;
    }
    if (location == AppRoutes.settings ||
        location.startsWith('${AppRoutes.settings}/')) {
      return 3;
    }
    return 0;
  }

  static String locationForTabIndex(int index) {
    switch (index) {
      case 0:
        return AppRoutes.dashboard;
      case 1:
        return AppRoutes.shops;
      case 2:
        return AppRoutes.map;
      case 3:
        return AppRoutes.settings;
      default:
        return AppRoutes.dashboard;
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
    final currentIndex = tabIndexForLocation(location);

    void onDestinationSelected(int index) {
      _onTabSelected(context, index);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return Scaffold(
            backgroundColor: colors.surfaceBackground,
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NavigationRail(
                  selectedIndex: currentIndex,
                  onDestinationSelected: onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.storefront_outlined),
                      selectedIcon: Icon(Icons.storefront),
                      label: Text('Shops'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.map_outlined),
                      selectedIcon: Icon(Icons.map),
                      label: Text('Map'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: child),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: colors.surfaceBackground,
          body: child,
          bottomNavigationBar: AppBottomNav(
            currentIndex: currentIndex,
            onTap: onDestinationSelected,
          ),
        );
      },
    );
  }
}
