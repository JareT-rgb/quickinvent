import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import 'premium_widgets.dart';

class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;
  final BoxFit fit;

  const ProductImage({
    super.key,
    this.imageUrl,
    this.size = 40,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholderIcon = Icons.image_outlined,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = width ?? size;
    final effectiveHeight = height ?? size;
    final effectiveRadius = borderRadius ?? AppTheme.radiusSmall;

    // Safety check for null or empty URL
    final hasUrl = imageUrl != null && imageUrl!.trim().isNotEmpty;

    if (!hasUrl) {
      return _buildPlaceholder(effectiveWidth, effectiveHeight, effectiveRadius);
    }

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: effectiveWidth,
        height: effectiveHeight,
        fit: fit,
        placeholder: (context, url) => _buildLoading(effectiveWidth, effectiveHeight, effectiveRadius),
        errorWidget: (context, url, error) => _buildPlaceholder(effectiveWidth, effectiveHeight, effectiveRadius, isError: true),
      ),
    );
  }

  Widget _buildPlaceholder(double w, double h, BorderRadius radius, {bool isError = false}) {
    // Ensure width and height are finite for calculations
    final safeW = w.isFinite ? w : 40.0;
    final iconSize = safeW * 0.5;
    
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: isError ? AppTheme.error.withValues(alpha: 0.05) : AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: radius,
      ),
      child: Icon(
        isError ? Icons.broken_image_outlined : placeholderIcon,
        size: iconSize.clamp(12.0, 48.0).toDouble(),
        color: (isError ? AppTheme.error : AppTheme.primary).withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildLoading(double w, double h, BorderRadius radius) {
    return SkeletonLoader(
      width: w,
      height: h,
      borderRadius: radius.topLeft.x,
    );
  }
}
