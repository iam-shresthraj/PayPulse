import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

/// A reusable shimmer/skeleton widget that renders animated bone placeholders.
/// Mirrors the spirit of boneyard — pixel-perfect bones that match your real UI.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsets? margin;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Wraps children in a shimmer wave animation.
class SkeletonShimmer extends StatelessWidget {
  final Widget child;

  const SkeletonShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceContainer,
      highlightColor: AppColors.border.withValues(alpha: 0.5),
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

// -----------------------------------------------------------
// Stat Card Skeleton (Dashboard)
// -----------------------------------------------------------
class StatCardSkeleton extends StatelessWidget {
  const StatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SkeletonBox(width: 80, height: 12),
                SkeletonBox(width: 32, height: 32, borderRadius: 10),
              ],
            ),
            const SizedBox(height: 16),
            const SkeletonBox(width: 100, height: 24),
            const SizedBox(height: 8),
            const SkeletonBox(width: 60, height: 10),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------
// Invoice List Item Skeleton
// -----------------------------------------------------------
class InvoiceListItemSkeleton extends StatelessWidget {
  const InvoiceListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            SkeletonBox(width: 44, height: 44, borderRadius: 12),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 140, height: 14),
                  SizedBox(height: 8),
                  SkeletonBox(width: 90, height: 11),
                  SizedBox(height: 6),
                  SkeletonBox(width: 60, height: 10),
                ],
              ),
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SkeletonBox(width: 80, height: 14),
                SizedBox(height: 8),
                SkeletonBox(width: 50, height: 22, borderRadius: 6),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------
// Customer List Item Skeleton
// -----------------------------------------------------------
class CustomerListItemSkeleton extends StatelessWidget {
  const CustomerListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const SkeletonBox(width: 46, height: 46, borderRadius: 23),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 120, height: 14),
                  SizedBox(height: 7),
                  SkeletonBox(width: 85, height: 11),
                ],
              ),
            ),
            const SkeletonBox(width: 70, height: 11),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------
// Product List Item Skeleton
// -----------------------------------------------------------
class ProductListItemSkeleton extends StatelessWidget {
  const ProductListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            SkeletonBox(width: 56, height: 56, borderRadius: 12),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 130, height: 14),
                  SizedBox(height: 8),
                  SkeletonBox(width: 80, height: 11),
                  SizedBox(height: 6),
                  SkeletonBox(width: 55, height: 10),
                ],
              ),
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SkeletonBox(width: 60, height: 14),
                SizedBox(height: 8),
                SkeletonBox(width: 40, height: 26, borderRadius: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------
// Dashboard Greeting / Header Skeleton
// -----------------------------------------------------------
class DashboardHeaderSkeleton extends StatelessWidget {
  const DashboardHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            SkeletonBox(width: 54, height: 54, borderRadius: 27),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 80, height: 11),
                  SizedBox(height: 8),
                  SkeletonBox(width: 150, height: 18),
                  SizedBox(height: 6),
                  SkeletonBox(width: 100, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------
// Chart / Analytics Skeleton
// -----------------------------------------------------------
class ChartSkeleton extends StatelessWidget {
  const ChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Container(
        height: 220,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 120, height: 14),
                SkeletonBox(width: 60, height: 28, borderRadius: 8),
              ],
            ),
            const SizedBox(height: 20),
            const SkeletonBox(width: 80, height: 24),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final h in [0.5, 0.8, 0.4, 0.9, 0.6, 0.75, 0.3])
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 90 * h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------
// Detail Page Skeleton (Customer / Product detail)
// -----------------------------------------------------------
class DetailPageSkeleton extends StatelessWidget {
  const DetailPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + name header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  SkeletonBox(width: 64, height: 64, borderRadius: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 160, height: 18),
                        SizedBox(height: 8),
                        SkeletonBox(width: 110, height: 12),
                        SizedBox(height: 6),
                        SkeletonBox(width: 130, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Stat row
            Row(
              children: [
                for (int i = 0; i < 3; i++) ...[
                  Expanded(
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                    ),
                  ),
                  if (i < 2) const SizedBox(width: 12),
                ],
              ],
            ),
            const SizedBox(height: 20),
            // Section label
            const SkeletonBox(width: 100, height: 12),
            const SizedBox(height: 12),
            // List items
            for (int i = 0; i < 4; i++) ...[
              Container(
                height: 72,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------
// Reports Screen Skeleton
// -----------------------------------------------------------
class ReportsSkeleton extends StatelessWidget {
  const ReportsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 180, height: 14),
            const SizedBox(height: 20),
            for (int i = 0; i < 2; i++) ...[
              Container(
                height: 130,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const SkeletonBox(width: 52, height: 52, borderRadius: 12),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SkeletonBox(width: 120, height: 14),
                          SizedBox(height: 10),
                          SkeletonBox(width: double.infinity, height: 10),
                          SizedBox(height: 6),
                          SkeletonBox(width: 180, height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------
// Staff List Item Skeleton
// -----------------------------------------------------------
class StaffListItemSkeleton extends StatelessWidget {
  const StaffListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const SkeletonBox(width: 48, height: 48, borderRadius: 24),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 130, height: 14),
                  SizedBox(height: 8),
                  SkeletonBox(width: 90, height: 11),
                ],
              ),
            ),
            const SkeletonBox(width: 60, height: 26, borderRadius: 6),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------
// Settings / More section tile skeleton
// -----------------------------------------------------------
class SettingsTileSkeleton extends StatelessWidget {
  const SettingsTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            SkeletonBox(width: 40, height: 40, borderRadius: 10),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 110, height: 13),
                  SizedBox(height: 6),
                  SkeletonBox(width: 160, height: 10),
                ],
              ),
            ),
            SkeletonBox(width: 20, height: 20, borderRadius: 10),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------
// Generic List Skeleton — renders N items of the specified type
// -----------------------------------------------------------
enum SkeletonType {
  invoice,
  customer,
  product,
  staff,
  settings,
}

class SkeletonList extends StatelessWidget {
  final SkeletonType type;
  final int count;
  final EdgeInsets padding;

  const SkeletonList({
    super.key,
    required this.type,
    this.count = 6,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  Widget _item() {
    return switch (type) {
      SkeletonType.invoice => const InvoiceListItemSkeleton(),
      SkeletonType.customer => const CustomerListItemSkeleton(),
      SkeletonType.product => const ProductListItemSkeleton(),
      SkeletonType.staff => const StaffListItemSkeleton(),
      SkeletonType.settings => const SettingsTileSkeleton(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (_, __) => _item(),
    );
  }
}
