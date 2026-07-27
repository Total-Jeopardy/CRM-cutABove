import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:cut_above/core/data/outreach_types.dart';
import 'package:cut_above/core/design_system/app_color_scheme.dart';
import 'package:cut_above/core/design_system/app_colors.dart';
import 'package:cut_above/core/design_system/app_radii.dart';
import 'package:cut_above/core/design_system/app_section_header.dart';
import 'package:cut_above/core/design_system/app_spacing.dart';
import 'package:cut_above/core/design_system/app_typography.dart';
import 'package:cut_above/core/router/app_routes.dart';
import 'package:cut_above/core/supabase/supabase_provider.dart';
import 'package:cut_above/core/utils/responsive.dart';
import 'package:cut_above/core/utils/string_extensions.dart';
import 'package:cut_above/features/dashboard/dashboard_providers.dart';
import 'package:cut_above/features/shops/data/shop_model.dart';
import 'package:cut_above/features/shops/presentation/shops_providers.dart';

void _navigateShops(
  BuildContext context, {
  String? filter,
  String? status,
  bool overdue = false,
  String? rep,
  String? outreach,
  String? area,
}) {
  final q = <String, String>{};
  if (filter != null) q['filter'] = filter;
  if (status != null) q['status'] = status;
  if (overdue) q['overdue'] = '1';
  if (rep != null) q['rep'] = rep;
  if (outreach != null) q['outreach'] = outreach;
  if (area != null) q['area'] = area;
  final uri = Uri(
    path: AppRoutes.shops,
    queryParameters: q.isEmpty ? null : q,
  );
  context.go(uri.toString());
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _firstName(String? email) {
    if (email == null || email.isEmpty) return 'there';
    return email.split('@').first.split('.').first.capitalize();
  }

  Widget _metricCard({
    required AppColorScheme colors,
    required String label,
    required int value,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    final child = Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySm.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$value',
              style: AppTypography.h2.copyWith(
                color: valueColor ?? AppColors.brandPrimary,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: child,
      ),
    );
  }

  Widget _metricSkeleton() => Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.surfaceCardLight,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        height: 88,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final statsAsync = ref.watch(dashboardStatsProvider);
    final overdueAsync = ref.watch(overdueShopsProvider);
    final email = supabaseClient.auth.currentUser?.email;
    final dateStr = DateFormat('EEEE, d MMMM y', 'en').format(DateTime.now());

    return Scaffold(
      backgroundColor: colors.surfaceBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: colors.headerBackground,
        foregroundColor: colors.headerContent,
        title: Text(
          'CutAbove CRM',
          style: AppTypography.h3.copyWith(color: colors.headerContent),
        ),
      ),
      body: statsAsync.when(
        loading: () => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.space4),
          child: Responsive.constrained(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: AppSpacing.space3,
                  mainAxisSpacing: AppSpacing.space3,
                  childAspectRatio: 2.0,
                  children: [
                    _metricSkeleton(),
                    _metricSkeleton(),
                    _metricSkeleton(),
                    _metricSkeleton(),
                  ],
                ),
              ],
            ),
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  e.toString(),
                  style: AppTypography.bodyMd.copyWith(
                    color: colors.semanticError,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.space4),
                FilledButton(
                  onPressed: () => ref.invalidate(shopsListProvider),
                  child: Text(
                    'Retry',
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (stats) {
          final overdue = switch (overdueAsync) {
            AsyncData(:final value) => value,
            _ => <ShopModel>[],
          };
          final funnel = <(String, int)>[
            ('Visited', stats.visited),
            ('Interested', stats.interested),
            ('Demo Booked', stats.demoBooked),
            ('Committed', stats.funnelCommitted),
            ('Enrolled', stats.funnelEnrolled),
          ];
          final areaRows = stats.byArea.entries.toList()
            ..sort((a, b) => b.value.total.compareTo(a.value.total));
          final outreachRows = stats.byOutreach.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return RefreshIndicator(
            color: AppColors.brandPrimary,
            onRefresh: () async {
              ref.invalidate(shopsListProvider);
              await ref.read(shopsListProvider.future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(AppSpacing.space4),
              child: Responsive.constrained(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.space5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.brandPrimary,
                            AppColors.brandPrimaryLight,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppRadii.xl),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _firstName(email),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: AppColors.brandAccent,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const AppSectionHeader(title: 'Pipeline'),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: AppSpacing.space3,
                      mainAxisSpacing: AppSpacing.space3,
                      // Taller cells on narrow widths so label + h2 value + padding fit
                      childAspectRatio:
                          MediaQuery.sizeOf(context).width < 400 ? 1.35 : 1.75,
                      children: [
                        _metricCard(
                          colors: colors,
                          label: 'Total shops',
                          value: stats.total,
                          onTap: () => _navigateShops(context),
                        ),
                        _metricCard(
                          colors: colors,
                          label: 'Hot leads',
                          value: stats.hot,
                          valueColor: AppColors.scoreHot,
                          onTap: () => _navigateShops(context, filter: 'Hot'),
                        ),
                        _metricCard(
                          colors: colors,
                          label: 'Committed',
                          value: stats.committed,
                          onTap: () =>
                              _navigateShops(context, status: 'Committed'),
                        ),
                        _metricCard(
                          colors: colors,
                          label: 'Enrolled',
                          value: stats.enrolled,
                          valueColor: AppColors.brandAccent,
                          onTap: () =>
                              _navigateShops(context, filter: 'Enrolled'),
                        ),
                      ],
                    ),
                    const AppSectionHeader(title: 'By score tier'),
                    LayoutBuilder(
                      builder: (context, c) {
                        final gap = AppSpacing.space2;
                        final tileWidth = (c.maxWidth - gap) / 2;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            SizedBox(
                              width: tileWidth,
                              child: _tierMiniCard(
                                'Hot',
                                stats.hot,
                                AppColors.scoreHot,
                                colors,
                                () => _navigateShops(context, filter: 'Hot'),
                              ),
                            ),
                            SizedBox(
                              width: tileWidth,
                              child: _tierMiniCard(
                                'Warm',
                                stats.warm,
                                AppColors.scoreWarm,
                                colors,
                                () => _navigateShops(context, filter: 'Warm'),
                              ),
                            ),
                            SizedBox(
                              width: tileWidth,
                              child: _tierMiniCard(
                                'Nurture',
                                stats.nurture,
                                AppColors.scoreNurture,
                                colors,
                                () =>
                                    _navigateShops(context, filter: 'Nurture'),
                              ),
                            ),
                            SizedBox(
                              width: tileWidth,
                              child: _tierMiniCard(
                                'Cold',
                                stats.cold,
                                AppColors.scoreCold,
                                colors,
                                () => _navigateShops(context, filter: 'Cold'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const AppSectionHeader(title: 'Conversion funnel'),
                    ...List.generate(funnel.length, (i) {
                      final item = funnel[i];
                      final denomI = (funnel.length - 1).clamp(1, 999);
                      final opacity = 0.25 + (i / denomI) * 0.75;
                      final denom = stats.total > 0 ? stats.total : 1;
                      final frac = item.$2 / denom;
                      return Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.space3),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (item.$1 == 'Enrolled') {
                                _navigateShops(context, filter: 'Enrolled');
                              } else {
                                _navigateShops(context, status: item.$1);
                              }
                            },
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.space1,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item.$1,
                                        style: AppTypography.bodySm.copyWith(
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${item.$2}',
                                        style: AppTypography.bodySm.copyWith(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: AppSpacing.space2),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.sm,
                                    ),
                                    child: LinearProgressIndicator(
                                      value: frac.clamp(0.0, 1.0),
                                      minHeight: AppSpacing.space3,
                                      backgroundColor: colors.borderSubtle,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        AppColors.brandPrimary.withValues(
                                          alpha: opacity.clamp(0.0, 1.0),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    Padding(
                      padding: EdgeInsets.only(
                        top: AppSpacing.space5,
                        bottom: AppSpacing.space2,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: stats.overdueFollowups > 0
                              ? () => _navigateShops(context, overdue: true)
                              : null,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.space1,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'FOLLOW-UP NEEDED',
                                    style: AppTypography.caption.copyWith(
                                      color: colors.textSecondary,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (stats.overdueFollowups > 0)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppSpacing.space3,
                                      vertical: AppSpacing.space1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandAccent.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.pill,
                                      ),
                                    ),
                                    child: Text(
                                      '${stats.overdueFollowups}',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.brandAccent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (overdue.isEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: AppSpacing.space2),
                        child: Text(
                          'No overdue follow-ups',
                          style: AppTypography.bodyMd.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      )
                    else
                      ...overdue.map(
                        (shop) => _overdueCard(context, shop, colors),
                      ),
                    const AppSectionHeader(title: 'Greater Accra breakdown'),
                    Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.space2),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Area',
                              style: AppTypography.caption.copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Total',
                              style: AppTypography.caption.copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Enrolled',
                              style: AppTypography.caption.copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '%',
                              style: AppTypography.caption.copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...areaRows.map((e) {
                      final a = e.value;
                      final pct = a.total == 0
                          ? 0.0
                          : (a.enrolled / a.total * 100);
                      return Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.space3),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () =>
                                _navigateShops(context, area: e.key),
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.space1,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      e.key,
                                      style: AppTypography.bodySm.copyWith(
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${a.total}',
                                      style: AppTypography.bodySm.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${a.enrolled}',
                                      style: AppTypography.bodySm.copyWith(
                                        color: a.enrolled > 0
                                            ? AppColors.brandPrimary
                                            : colors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${pct.toStringAsFixed(0)}%',
                                      style: AppTypography.bodySm.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    if (areaRows.isEmpty)
                      Text(
                        'No area data yet',
                        style: AppTypography.bodySm.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    if (stats.byRep.length > 1) ...[
                      SizedBox(height: AppSpacing.space6),
                      const AppSectionHeader(title: 'By team member'),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.space2,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Member',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: Text(
                                'Visited',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondaryLight,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: Text(
                                'Committed',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondaryLight,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: Text(
                                'Enrolled',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondaryLight,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      ...stats.byRep.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.space2,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () =>
                                  _navigateShops(context, rep: e.key),
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSpacing.space1,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        e.key,
                                        style: AppTypography.bodySm,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        '${e.value.visited}',
                                        style: AppTypography.bodySm,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        '${e.value.committed}',
                                        style: AppTypography.bodySm,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        '${e.value.enrolled}',
                                        style: e.value.enrolled > 0
                                            ? AppTypography.bodySm.copyWith(
                                                color: AppColors.brandPrimary,
                                                fontWeight: FontWeight.w600,
                                              )
                                            : AppTypography.bodySm,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (stats.byOutreach.length > 1) ...[
                      SizedBox(height: AppSpacing.space6),
                      const AppSectionHeader(title: 'By outreach channel'),
                      ...outreachRows.map(
                        (e) {
                          final pct = stats.total == 0
                              ? 0.0
                              : e.value / stats.total;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.space2,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _navigateShops(
                                  context,
                                  outreach: e.key,
                                ),
                                borderRadius:
                                    BorderRadius.circular(AppRadii.sm),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: AppSpacing.space1,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 100,
                                        child: Text(
                                          '${OutreachTypes.icons[e.key] ?? ''} ${e.key}',
                                          style: AppTypography.bodySm,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            AppRadii.sm,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: pct.clamp(0.0, 1.0),
                                            minHeight: 8,
                                            backgroundColor:
                                                AppColors.brandSurface,
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                    Color>(
                                              AppColors.brandPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: AppSpacing.space3),
                                      Text(
                                        '${e.value}',
                                        style: AppTypography.bodySm.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.brandPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    SizedBox(height: AppSpacing.space8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tierMiniCard(
    String label,
    int count,
    Color tierColor,
    AppColorScheme colors,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: tierColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$count', style: AppTypography.h3.copyWith(color: tierColor)),
              SizedBox(height: AppSpacing.space1),
              Text(
                label,
                style: AppTypography.bodySm.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overdueCard(
    BuildContext context,
    ShopModel shop,
    AppColorScheme colors,
  ) {
    final dateStr = shop.followupDate == null
        ? ''
        : DateFormat.yMMMd().format(shop.followupDate!.toLocal());
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.space2),
      child: Material(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: () => context.push('/shops/${shop.id}'),
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            padding: EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.shopName,
                        style: AppTypography.bodyMd.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        shop.ownerName,
                        style: AppTypography.bodySm.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  dateStr,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.brandAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
