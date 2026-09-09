import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';

/// Shimmering placeholder block. Skeletons below mirror the real layout
/// exactly so nothing shifts when data lands.
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Shimmer.fromColors(
      baseColor: c.isDark ? c.surfaceMuted : c.backgroundSunken,
      highlightColor: c.isDark ? c.surfaceElevated : Colors.white,
      period: const Duration(milliseconds: 1300),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space10),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppDimensions.brLarge,
        border: Border.all(color: c.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingSkeleton(
            height: AppDimensions.productImageHeight,
            radius: AppDimensions.radiusSmall,
          ),
          SizedBox(height: AppDimensions.space10),
          LoadingSkeleton(height: 14, width: 110),
          SizedBox(height: AppDimensions.space8),
          LoadingSkeleton(height: 11, width: 70),
          Spacer(),
          Row(
            children: [
              Expanded(child: LoadingSkeleton(height: 18, width: 80)),
              LoadingSkeleton(height: 34, width: 34, radius: 12),
            ],
          ),
        ],
      ),
    );
  }
}

class CompanyCardSkeleton extends StatelessWidget {
  const CompanyCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppDimensions.brLarge,
        border: Border.all(color: c.border),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              LoadingSkeleton(height: 46, width: 46, radius: 15),
              SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(height: 15, width: 130),
                    SizedBox(height: AppDimensions.space8),
                    LoadingSkeleton(height: 11, width: 90),
                  ],
                ),
              ),
              LoadingSkeleton(height: 20, width: 58, radius: 999),
            ],
          ),
          SizedBox(height: AppDimensions.space12),
          LoadingSkeleton(height: 52, radius: AppDimensions.radiusSmall),
          SizedBox(height: AppDimensions.space12),
          Row(
            children: [
              Expanded(child: LoadingSkeleton(height: 20, width: 120)),
              LoadingSkeleton(height: 42, width: 96, radius: 999),
            ],
          ),
        ],
      ),
    );
  }
}

class ListRowSkeleton extends StatelessWidget {
  const ListRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppDimensions.brLarge,
        border: Border.all(color: c.border),
      ),
      child: const Row(
        children: [
          LoadingSkeleton(height: 54, width: 54, radius: 17),
          SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingSkeleton(height: 14, width: 140),
                SizedBox(height: AppDimensions.space8),
                LoadingSkeleton(height: 11, width: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Two-column skeleton grid matching the catalogue layout.
class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: AppDimensions.pagePadding,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppDimensions.space12,
        crossAxisSpacing: AppDimensions.space12,
        childAspectRatio: 0.63,
      ),
      itemCount: count,
      itemBuilder: (context, _) => const ProductCardSkeleton(),
    );
  }
}
