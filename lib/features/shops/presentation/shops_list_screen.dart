import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cut_above/core/data/outreach_types.dart';
import 'package:cut_above/core/design_system/app_color_scheme.dart';
import 'package:cut_above/core/design_system/app_colors.dart';
import 'package:cut_above/core/design_system/app_radii.dart';
import 'package:cut_above/core/design_system/app_spacing.dart';
import 'package:cut_above/core/design_system/app_typography.dart';
import 'package:cut_above/core/router/app_routes.dart';
import 'package:cut_above/core/utils/responsive.dart';
import 'package:cut_above/features/shops/data/shop_model.dart';
import 'package:cut_above/features/shops/presentation/shops_providers.dart';

class ShopsListScreen extends ConsumerStatefulWidget {
  const ShopsListScreen({super.key});

  @override
  ConsumerState<ShopsListScreen> createState() => _ShopsListScreenState();
}

class _ShopsListScreenState extends ConsumerState<ShopsListScreen> {
  final SearchController _searchController = SearchController();
  String _filter = 'All';
  String _selectedRep = 'All';
  String _selectedOutreach = 'All';
  String _selectedArea = 'All';
  String? _statusFilter;
  bool _overdueOnly = false;
  String? _lastAppliedRouteQuery;

  static const _filters = ['All', 'Hot', 'Warm', 'Nurture', 'Cold', 'Enrolled'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = GoRouterState.of(context).uri;
    final queryKey = uri.hasQuery ? uri.query : '';
    if (queryKey == _lastAppliedRouteQuery) return;
    _lastAppliedRouteQuery = queryKey;
    if (!uri.hasQuery) {
      setState(() {
        _filter = 'All';
        _statusFilter = null;
        _overdueOnly = false;
        _selectedRep = 'All';
        _selectedOutreach = 'All';
        _selectedArea = 'All';
      });
      return;
    }
    _applyRouteQuery(uri.queryParameters);
  }

  void _applyRouteQuery(Map<String, String> q) {
    setState(() {
      _filter = 'All';
      _statusFilter = null;
      _overdueOnly = false;
      _selectedRep = 'All';
      _selectedOutreach = 'All';
      _selectedArea = 'All';

      if (q['overdue'] == '1') {
        _overdueOnly = true;
      } else if (q['status'] != null && q['status']!.isNotEmpty) {
        _statusFilter = q['status'];
      } else if (q['filter'] != null && _filters.contains(q['filter'])) {
        _filter = q['filter']!;
      }

      final rep = q['rep'];
      if (rep != null && rep.isNotEmpty) {
        _selectedRep = rep;
      }
      final outreach = q['outreach'];
      if (outreach != null && outreach.isNotEmpty) {
        _selectedOutreach = outreach;
      }
      final area = q['area'];
      if (area != null && area.isNotEmpty) {
        _selectedArea = area;
      }
    });
  }

  List<ShopModel> _filtered(
    List<ShopModel> all,
    String filter,
    String query,
    String rep,
    String outreach,
    String area,
    String? statusFilter,
    bool overdueOnly,
  ) {
    var list = all;
    if (area != 'All') {
      list = list
          .where((s) => (s.area ?? 'Unknown') == area)
          .toList();
    }
    if (rep != 'All') {
      list = list
          .where((s) => (s.createdByName ?? 'Unknown') == rep)
          .toList();
    }
    if (outreach != 'All') {
      list = list.where((s) => s.outreachType == outreach).toList();
    }
    if (statusFilter != null && statusFilter.isNotEmpty) {
      list = list.where((s) => s.status == statusFilter).toList();
    }
    if (overdueOnly) {
      list = list.where((s) => s.isFollowupOverdue).toList();
    }
    if (filter == 'Enrolled') {
      list = list.where((s) => s.isEnrolled).toList();
    } else if (filter != 'All') {
      list = list.where((s) => s.scoreTier == filter).toList();
    }
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list
          .where(
            (s) =>
                s.shopName.toLowerCase().contains(q) ||
                s.ownerName.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  Widget _outreachFilterChip(
    AppColorScheme colors,
    String label,
    String value,
    bool selected,
  ) {
    return FilterChip(
      label: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: selected ? AppColors.textOnPrimary : colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: selected,
      onSelected: (_) => setState(() => _selectedOutreach = value),
      selectedColor: AppColors.brandPrimary,
      checkmarkColor: AppColors.textOnPrimary,
      backgroundColor: colors.surfaceCard,
      side: BorderSide(
        color: selected ? AppColors.brandAccent : colors.borderSubtle,
        width: selected ? 2 : 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
    );
  }

  Widget _repFilterChip(
    AppColorScheme colors,
    String label,
    String value,
    bool selected,
  ) {
    return FilterChip(
      label: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: selected ? AppColors.textOnPrimary : colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: selected,
      onSelected: (_) => setState(() => _selectedRep = value),
      selectedColor: AppColors.brandPrimary,
      checkmarkColor: AppColors.textOnPrimary,
      backgroundColor: colors.surfaceCard,
      side: BorderSide(
        color: selected ? AppColors.brandAccent : colors.borderSubtle,
        width: selected ? 2 : 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
    );
  }

  Color _tierColor(String tier) => switch (tier) {
        'Hot' => AppColors.scoreHot,
        'Warm' => AppColors.scoreWarm,
        'Nurture' => AppColors.scoreNurture,
        _ => AppColors.scoreCold,
      };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final async = ref.watch(shopsListProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: colors.surfaceBackground,
      appBar: AppBar(
        backgroundColor: colors.headerBackground,
        foregroundColor: colors.headerContent,
        title: Text(
          'Shops',
          style: AppTypography.h3.copyWith(color: colors.headerContent),
        ),
        actions: [
          if (!isMobile)
            IconButton(
              icon: Icon(Icons.add, color: colors.headerContent),
              onPressed: () => context.push(AppRoutes.shopAdd),
            ),
        ],
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () => context.push(AppRoutes.shopAdd),
              backgroundColor: AppColors.brandAccent,
              foregroundColor: AppColors.textOnAccent,
              child: const Icon(Icons.add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: async.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.brandAccent),
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
        data: (all) {
          final q = _searchController.text.trim();
          final filtered = _filtered(
            all,
            _filter,
            q,
            _selectedRep,
            _selectedOutreach,
            _selectedArea,
            _statusFilter,
            _overdueOnly,
          );
          return RefreshIndicator(
            color: AppColors.brandPrimary,
            onRefresh: () async {
              ref.invalidate(shopsListProvider);
              await ref.read(shopsListProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Responsive.constrained(
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.space4,
                        AppSpacing.space4,
                        AppSpacing.space4,
                        AppSpacing.space2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SearchBar(
                            controller: _searchController,
                            hintText: 'Search shops',
                            hintStyle: WidgetStatePropertyAll(
                              AppTypography.bodyMd.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                            backgroundColor: WidgetStatePropertyAll(
                              colors.surfaceCard,
                            ),
                            side: WidgetStatePropertyAll(
                              BorderSide(color: colors.borderSubtle),
                            ),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadii.md,
                                ),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                            leading: Icon(
                              Icons.search,
                              color: colors.textSecondary,
                            ),
                          ),
                          SizedBox(height: AppSpacing.space3),
                          Wrap(
                            spacing: AppSpacing.space2,
                            runSpacing: AppSpacing.space2,
                            children: _filters.map((f) {
                              final selected = _filter == f;
                              return FilterChip(
                                label: Text(
                                  f,
                                  style: AppTypography.caption.copyWith(
                                    color: selected
                                        ? AppColors.textOnPrimary
                                        : colors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                selected: selected,
                                onSelected: (_) => setState(() => _filter = f),
                                selectedColor: AppColors.brandPrimary,
                                checkmarkColor: AppColors.textOnPrimary,
                                backgroundColor: colors.surfaceCard,
                                side: BorderSide(
                                  color: selected
                                      ? AppColors.brandAccent
                                      : colors.borderSubtle,
                                  width: selected ? 2 : 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.pill,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          ref.watch(repNamesProvider).when(
                            data: (reps) {
                              if (reps.length <= 1) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.space2,
                                ),
                                child: Wrap(
                                  spacing: AppSpacing.space2,
                                  runSpacing: AppSpacing.space2,
                                  children: [
                                    _repFilterChip(
                                      colors,
                                      'All reps',
                                      'All',
                                      _selectedRep == 'All',
                                    ),
                                    ...reps.map(
                                      (rep) => _repFilterChip(
                                        colors,
                                        rep,
                                        rep,
                                        _selectedRep == rep,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, _) => const SizedBox.shrink(),
                          ),
                          Builder(
                            builder: (context) {
                              final hasMultipleChannels = all
                                      .map((s) => s.outreachType)
                                      .toSet()
                                      .length >
                                  1;
                              if (!hasMultipleChannels) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.space2,
                                ),
                                child: Wrap(
                                  spacing: AppSpacing.space2,
                                  runSpacing: AppSpacing.space1,
                                  children: [
                                    _outreachFilterChip(
                                      colors,
                                      'All channels',
                                      'All',
                                      _selectedOutreach == 'All',
                                    ),
                                    ...OutreachTypes.all.map(
                                      (type) => _outreachFilterChip(
                                        colors,
                                        '${OutreachTypes.icons[type] ?? ''} $type',
                                        type,
                                        _selectedOutreach == type,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.space6),
                        child: Text(
                          'No shops match your filters.',
                          style: AppTypography.bodyLg.copyWith(
                            color: colors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.only(
                      left: AppSpacing.space4,
                      right: AppSpacing.space4,
                      top: AppSpacing.space2,
                      bottom: isMobile ? AppSpacing.space6 : AppSpacing.space2,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final shop = filtered[index];
                          return Responsive.constrained(
                            Padding(
                              padding:
                                  EdgeInsets.only(bottom: AppSpacing.space3),
                              child: _ShopCard(
                                shop: shop,
                                tierColor: _tierColor(shop.scoreTier),
                                onTap: () =>
                                    context.push('/shops/${shop.id}'),
                              ),
                            ),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.shop,
    required this.tierColor,
    required this.onTap,
  });

  final ShopModel shop;
  final Color tierColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border(
                left: BorderSide(color: tierColor, width: 4),
                top: BorderSide(color: colors.borderSubtle),
                right: BorderSide(color: colors.borderSubtle),
                bottom: BorderSide(color: colors.borderSubtle),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPrimary.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(AppSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop.shopName,
                            style: AppTypography.bodyLg.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: AppSpacing.space2),
                          Text(
                            shop.ownerName,
                            style: AppTypography.bodySm.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          if (shop.area != null && shop.area!.isNotEmpty) ...[
                            SizedBox(height: AppSpacing.space1),
                            Text(
                              shop.area!,
                              style: AppTypography.bodySm.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                        vertical: AppSpacing.space2,
                      ),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text(
                        '${shop.score}',
                        style: AppTypography.caption.copyWith(
                          color: tierColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.space3),
                Row(
                  children: [
                    if (shop.isEnrolled)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.space3,
                          vertical: AppSpacing.space1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.statusEnrolled.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(
                          'Enrolled',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.statusEnrolled,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.space3,
                          vertical: AppSpacing.space1,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceBackground,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          border: Border.all(color: colors.borderSubtle),
                        ),
                        child: Text(
                          shop.status,
                          style: AppTypography.caption.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (shop.followupDate != null) ...[
                      SizedBox(width: AppSpacing.space3),
                      if (shop.isFollowupOverdue)
                        Container(
                          width: AppSpacing.space2,
                          height: AppSpacing.space2,
                          margin: EdgeInsets.only(right: AppSpacing.space2),
                          decoration: const BoxDecoration(
                            color: AppColors.brandAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Flexible(
                        child: Text(
                          'Follow-up: ${shop.followupDate!.toLocal().toString().split(' ').first}',
                          style: AppTypography.caption.copyWith(
                            color: shop.isFollowupOverdue
                                ? AppColors.brandAccent
                                : colors.textSecondary,
                            fontWeight: shop.isFollowupOverdue
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
