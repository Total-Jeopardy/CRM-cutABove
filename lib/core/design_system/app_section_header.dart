import 'package:flutter/material.dart';

import 'package:cut_above/core/design_system/app_colors.dart';
import 'package:cut_above/core/design_system/app_spacing.dart';
import 'package:cut_above/core/design_system/app_typography.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.space5,
        bottom: AppSpacing.space2,
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            margin: const EdgeInsets.only(right: 8),
            color: AppColors.brandAccent,
          ),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: AppTypography.caption.copyWith(
                color: AppColors.brandPrimary,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
