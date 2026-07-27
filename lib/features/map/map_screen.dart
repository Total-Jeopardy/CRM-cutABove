import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:cut_above/core/design_system/app_color_scheme.dart';
import 'package:cut_above/core/design_system/app_colors.dart';
import 'package:cut_above/core/design_system/app_radii.dart';
import 'package:cut_above/core/design_system/app_spacing.dart';
import 'package:cut_above/core/design_system/app_typography.dart';
import 'package:cut_above/features/shops/data/shop_model.dart';
import 'package:cut_above/features/shops/presentation/shops_providers.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  ShopModel? _selectedShop;

  static const _defaultCenter = LatLng(5.6037, -0.1870);
  static const _defaultZoom = 12.0;
  static const _maxMapWidth = 900.0;

  BitmapDescriptor _pinColor(String tier) => switch (tier) {
    'Hot' => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    'Warm' => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    'Nurture' => BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueOrange,
    ),
    _ => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
  };

  Set<Marker> _buildMarkers(List<ShopModel> shops) {
    return shops
        .where((s) => s.coordinatesLat != null && s.coordinatesLng != null)
        .map(
          (s) => Marker(
            markerId: MarkerId(s.id),
            position: LatLng(s.coordinatesLat!, s.coordinatesLng!),
            icon: _pinColor(s.scoreTier),
            onTap: () => setState(() => _selectedShop = s),
          ),
        )
        .toSet();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final shopsAsync = ref.watch(shopsListProvider);

    return Scaffold(
      backgroundColor: colors.surfaceBackground,
      appBar: AppBar(
        backgroundColor: colors.headerBackground,
        foregroundColor: colors.headerContent,
        title: Text(
          'Map',
          style: AppTypography.h3.copyWith(color: colors.headerContent),
        ),
        actions: [
          if (_selectedShop != null)
            IconButton(
              icon: Icon(Icons.close, color: colors.headerContent),
              onPressed: () => setState(() => _selectedShop = null),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final mapWidth = constraints.maxWidth > _maxMapWidth
              ? _maxMapWidth
              : constraints.maxWidth;
          return shopsAsync.when(
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
                      'Error: $e',
                      style: AppTypography.bodyMd.copyWith(
                        color: colors.semanticError,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.space4),
                    FilledButton(
                      onPressed: () => ref.invalidate(shopsListProvider),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: AppColors.textOnPrimary,
                      ),
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
            data: (shops) => Center(
              child: SizedBox(
                width: mapWidth,
                height: constraints.maxHeight,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: _defaultCenter,
                        zoom: _defaultZoom,
                      ),
                      markers: _buildMarkers(shops),
                      onMapCreated: (c) => _mapController = c,
                      onTap: (_) => setState(() => _selectedShop = null),
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: true,
                    ),
                    Positioned(
                      top: AppSpacing.space2,
                      right: AppSpacing.space4,
                      child: _Legend(colors: colors),
                    ),
                    if (_selectedShop != null)
                      Positioned(
                        left: AppSpacing.space4,
                        right: AppSpacing.space4,
                        bottom: 0,
                        child: SafeArea(
                          top: false,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: AppSpacing.space5),
                            child: _ShopPinCard(
                              shop: _selectedShop!,
                              colors: colors,
                              onTap: () =>
                                  context.push('/shops/${_selectedShop!.id}'),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.colors});

  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: colors.surfaceCard.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendRow(AppColors.scoreHot, 'Hot'),
          _legendRow(AppColors.scoreWarm, 'Warm'),
          _legendRow(AppColors.scoreNurture, 'Nurture'),
          _legendRow(AppColors.scoreCold, 'Cold'),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label) => Padding(
    padding: EdgeInsets.symmetric(vertical: AppSpacing.space1),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppSpacing.space3,
          height: AppSpacing.space3,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: AppSpacing.space2),
        Text(
          label,
          style: AppTypography.bodySm.copyWith(color: colors.textPrimary),
        ),
      ],
    ),
  );
}

class _ShopPinCard extends StatelessWidget {
  const _ShopPinCard({
    required this.shop,
    required this.colors,
    required this.onTap,
  });

  final ShopModel shop;
  final AppColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    shop.shopName,
                    style: AppTypography.bodyLg.copyWith(
                      color: AppColors.brandPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.space1),
                  Text(
                    shop.ownerName,
                    style: AppTypography.bodySm.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  if (shop.area != null && shop.area!.isNotEmpty)
                    Text(
                      shop.area!,
                      style: AppTypography.bodySm.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.space3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                _scorePill(shop.scoreTier),
                SizedBox(height: AppSpacing.space2),
                Text(
                  'View detail →',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.brandPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _scorePill(String tier) {
    final color = switch (tier) {
      'Hot' => AppColors.scoreHot,
      'Warm' => AppColors.scoreWarm,
      'Nurture' => AppColors.scoreNurture,
      _ => AppColors.scoreCold,
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        tier,
        style: AppTypography.bodySm.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
