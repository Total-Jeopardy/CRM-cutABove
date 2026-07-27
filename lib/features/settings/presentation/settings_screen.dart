import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cut_above/core/design_system/app_color_scheme.dart';
import 'package:cut_above/core/design_system/app_colors.dart';
import 'package:cut_above/core/design_system/app_radii.dart';
import 'package:cut_above/core/design_system/app_spacing.dart';
import 'package:cut_above/core/design_system/app_section_header.dart';
import 'package:cut_above/core/design_system/app_typography.dart';
import 'package:cut_above/core/utils/responsive.dart';
import 'package:cut_above/features/auth/domain/auth_state.dart';
import 'package:cut_above/features/auth/presentation/auth_providers.dart';
import 'package:cut_above/features/shops/data/profile_model.dart';
import 'package:cut_above/features/settings/presentation/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _editingName = false;
  final _nameController = TextEditingController();
  bool _savingName = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget _avatar(String nameOrEmail, {double size = 52}) {
    final initials = nameOrEmail
        .trim()
        .split(RegExp(r'[\s@.]'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.brandPrimary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: AppTypography.bodyMd.copyWith(
          color: AppColors.textOnPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _openSupabaseInvite() async {
    final raw = dotenv.env['SUPABASE_URL'] ?? '';
    if (raw.isEmpty) return;
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty) return;
    final projectRef = uri.host.split('.').first;
    final target = Uri.parse(
      'https://supabase.com/dashboard/project/$projectRef/auth/users',
    );
    if (await canLaunchUrl(target)) {
      await launchUrl(target, mode: LaunchMode.externalApplication);
    }
  }

  InputDecoration _inputDecoration(AppColorScheme colors, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTypography.bodySm.copyWith(color: colors.textSecondary),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final auth = ref.watch(authNotifierProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final teamAsync = ref.watch(teamProvider);

    final email = switch (auth) {
      AuthAuthenticated(:final user) => user.email ?? '',
      _ => '',
    };

    final profileSnapshot = switch (profileAsync) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final displayName =
        profileSnapshot?.fullName ??
        (email.isNotEmpty ? email.split('@').first : 'User');

    return Scaffold(
      backgroundColor: colors.surfaceBackground,
      appBar: AppBar(
        backgroundColor: colors.headerBackground,
        foregroundColor: colors.headerContent,
        title: Text(
          'Settings',
          style: AppTypography.h3.copyWith(color: colors.headerContent),
        ),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppSpacing.space4),
        child: Responsive.constrained(
          Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppSectionHeader(title: 'Your account'),
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.brandPrimary, width: 4),
                  ),
                ),
                padding: EdgeInsets.only(
                  left: AppSpacing.space4,
                  top: AppSpacing.space2,
                  bottom: AppSpacing.space2,
                ),
                child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _avatar(displayName.isNotEmpty ? displayName : email),
                  SizedBox(width: AppSpacing.space4),
                  Expanded(
                    child: profileAsync.when(
                      loading: () => Text(
                        'Loading…',
                        style: AppTypography.bodyMd.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      error: (e, _) => Text(
                        '$e',
                        style: AppTypography.bodySm.copyWith(
                          color: colors.semanticError,
                        ),
                      ),
                      data: (profile) {
                        if (_editingName) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _nameController,
                                style: AppTypography.bodyMd.copyWith(
                                  color: colors.textPrimary,
                                ),
                                decoration: _inputDecoration(
                                  colors,
                                  'Full name',
                                ),
                              ),
                              SizedBox(height: AppSpacing.space3),
                              Wrap(
                                spacing: AppSpacing.space3,
                                runSpacing: AppSpacing.space2,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  FilledButton(
                                    onPressed: _savingName
                                        ? null
                                        : () async {
                                            setState(() => _savingName = true);
                                            try {
                                              await ref
                                                  .read(
                                                    profileRepositoryProvider,
                                                  )
                                                  .upsertProfile(
                                                    fullName: _nameController
                                                        .text
                                                        .trim(),
                                                    role: profile?.role ??
                                                        'field',
                                                  );
                                              if (!mounted) return;
                                              setState(() {
                                                _editingName = false;
                                              });
                                              ref.invalidate(
                                                currentProfileProvider,
                                              );
                                              ref.invalidate(teamProvider);
                                            } finally {
                                              if (mounted) {
                                                setState(
                                                  () => _savingName = false,
                                                );
                                              }
                                            }
                                          },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.brandPrimary,
                                      foregroundColor: AppColors.textOnPrimary,
                                    ),
                                    child: Text(
                                      'Save',
                                      style: AppTypography.bodyMd.copyWith(
                                        color: AppColors.textOnPrimary,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _savingName
                                        ? null
                                        : () => setState(() {
                                              _editingName = false;
                                              _nameController.text =
                                                  profile?.fullName ??
                                                      (email.isNotEmpty
                                                          ? email
                                                              .split('@')
                                                              .first
                                                          : '');
                                            }),
                                    child: Text(
                                      'Cancel',
                                      style: AppTypography.bodyMd.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.fullName ??
                                  (email.isNotEmpty
                                      ? email.split('@').first
                                      : 'User'),
                              style: AppTypography.bodyLg.copyWith(
                                color: AppColors.brandPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (email.isNotEmpty) ...[
                              SizedBox(height: AppSpacing.space2),
                              Text(
                                email,
                                style: AppTypography.bodySm.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                            SizedBox(height: AppSpacing.space2),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.space3,
                                vertical: AppSpacing.space1,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surfaceBackground,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.pill,
                                ),
                                border: Border.all(color: colors.borderSubtle),
                              ),
                              child: Text(
                                profile?.role ?? 'field',
                                style: AppTypography.caption.copyWith(
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(height: AppSpacing.space3),
                            OutlinedButton(
                              onPressed: () {
                                _nameController.text = profile?.fullName ??
                                    (email.isNotEmpty
                                        ? email.split('@').first
                                        : '');
                                setState(() => _editingName = true);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.brandPrimary,
                                side: BorderSide(color: AppColors.brandPrimary),
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.space4,
                                  vertical: AppSpacing.space3,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.md,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Edit name',
                                style: AppTypography.bodyMd.copyWith(
                                  color: AppColors.brandPrimary,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(child: AppSectionHeader(title: 'Team')),
                  teamAsync.maybeWhen(
                    data: (t) => t.isEmpty
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: EdgeInsets.only(
                              top: AppSpacing.space5,
                              bottom: AppSpacing.space2,
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.space3,
                                vertical: AppSpacing.space1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.brandPrimary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadii.pill,
                                ),
                              ),
                              child: Text(
                                '${t.length}',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.brandPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              teamAsync.when(
                loading: () => Column(
                  children: List.generate(
                    3,
                    (_) => Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.space3),
                      child: Row(
                        children: [
                          Container(
                            width: AppSpacing.space7,
                            height: AppSpacing.space7,
                            decoration: BoxDecoration(
                              color: colors.surfaceCard,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: AppSpacing.space4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: AppSpacing.space3,
                                  width: AppSpacing.space8 * 2,
                                  decoration: BoxDecoration(
                                    color: colors.surfaceCard,
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.sm,
                                    ),
                                  ),
                                ),
                                SizedBox(height: AppSpacing.space2),
                                Container(
                                  height: AppSpacing.space2,
                                  width: AppSpacing.space8 + AppSpacing.space2,
                                  decoration: BoxDecoration(
                                    color: colors.surfaceCard,
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.sm,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                error: (e, _) => Text(
                  '$e',
                  style: AppTypography.bodySm.copyWith(
                    color: colors.semanticError,
                  ),
                ),
                data: (team) {
                  if (team.isEmpty) {
                    return Text(
                      'No team members yet',
                      style: AppTypography.bodyMd.copyWith(
                        color: colors.textSecondary,
                      ),
                    );
                  }
                  final dateFmt = DateFormat.yMMMd();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: team
                        .map((m) => _teamRow(m, colors, dateFmt))
                        .toList(),
                  );
                },
              ),
              const AppSectionHeader(title: 'Invite team member'),
              Text(
                'To invite team members, go to your Supabase dashboard → Authentication → Users → Invite user.',
                style: AppTypography.bodySm.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: AppSpacing.space4),
              FilledButton(
                onPressed: _openSupabaseInvite,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.space4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
                child: Text(
                  'Open Supabase dashboard',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
              const AppSectionHeader(title: 'Account'),
              OutlinedButton(
                onPressed: () =>
                    ref.read(authNotifierProvider.notifier).logout(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.semanticError,
                  side: BorderSide(color: colors.semanticError),
                  minimumSize: const Size(double.infinity, 48),
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.space4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
                child: Text(
                  'Sign out',
                  style: AppTypography.bodyMd.copyWith(
                    color: colors.semanticError,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.space8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamRow(ProfileModel m, AppColorScheme colors, DateFormat dateFmt) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _avatar(m.fullName, size: 44),
          SizedBox(width: AppSpacing.space3),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMd.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.space1),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.space2,
                    vertical: AppSpacing.space1,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceBackground,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Text(
                    m.role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            m.createdAt != null ? dateFmt.format(m.createdAt!.toLocal()) : '—',
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
