import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cut_above/core/data/outreach_types.dart';
import 'package:cut_above/core/design_system/app_color_scheme.dart';
import 'package:cut_above/core/design_system/app_colors.dart';
import 'package:cut_above/core/design_system/app_radii.dart';
import 'package:cut_above/core/design_system/app_spacing.dart';
import 'package:cut_above/core/design_system/app_section_header.dart';
import 'package:cut_above/core/design_system/app_typography.dart';
import 'package:cut_above/core/utils/responsive.dart';
import 'package:cut_above/core/supabase/supabase_provider.dart';
import 'package:cut_above/features/settings/presentation/settings_providers.dart';
import 'package:cut_above/features/shops/domain/score_options.dart';
import 'package:cut_above/features/shops/presentation/shops_providers.dart';

String _formatShopDate(DateTime d) =>
    DateFormat.yMMMd().format(d.toLocal());

String _auditLabel(String action) => switch (action) {
      'created' => 'Shop added to pipeline',
      'updated' => 'Shop details updated',
      'note_added' => 'Note added',
      'enrolled' => 'Enrolled as CutAbove customer',
      'status_changed' => 'Status changed',
      _ => action,
    };

class ShopDetailScreen extends ConsumerWidget {
  const ShopDetailScreen({super.key, required this.shopId});

  final String shopId;

  int _maxFor(List<ScoreOption> options) =>
      options.map((o) => o.points).reduce(math.max);

  Future<void> _launchUri(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String? _digitsOnly(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    return s.replaceAll(RegExp(r'\D'), '');
  }

  Future<void> _showEnrollSheet(BuildContext context, WidgetRef ref) async {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final tenantController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
            left: AppSpacing.space5,
            right: AppSpacing.space5,
            top: AppSpacing.space5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Mark as enrolled',
                style: AppTypography.h3.copyWith(color: colors.textPrimary),
              ),
              SizedBox(height: AppSpacing.space4),
              TextField(
                controller: tenantController,
                style: AppTypography.bodyMd.copyWith(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'CutAbove Tenant ID (optional)',
                  labelStyle: AppTypography.bodySm.copyWith(
                    color: colors.textSecondary,
                  ),
                  filled: true,
                  fillColor: colors.surfaceBackground,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: BorderSide(color: colors.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: BorderSide(
                      color: AppColors.brandAccent,
                      width: 2,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.space5),
              FilledButton(
                onPressed: () async {
                  try {
                    final profile = await ref
                        .read(profileRepositoryProvider)
                        .fetchCurrentUser();
                    final userName = profile?.fullName ??
                        supabaseClient.auth.currentUser?.email ??
                        'Unknown';
                    await ref.read(shopsRepositoryProvider).markEnrolled(
                          id: shopId,
                          tenantId: tenantController.text.trim(),
                          enrolledByName: userName,
                        );
                    ref.invalidate(shopsListProvider);
                    ref.invalidate(shopDetailProvider(shopId));
                    ref.invalidate(shopAuditProvider(shopId));
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (context.mounted) context.pop();
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(
                        ctx,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.space4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
                child: Text(
                  'Confirm',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.space5),
            ],
          ),
        );
      },
    );

    tenantController.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final shopAsync = ref.watch(shopDetailProvider(shopId));
    final answersAsync = ref.watch(shopScoreAnswersProvider(shopId));
    final notesAsync = ref.watch(shopNotesProvider(shopId));

    return shopAsync.when(
      loading: () => Scaffold(
        backgroundColor: colors.surfaceBackground,
        appBar: AppBar(
          backgroundColor: colors.headerBackground,
          foregroundColor: colors.headerContent,
          title: Text(
            'Shop',
            style: AppTypography.h3.copyWith(color: colors.headerContent),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.brandAccent),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: colors.surfaceBackground,
        appBar: AppBar(
          backgroundColor: colors.headerBackground,
          foregroundColor: colors.headerContent,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space5),
            child: Text(
              e.toString(),
              style: AppTypography.bodyMd.copyWith(color: colors.semanticError),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (shop) {
        final tier = shop.scoreTier;
        final dateFmt = DateFormat.yMMMd();

        return Scaffold(
          backgroundColor: colors.surfaceBackground,
          appBar: AppBar(
            backgroundColor: colors.headerBackground,
            foregroundColor: colors.headerContent,
            title: Text(
              shop.shopName,
              style: AppTypography.h3.copyWith(color: colors.headerContent),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.edit_outlined, color: colors.headerContent),
                onPressed: () => context.push('/shops/$shopId/edit'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space4,
            ),
            child: Responsive.constrained(
              Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (shop.photoUrl != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(AppRadii.lg),
                          bottomRight: Radius.circular(AppRadii.lg),
                        ),
                        child: Image.network(
                          shop.photoUrl!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    if (shop.photoUrl != null)
                      SizedBox(height: AppSpacing.space4),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(AppSpacing.space5),
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${shop.score}',
                                  style: AppTypography.h2.copyWith(
                                    color: AppColors.textOnPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  tier,
                                  style: AppTypography.bodyMd.copyWith(
                                    color: AppColors.brandAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (shop.isEnrolled)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.space3,
                                    vertical: AppSpacing.space2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.textOnPrimary.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.pill,
                                    ),
                                  ),
                                  child: Text(
                                    'Enrolled',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textOnPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.space3,
                                    vertical: AppSpacing.space2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.textOnPrimary.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.pill,
                                    ),
                                    border: Border.all(
                                      color: AppColors.textOnPrimary
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    shop.status,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textOnPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space4,
                        vertical: AppSpacing.space2,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${OutreachTypes.icons[shop.outreachType] ?? ''} '
                              '${shop.outreachType} · Logged by '
                              '${shop.createdByName ?? 'Unknown'}'
                              ' · ${_formatShopDate(shop.createdAt)}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (shop.lastUpdatedByName != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space4,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: AppColors.textSecondaryLight,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Updated by ${shop.lastUpdatedByName}'
                                ' · ${_formatShopDate(shop.updatedAt ?? shop.createdAt)}',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const AppSectionHeader(title: 'Shop info'),
                    _infoRow(
                      colors,
                      label: 'Outreach',
                      value:
                          '${OutreachTypes.icons[shop.outreachType] ?? ''} '
                          '${shop.outreachType}',
                    ),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    _infoRow(colors, label: 'Owner name', value: shop.ownerName),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    if (shop.phone != null && shop.phone!.isNotEmpty) ...[
                      _infoRow(
                        colors,
                        label: 'Phone',
                        value: shop.phone!,
                        onTap: () {
                          final d = _digitsOnly(shop.phone);
                          if (d != null) {
                            _launchUri(Uri(scheme: 'tel', path: d));
                          }
                        },
                      ),
                      const Divider(height: 1, color: AppColors.borderSubtle),
                    ],
                    if (shop.whatsapp != null && shop.whatsapp!.isNotEmpty) ...[
                      _infoRow(
                        colors,
                        label: 'WhatsApp',
                        value: shop.whatsapp!,
                        onTap: () {
                          final d = _digitsOnly(shop.whatsapp);
                          if (d != null) {
                            _launchUri(Uri.parse('https://wa.me/$d'));
                          }
                        },
                      ),
                      const Divider(height: 1, color: AppColors.borderSubtle),
                    ],
                    if (shop.area != null && shop.area!.isNotEmpty) ...[
                      _infoRow(colors, label: 'Area', value: shop.area!),
                      const Divider(height: 1, color: AppColors.borderSubtle),
                    ],
                    if (shop.followupDate != null) ...[
                      _infoRow(
                        colors,
                        label: 'Follow-up date',
                        value: dateFmt.format(shop.followupDate!.toLocal()),
                        valueColor: shop.isFollowupOverdue
                            ? AppColors.brandAccent
                            : colors.textPrimary,
                      ),
                      const Divider(height: 1, color: AppColors.borderSubtle),
                    ],
                    if (shop.enrolledAt != null) ...[
                      _infoRow(
                        colors,
                        label: 'Enrolled at',
                        value: dateFmt.format(shop.enrolledAt!.toLocal()),
                      ),
                      const Divider(height: 1, color: AppColors.borderSubtle),
                    ],
                    if (shop.tenantId != null && shop.tenantId!.isNotEmpty) ...[
                      _infoRow(
                        colors,
                        label: 'CutAbove Tenant ID',
                        value: shop.tenantId!,
                      ),
                      const Divider(height: 1, color: AppColors.borderSubtle),
                    ],
                    const AppSectionHeader(title: 'Readiness score'),
                  answersAsync.when(
                    data: (answers) {
                      if (answers == null) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.space4),
                          child: Text(
                            'No score recorded',
                            style: AppTypography.bodyMd.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        );
                      }
                      final rows = <Widget>[
                        _scoreDimRow(
                          colors,
                          'Workers',
                          answers.workers,
                          _maxFor(ScoreOptions.workers),
                        ),
                        _scoreDimRow(
                          colors,
                          'Cashier',
                          answers.cashier,
                          _maxFor(ScoreOptions.cashier),
                        ),
                        _scoreDimRow(
                          colors,
                          'Tracking method',
                          answers.tracking,
                          _maxFor(ScoreOptions.tracking),
                        ),
                        _scoreDimRow(
                          colors,
                          'Owner met',
                          answers.ownerMet,
                          _maxFor(ScoreOptions.ownerMet),
                        ),
                        _scoreDimRow(
                          colors,
                          'Reaction',
                          answers.reaction,
                          _maxFor(ScoreOptions.reaction),
                        ),
                        _scoreDimRow(
                          colors,
                          'Establishment',
                          answers.establishment,
                          _maxFor(ScoreOptions.establishment),
                        ),
                        _scoreDimRow(
                          colors,
                          'Customer flow',
                          answers.flow,
                          _maxFor(ScoreOptions.flow),
                        ),
                        SizedBox(height: AppSpacing.space2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: AppTypography.bodyMd.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${answers.total} /100',
                              style: AppTypography.bodyMd.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: rows,
                      );
                    },
                    loading: () => Padding(
                      padding: EdgeInsets.all(AppSpacing.space4),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.brandAccent,
                        ),
                      ),
                    ),
                    error: (e, _) => Text(
                      e.toString(),
                      style: AppTypography.bodySm.copyWith(
                        color: colors.semanticError,
                      ),
                    ),
                  ),
                  const AppSectionHeader(title: 'Notes'),
                  notesAsync.when(
                    data: (notes) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...notes.map(
                          (n) => Padding(
                            padding: EdgeInsets.only(bottom: AppSpacing.space4),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(AppSpacing.space4),
                              decoration: BoxDecoration(
                                color: AppColors.brandSurface,
                                borderRadius:
                                    BorderRadius.circular(AppRadii.md),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${n.authorName} · ${dateFmt.format(n.createdAt.toLocal())}',
                                    style: AppTypography.caption.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  SizedBox(height: AppSpacing.space1),
                                  Text(
                                    n.note,
                                    style: AppTypography.bodySm.copyWith(
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        _AddNoteRow(shopId: shopId),
                      ],
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => Text(
                      e.toString(),
                      style: AppTypography.bodySm.copyWith(
                        color: colors.semanticError,
                      ),
                    ),
                  ),
                  const AppSectionHeader(title: 'Activity log'),
                  ref.watch(shopAuditProvider(shopId)).when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (events) => events.isEmpty
                        ? Text(
                            'No activity recorded',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: events
                                .map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.space2,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.only(
                                            top: 5,
                                            right: 10,
                                          ),
                                          decoration: const BoxDecoration(
                                            color: AppColors.brandAccent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _auditLabel(
                                                  e['action'] as String,
                                                ),
                                                style: AppTypography.bodySm,
                                              ),
                                              Text(
                                                '${e['changed_by_name'] ?? 'Unknown'}'
                                                ' · ${_formatShopDate(DateTime.parse(e['created_at'] as String))}',
                                                style: AppTypography.caption
                                                    .copyWith(
                                                  color: AppColors
                                                      .textSecondaryLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  if (!shop.isEnrolled) ...[
                    const AppSectionHeader(title: 'Convert to customer'),
                    FilledButton(
                      onPressed: () => _showEnrollSheet(context, ref),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandAccent,
                        foregroundColor: AppColors.textOnAccent,
                        minimumSize: const Size(double.infinity, 48),
                        padding: EdgeInsets.symmetric(
                          vertical: AppSpacing.space4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                      ),
                      child: Text(
                        'Mark as enrolled',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.textOnAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: AppSpacing.space8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(
    AppColorScheme colors, {
    required String label,
    required String value,
    VoidCallback? onTap,
    Color? valueColor,
  }) {
    final child = Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
                           style: AppTypography.bodySm.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.bodyMd.copyWith(
                color: valueColor ?? colors.textPrimary,
                fontWeight: FontWeight.w500,
                decoration: onTap != null ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return child;
    return InkWell(onTap: onTap, child: child);
  }

  Widget _scoreDimRow(
    AppColorScheme colors,
    String label,
    int points,
    int maxPoints,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.space2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm.copyWith(color: colors.textSecondary),
            ),
          ),
          Text(
            '$points / $maxPoints',
            textAlign: TextAlign.end,
            style: AppTypography.bodySm.copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _AddNoteRow extends ConsumerStatefulWidget {
  const _AddNoteRow({required this.shopId});

  final String shopId;

  @override
  ConsumerState<_AddNoteRow> createState() => _AddNoteRowState();
}

class _AddNoteRowState extends ConsumerState<_AddNoteRow> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            minLines: 1,
            maxLines: 3,
            style: AppTypography.bodyMd.copyWith(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Add a note',
              hintStyle: AppTypography.bodySm.copyWith(
                color: colors.textSecondary,
              ),
              filled: true,
              fillColor: colors.surfaceCard,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: BorderSide(color: colors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: BorderSide(color: AppColors.brandAccent, width: 2),
              ),
            ),
          ),
        ),
        SizedBox(width: AppSpacing.space3),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  final text = _controller.text.trim();
                  if (text.isEmpty) return;
                  setState(() => _saving = true);
                  try {
                    final user = supabaseClient.auth.currentUser;
                    final author =
                        user?.email ??
                        user?.userMetadata?['full_name']?.toString() ??
                        'User';
                    await ref
                        .read(notesRepositoryProvider)
                        .add(
                          shopId: widget.shopId,
                          note: text,
                          authorName: author,
                        );
                    _controller.clear();
                    ref.invalidate(shopNotesProvider(widget.shopId));
                    ref.invalidate(shopDetailProvider(widget.shopId));
                    ref.invalidate(shopAuditProvider(widget.shopId));
                  } catch (_) {
                    // ignore; could show snackbar
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandPrimary,
            foregroundColor: AppColors.textOnPrimary,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
          ),
          child: _saving
              ? SizedBox(
                  width: AppSpacing.space5,
                  height: AppSpacing.space5,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textOnPrimary,
                  ),
                )
              : Text(
                  'Add',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
        ),
      ],
    );
  }
}
