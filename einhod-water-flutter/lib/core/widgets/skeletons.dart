import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'shimmer_loading.dart';

class DeliveryCardSkeleton extends StatelessWidget {
  const DeliveryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 40, height: 40, borderRadius: AppRadius.sm),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 140, height: 16),
                const SizedBox(height: AppSpacing.xs),
                const SkeletonBox(width: 80, height: 12),
              ],
            ),
          ),
          const SkeletonBox(width: 70, height: 24, borderRadius: AppRadius.full),
        ],
      ),
    );
  }
}

class HeroCardSkeleton extends StatelessWidget {
  const HeroCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.elevated,
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonBox(width: 100, height: 20, borderRadius: AppRadius.full),
                    const SizedBox(height: AppSpacing.md),
                    const SkeletonBox(width: 120, height: 14),
                    const SizedBox(height: AppSpacing.xs),
                    const SkeletonBox(width: 60, height: 48),
                  ],
                ),
              ),
              const SkeletonBox(width: 90, height: 90, borderRadius: AppRadius.full),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          const SkeletonBox(width: 150, height: 24, borderRadius: AppRadius.full),
        ],
      ),
    );
  }
}
