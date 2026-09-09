import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';

/// Compact rating: filled star, tabular score, muted review count.
class RatingWidget extends StatelessWidget {
  const RatingWidget({
    super.key,
    required this.rating,
    this.reviewCount,
    this.size = 13,
    this.color,
    this.showReviewsLabel = false,
  });

  final double rating;
  final int? reviewCount;
  final double size;
  final Color? color;
  final bool showReviewsLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: size + 4, color: c.star),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: AppTypography.numeric.copyWith(
            fontSize: size,
            color: color ?? c.textPrimary,
          ),
        ),
        if (reviewCount != null) ...[
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              showReviewsLabel ? '($reviewCount ta sharh)' : '($reviewCount)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                fontSize: size - 1,
                color: c.textTertiary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Five-star breakdown used on the product detail sheet.
class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 1; i <= 5; i++)
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Icon(
              rating >= i
                  ? Icons.star_rounded
                  : (rating >= i - 0.5 ? Icons.star_half_rounded : Icons.star_outline_rounded),
              size: size,
              color: rating >= i - 0.5 ? c.star : c.borderStrong,
            ),
          ),
      ],
    );
  }
}
