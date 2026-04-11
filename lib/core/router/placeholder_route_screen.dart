import 'package:flutter/material.dart';

import 'package:cut_above/core/design_system/app_color_scheme.dart';
import 'package:cut_above/core/design_system/app_spacing.dart';

import 'app_routes.dart';

enum PlaceholderPage {
  home('Home', AppRoutes.home),
  search('Search', AppRoutes.search),
  favorites('Favorites', AppRoutes.favorites),
  discover('Discover', AppRoutes.discover),
  settings('Settings', AppRoutes.settings);

  const PlaceholderPage(this.title, this.pathPattern);

  final String title;

  final String pathPattern;
}

class PlaceholderRouteScreen extends StatelessWidget {
  const PlaceholderRouteScreen({
    super.key,
    required this.page,
    this.detail,
    this.useScaffold = true,
  });

  final PlaceholderPage page;
  final String? detail;
  final bool useScaffold;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final content = _PlaceholderRouteContent(page: page, detail: detail);

    if (!useScaffold) {
      return ColoredBox(
        color: colors.surfaceBackground,
        child: SafeArea(child: content),
      );
    }

    return Scaffold(
      backgroundColor: colors.surfaceBackground,
      appBar: AppBar(
        backgroundColor: colors.headerBackground,
        foregroundColor: colors.headerContent,
        title: Text(page.title),
      ),
      body: content,
    );
  }
}

class _PlaceholderRouteContent extends StatelessWidget {
  const _PlaceholderRouteContent({required this.page, this.detail});

  final PlaceholderPage page;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: colors.textPrimary),
            ),
            if (detail != null && detail!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.space4),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
              ),
            ],
            const SizedBox(height: AppSpacing.space6),
            Text(
              page.pathPattern,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              'Placeholder',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: colors.accentIndicator),
            ),
          ],
        ),
      ),
    );
  }
}
