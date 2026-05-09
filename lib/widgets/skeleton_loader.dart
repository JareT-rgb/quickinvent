import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  static Widget productCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusMedium,
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const SkeletonLoader(width: 60, height: 60),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 150, height: 16),
                const SizedBox(height: 8),
                SkeletonLoader(width: 100, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const SkeletonLoader(width: 60, height: 20),
        ],
      ),
    );
  }

  static Widget posGridItem() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(child: SkeletonLoader(width: double.infinity, height: double.infinity)),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 80, height: 12),
                const SizedBox(height: 8),
                SkeletonLoader(width: 40, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
