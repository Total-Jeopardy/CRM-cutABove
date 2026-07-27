import 'package:flutter/material.dart';

import 'package:cut_above/core/design_system/app_typography.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final barTheme = Theme.of(context).bottomNavigationBarTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: barTheme.backgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: barTheme.type ?? BottomNavigationBarType.fixed,
        backgroundColor: barTheme.backgroundColor,
        selectedItemColor: barTheme.selectedItemColor,
        unselectedItemColor: barTheme.unselectedItemColor,
        elevation: barTheme.elevation ?? 0,
        selectedLabelStyle: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.caption,
        iconSize: 24,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined, size: 24),
            activeIcon: Icon(Icons.dashboard, size: 24),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined, size: 24),
            activeIcon: Icon(Icons.storefront, size: 24),
            label: 'Shops',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined, size: 24),
            activeIcon: Icon(Icons.map, size: 24),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined, size: 24),
            activeIcon: Icon(Icons.settings, size: 24),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
