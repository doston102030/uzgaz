import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/motion.dart';
import 'product_illustration.dart';

/// The tile every product photo sits on (cards, thumbnails, the loading
/// skeleton): a shade off the card, so transparent cut-outs and full
/// photos share one frame.
Color productPhotoTile(AppPalette c) =>
    c.isDark ? c.surfaceMuted : const Color(0xFFF3F5F9);

/// A product's own photo as a small square — cart rows, checkout and
/// order lines. The drawn category glyph stands in only when there is no
/// photo, or it fails to load.
class ProductThumb extends StatelessWidget {
  const ProductThumb({
    super.key,
    required this.imageUrl,
    required this.visual,
    this.size = 56,
  });

  final String? imageUrl;
  final EnergyVisual visual;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final fallback = EnergyAvatar(visual: visual, size: size);
    if (url == null || !url.startsWith('http')) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Container(
        width: size,
        height: size,
        color: productPhotoTile(context.palette),
        padding: EdgeInsets.all(size * 0.08),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          fadeInDuration: AppMotion.fast,
          placeholder: (_, __) => const SizedBox.shrink(),
          errorWidget: (_, __, ___) => fallback,
        ),
      ),
    );
  }
}
