import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:cut_above/core/data/areas_provider.dart';
import 'package:cut_above/core/data/outreach_types.dart';
import 'package:cut_above/core/data/greater_accra_areas.dart';
import 'package:cut_above/core/services/geocoding_service.dart';
import 'package:cut_above/core/design_system/app_color_scheme.dart';
import 'package:cut_above/core/design_system/app_colors.dart';
import 'package:cut_above/core/design_system/app_radii.dart';
import 'package:cut_above/core/design_system/app_section_header.dart';
import 'package:cut_above/core/design_system/app_spacing.dart';
import 'package:cut_above/core/design_system/app_typography.dart';
import 'package:cut_above/core/utils/responsive.dart';
import 'package:cut_above/core/supabase/supabase_provider.dart';
import 'package:cut_above/features/shops/data/photo_upload_service.dart';
import 'package:cut_above/features/shops/data/score_answers_model.dart';
import 'package:cut_above/features/shops/data/shop_model.dart';
import 'package:cut_above/features/shops/domain/score_calculator.dart';
import 'package:cut_above/features/shops/domain/score_options.dart';
import 'package:cut_above/features/settings/presentation/settings_providers.dart';
import 'package:cut_above/features/shops/presentation/shops_providers.dart';

class ShopFormScreen extends ConsumerWidget {
  const ShopFormScreen({super.key, this.shopId});

  final String? shopId;

  static const _statuses = [
    'Visited',
    'Interested',
    'Demo Booked',
    'Committed',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = shopId == null ? 'Add shop' : 'Edit shop';

    if (shopId != null) {
      final async = ref.watch(shopFormBundleProvider(shopId!));
      return async.when(
        loading: () => _FormScaffold(
          title: title,
          child: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => _FormScaffold(
          title: title,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space5),
              child: Text(
                e.toString(),
                style: AppTypography.bodyMd.copyWith(
                  color: Theme.of(context)
                      .extension<AppColorScheme>()!
                      .semanticError,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        data: (bundle) => _ShopFormEditor(title: title, bundle: bundle),
      );
    }

    return _ShopFormEditor(title: title, bundle: null);
  }
}

class _FormScaffold extends StatelessWidget {
  const _FormScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    return Scaffold(
      backgroundColor: colors.surfaceBackground,
      appBar: AppBar(
        backgroundColor: colors.headerBackground,
        foregroundColor: colors.headerContent,
        title: Text(
          title,
          style: AppTypography.h3.copyWith(color: colors.headerContent),
        ),
      ),
      body: child,
    );
  }
}

class _ShopFormEditor extends ConsumerStatefulWidget {
  const _ShopFormEditor({required this.title, required this.bundle});

  final String title;
  final ShopFormBundle? bundle;

  @override
  ConsumerState<_ShopFormEditor> createState() => _ShopFormEditorState();
}

class _ShopFormEditorState extends ConsumerState<_ShopFormEditor> {
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _coordsController = TextEditingController();
  final _areaController = TextEditingController();
  final _areaFocusNode = FocusNode();

  late ScoreOption _workers;
  late ScoreOption _cashier;
  late ScoreOption _tracking;
  late ScoreOption _ownerMet;
  late ScoreOption _reaction;
  late ScoreOption _establishment;
  late ScoreOption _flow;

  String? _area;
  late String _status;
  String _outreachType = 'In Person';
  DateTime? _followupDate;
  double? _lat;
  double? _lng;

  String? _photoUrl;
  XFile? _pendingPhoto;
  Uint8List? _photoPreviewBytes;

  bool _saving = false;
  String? _error;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final b = widget.bundle;
    if (b != null) {
      final s = b.shop;
      final a = b.answers;
      _shopNameController.text = s.shopName;
      _ownerNameController.text = s.ownerName;
      _phoneController.text = s.phone ?? '';
      _whatsappController.text = s.whatsapp ?? '';
      _area = s.area;
      _areaController.text = s.area ?? '';
      _status = s.status;
      _outreachType = s.outreachType;
      _followupDate = s.followupDate;
      _lat = s.coordinatesLat;
      _lng = s.coordinatesLng;
      _photoUrl = s.photoUrl;

      _workers = _matchOption(ScoreOptions.workers, a?.workers ?? 0);
      _cashier = _matchOption(ScoreOptions.cashier, a?.cashier ?? 0);
      _tracking = _matchOption(ScoreOptions.tracking, a?.tracking ?? 0);
      _ownerMet = _matchOption(ScoreOptions.ownerMet, a?.ownerMet ?? 0);
      _reaction = _matchOption(ScoreOptions.reaction, a?.reaction ?? 0);
      _establishment = _matchOption(
        ScoreOptions.establishment,
        a?.establishment ?? 0,
      );
      _flow = _matchOption(ScoreOptions.flow, a?.flow ?? 0);
    } else {
      _status = ShopFormScreen._statuses.first;
      _workers = ScoreOptions.workers.first;
      _cashier = ScoreOptions.cashier.first;
      _tracking = ScoreOptions.tracking.first;
      _ownerMet = ScoreOptions.ownerMet.first;
      _reaction = ScoreOptions.reaction.first;
      _establishment = ScoreOptions.establishment.first;
      _flow = ScoreOptions.flow.first;
    }
    _syncCoordsText();
  }

  void _syncCoordsText() {
    _coordsController.text = _lat != null && _lng != null
        ? '${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}'
        : '';
  }

  ScoreOption _matchOption(List<ScoreOption> options, int points) {
    for (final o in options) {
      if (o.points == points) return o;
    }
    return options.first;
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _coordsController.dispose();
    _areaController.dispose();
    _areaFocusNode.dispose();
    super.dispose();
  }

  int get _liveScore => ScoreCalculator.calculate(
        workers: _workers.points,
        cashier: _cashier.points,
        tracking: _tracking.points,
        ownerMet: _ownerMet.points,
        reaction: _reaction.points,
        establishment: _establishment.points,
        flow: _flow.points,
      );

  String get _liveTier => ScoreCalculator.tier(_liveScore);

  Future<void> _pickDate() async {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final picked = await showDatePicker(
      context: context,
      initialDate: _followupDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.brandPrimary,
              onPrimary: AppColors.textOnPrimary,
              surface: colors.surfaceCard,
              onSurface: colors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _followupDate = picked);
  }

  Future<void> _useGps() async {
    setState(() => _error = null);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _error = 'Location permission denied.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      _syncCoordsText();

      final areaName = await GeocodingService.getAreaFromCoordinates(
        lat: pos.latitude,
        lng: pos.longitude,
      );
      if (!mounted) return;
      if (areaName != null) {
        final allAreas = ref.read(allAreasProvider).whenOrNull(data: (v) => v) ??
            GreaterAccraAreas.all;
        var match = '';
        for (final a in allAreas) {
          if (a.toLowerCase() == areaName.toLowerCase()) {
            match = a;
            break;
          }
        }
        if (match.isNotEmpty) {
          setState(() {
            _area = match;
            _areaController.text = match;
          });
        } else {
          await ref.read(customAreasRepositoryProvider).add(areaName);
          ref.invalidate(allAreasProvider);
          if (mounted) {
            setState(() {
              _area = areaName;
              _areaController.text = areaName;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"$areaName" added to your areas list'),
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _error = 'Could not get location: $e');
    }
  }

  InputDecoration _fieldDecoration(AppColorScheme colors, String label) {
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
        borderSide: const BorderSide(color: AppColors.brandPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: colors.semanticError),
      ),
    );
  }

  Future<void> _showPhotoOptions() async {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(
                'Camera',
                style: AppTypography.bodyMd.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              onTap: () => _onPhotoSource(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(
                'Gallery',
                style: AppTypography.bodyMd.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              onTap: () => _onPhotoSource(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onPhotoSource(ImageSource source) async {
    Navigator.of(context).pop();
    final isEdit = widget.bundle != null;
    if (isEdit) {
      final id = widget.bundle!.shop.id;
      final svc = PhotoUploadService();
      final url = source == ImageSource.camera
          ? await svc.captureAndUpload(shopId: id)
          : await svc.pickAndUpload(shopId: id);
      if (!mounted) return;
      if (url == null) {
        if (kIsWeb) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo upload failed or is limited on web.'),
            ),
          );
        }
        return;
      }
      setState(() {
        _photoUrl = url;
        _pendingPhoto = null;
        _photoPreviewBytes = null;
      });
      return;
    }

    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (x == null || !mounted) return;
    final bytes = await x.readAsBytes();
    setState(() {
      _pendingPhoto = x;
      _photoPreviewBytes = bytes;
      _photoUrl = null;
    });
  }

  Future<void> _save() async {
    final name = _shopNameController.text.trim();
    final owner = _ownerNameController.text.trim();
    if (name.isEmpty || owner.isEmpty) {
      setState(() => _error = 'Shop name and owner name are required.');
      return;
    }

    final user = supabaseClient.auth.currentUser;
    if (user == null) {
      setState(() => _error = 'Not signed in.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(shopsRepositoryProvider);
      final profile = await ref.read(profileRepositoryProvider).fetchCurrentUser();
      final userName = profile?.fullName ??
          supabaseClient.auth.currentUser?.email ??
          'Unknown';

      _area = _trimOrNull(_areaController.text);
      final allAreas = ref.read(allAreasProvider).whenOrNull(data: (v) => v) ??
          GreaterAccraAreas.all;
      if (_area != null &&
          !allAreas.any((a) => a.toLowerCase() == _area!.toLowerCase())) {
        await ref.read(customAreasRepositoryProvider).add(_area!);
        ref.invalidate(allAreasProvider);
      }

      final score = _liveScore;
      final phone = _trimOrNull(_phoneController.text);
      final whatsapp = _trimOrNull(_whatsappController.text);

      if (widget.bundle == null) {
        final shop = ShopModel(
          id: '',
          createdAt: DateTime.now(),
          createdBy: user.id,
          shopName: name,
          ownerName: owner,
          phone: phone,
          whatsapp: whatsapp,
          area: _area,
          coordinatesLat: _lat,
          coordinatesLng: _lng,
          status: _status,
          score: score,
          outreachType: _outreachType,
          followupDate: _followupDate,
          enrolledAt: null,
          tenantId: null,
          notesCount: 0,
          photoUrl: null,
          createdByName: null,
          lastUpdatedByName: null,
          lastUpdatedBy: null,
          updatedAt: null,
        );
        final answers = ScoreAnswersModel(
          shopId: '',
          workers: _workers.points,
          cashier: _cashier.points,
          tracking: _tracking.points,
          ownerMet: _ownerMet.points,
          reaction: _reaction.points,
          establishment: _establishment.points,
          flow: _flow.points,
        );
        final created = await repo.create(
          shop: shop,
          answers: answers,
          createdByName: userName,
        );
        if (_pendingPhoto != null) {
          final upload = PhotoUploadService();
          final url =
              await upload.uploadXFile(_pendingPhoto!, created.id);
          if (url != null) {
            await repo.update(
              id: created.id,
              shop: created.copyWith(photoUrl: url),
              answers: answers.copyWith(shopId: created.id),
              updatedByName: userName,
            );
          }
        }
      } else {
        final base = widget.bundle!.shop;
        var updated = base.copyWith(
          shopName: name,
          ownerName: owner,
          phone: phone,
          whatsapp: whatsapp,
          area: _area,
          coordinatesLat: _lat,
          coordinatesLng: _lng,
          status: _status,
          score: score,
          outreachType: _outreachType,
          followupDate: _followupDate,
          photoUrl: _photoUrl ?? base.photoUrl,
        );
        final answers = ScoreAnswersModel(
          id: widget.bundle!.answers?.id,
          shopId: base.id,
          workers: _workers.points,
          cashier: _cashier.points,
          tracking: _tracking.points,
          ownerMet: _ownerMet.points,
          reaction: _reaction.points,
          establishment: _establishment.points,
          flow: _flow.points,
        );
        await repo.update(
          id: base.id,
          shop: updated,
          answers: answers,
          updatedByName: userName,
        );
        ref.invalidate(shopAuditProvider(base.id));
      }

      ref.invalidate(shopsListProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _trimOrNull(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final tier = _liveTier;
    ref.watch(allAreasProvider);

    return Scaffold(
      backgroundColor: colors.surfaceBackground,
      appBar: AppBar(
        backgroundColor: colors.headerBackground,
        foregroundColor: colors.headerContent,
        title: Text(
          widget.title,
          style: AppTypography.h3.copyWith(color: colors.headerContent),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space5,
        ),
        child: Responsive.constrained(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppSectionHeader(title: 'Shop info'),
              SizedBox(height: AppSpacing.space4),
              TextField(
                controller: _shopNameController,
                style: AppTypography.bodyMd.copyWith(color: colors.textPrimary),
                decoration: _fieldDecoration(colors, 'Shop name *'),
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: AppSpacing.space4),
              TextField(
                controller: _ownerNameController,
                style: AppTypography.bodyMd.copyWith(color: colors.textPrimary),
                decoration: _fieldDecoration(colors, 'Owner name *'),
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: AppSpacing.space4),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: AppTypography.bodyMd.copyWith(color: colors.textPrimary),
                decoration: _fieldDecoration(colors, 'Phone'),
              ),
              SizedBox(height: AppSpacing.space4),
              TextField(
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                style: AppTypography.bodyMd.copyWith(color: colors.textPrimary),
                decoration: _fieldDecoration(colors, 'WhatsApp'),
              ),
              SizedBox(height: AppSpacing.space4),
              RawAutocomplete<String>(
                textEditingController: _areaController,
                focusNode: _areaFocusNode,
                displayStringForOption: (o) => o,
                optionsBuilder: (TextEditingValue value) {
                  final areas =
                      ref.read(allAreasProvider).whenOrNull(data: (v) => v) ??
                          GreaterAccraAreas.all;
                  if (value.text.isEmpty) return areas;
                  return areas.where(
                    (a) => a.toLowerCase().contains(value.text.toLowerCase()),
                  );
                },
                onSelected: (s) => setState(() => _area = s),
                fieldViewBuilder:
                    (context, textEditingController, focusNode, onSubmit) {
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    style: AppTypography.bodyMd.copyWith(
                      color: colors.textPrimary,
                    ),
                    decoration: _fieldDecoration(
                      colors,
                      'Area / Community',
                    ).copyWith(
                      hintText: 'Type to search...',
                      suffixIcon: const Icon(Icons.search, size: 20),
                    ),
                    onChanged: (v) =>
                        setState(() => _area = _trimOrNull(v)),
                    onFieldSubmitted: (_) => onSubmit(),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  final list = options.toList();
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      color: Theme.of(context).colorScheme.surface,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 240),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final option = list[i];
                            return ListTile(
                              dense: true,
                              title: Text(
                                option,
                                style: AppTypography.bodySm.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: AppSpacing.space4),
              _decoratedDropdown<String>(
                colors,
                label: 'Status',
                value: _status,
                items: ShopFormScreen._statuses,
                itemLabel: (s) => s,
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
              ),
              SizedBox(height: AppSpacing.space4),
              const AppSectionHeader(title: 'How did you reach them?'),
              SizedBox(height: AppSpacing.space3),
              Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space2,
                children: OutreachTypes.all.map((type) {
                  final selected = _outreachType == type;
                  return ChoiceChip(
                    label: Text(
                      '${OutreachTypes.icons[type] ?? ''} $type',
                      style: AppTypography.bodySm.copyWith(
                        color: selected
                            ? Colors.white
                            : colors.textPrimary,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    selected: selected,
                    selectedColor: AppColors.brandPrimary,
                    backgroundColor: colors.surfaceCard,
                    side: BorderSide(
                      color: selected
                          ? AppColors.brandPrimary
                          : colors.borderSubtle,
                    ),
                    onSelected: (_) =>
                        setState(() => _outreachType = type),
                  );
                }).toList(),
              ),
              SizedBox(height: AppSpacing.space4),
              OutlinedButton(
                onPressed: _pickDate,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textPrimary,
                  side: BorderSide(color: colors.borderSubtle),
                  minimumSize: const Size(double.infinity, 48),
                  padding: EdgeInsets.all(AppSpacing.space4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _followupDate == null
                        ? 'Follow-up date'
                        : _followupDate!.toLocal().toString().split(' ').first,
                    style: AppTypography.bodyMd.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
              const AppSectionHeader(title: 'Shop photo'),
              GestureDetector(
                onTap: _showPhotoOptions,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.brandSurface,
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: _photoPreviewBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          child: Image.memory(
                            _photoPreviewBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 160,
                          ),
                        )
                      : _photoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadii.lg),
                              child: Image.network(
                                _photoUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 160,
                                errorBuilder: (_, _, _) => _photoPlaceholder(),
                              ),
                            )
                          : _photoPlaceholder(),
                ),
              ),
              SizedBox(height: AppSpacing.space2),
              Text(
                'Optional — helps identify the shop later',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const AppSectionHeader(title: 'Location'),
              SizedBox(height: AppSpacing.space4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: TextField(
                      controller: _coordsController,
                      readOnly: true,
                      style: AppTypography.bodyMd.copyWith(
                        color: colors.textPrimary,
                      ),
                      decoration: _fieldDecoration(colors, 'Coordinates'),
                    ),
                  ),
                  SizedBox(width: AppSpacing.space3),
                  OutlinedButton.icon(
                    onPressed: _useGps,
                    icon: Icon(
                      Icons.my_location,
                      color: AppColors.brandPrimary,
                    ),
                    label: Text(
                      'Use GPS',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.brandPrimary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.brandPrimary),
                      padding: EdgeInsets.all(AppSpacing.space4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.space2),
              Text(
                'Tap Use GPS while at the shop',
                style: AppTypography.bodySm.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const AppSectionHeader(title: 'Readiness scoring'),
              SizedBox(height: AppSpacing.space4),
              Container(
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
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        '$_liveScore',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h1.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.space4),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                        vertical: AppSpacing.space2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandAccent,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Text(
                        tier,
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.textOnAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.space4),
              _scoreDropdown(
                colors,
                label: 'Workers',
                value: _workers,
                options: ScoreOptions.workers,
                onChanged: (v) => setState(() => _workers = v!),
              ),
              SizedBox(height: AppSpacing.space4),
              _scoreDropdown(
                colors,
                label: 'Cashier',
                value: _cashier,
                options: ScoreOptions.cashier,
                onChanged: (v) => setState(() => _cashier = v!),
              ),
              SizedBox(height: AppSpacing.space4),
              _scoreDropdown(
                colors,
                label: 'Tracking method',
                value: _tracking,
                options: ScoreOptions.tracking,
                onChanged: (v) => setState(() => _tracking = v!),
              ),
              SizedBox(height: AppSpacing.space4),
              _scoreDropdown(
                colors,
                label: 'Owner met',
                value: _ownerMet,
                options: ScoreOptions.ownerMet,
                onChanged: (v) => setState(() => _ownerMet = v!),
              ),
              SizedBox(height: AppSpacing.space4),
              _scoreDropdown(
                colors,
                label: 'Reaction',
                value: _reaction,
                options: ScoreOptions.reaction,
                onChanged: (v) => setState(() => _reaction = v!),
              ),
              SizedBox(height: AppSpacing.space4),
              _scoreDropdown(
                colors,
                label: 'Establishment',
                value: _establishment,
                options: ScoreOptions.establishment,
                onChanged: (v) => setState(() => _establishment = v!),
              ),
              SizedBox(height: AppSpacing.space4),
              _scoreDropdown(
                colors,
                label: 'Customer flow',
                value: _flow,
                options: ScoreOptions.flow,
                onChanged: (v) => setState(() => _flow = v!),
              ),
              if (_error != null) ...[
                SizedBox(height: AppSpacing.space5),
                Text(
                  _error!,
                  style: AppTypography.bodyMd.copyWith(
                    color: colors.semanticError,
                  ),
                ),
              ],
              SizedBox(height: AppSpacing.space6),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: AppColors.textOnPrimary,
                  disabledBackgroundColor: colors.borderSubtle,
                  minimumSize: const Size(double.infinity, 52),
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.space4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        height: AppSpacing.space6,
                        width: AppSpacing.space6,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                    : Text(
                        'Save',
                        style: AppTypography.bodyLg.copyWith(
                          color: AppColors.textOnPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              SizedBox(height: AppSpacing.space6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.add_a_photo_outlined,
          size: 36,
          color: AppColors.brandPrimary,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to add shop photo',
          style: AppTypography.bodySm.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Optional',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _scoreDropdown(
    AppColorScheme colors, {
    required String label,
    required ScoreOption value,
    required List<ScoreOption> options,
    required ValueChanged<ScoreOption?> onChanged,
  }) {
    return InputDecorator(
      decoration: _fieldDecoration(colors, label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ScoreOption>(
          value: value,
          isExpanded: true,
          style: AppTypography.bodySm.copyWith(color: colors.textPrimary),
          items: options
              .map(
                (o) => DropdownMenuItem(
                  value: o,
                  child: Text(
                    o.label,
                    style: AppTypography.bodySm.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _decoratedDropdown<T>(
    AppColorScheme colors, {
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
    Widget? hint,
  }) {
    return InputDecorator(
      decoration: _fieldDecoration(colors, label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: hint,
          isExpanded: true,
          style: AppTypography.bodyMd.copyWith(color: colors.textPrimary),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabel(item),
                    style: AppTypography.bodyMd.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
