import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/typography.dart';
import '../../features/products/domain/entities/product.dart';
import '../utils/formatters.dart';
import 'app_segmented_control.dart';
import 'app_surface.dart';
import 'app_tappable.dart';
import 'product_illustration.dart';
import 'rating_widget.dart';

/// Grid card used on Home ("Mashhur mahsulotlar") and in the catalogue.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAdd,
    this.badge,
    this.badgeTone = PillTone.flame,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final String? badge;
  final PillTone badgeTone;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final visual = EnergyVisualX.fromCategory(product.categoryId, name: product.name);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.space10),
      radius: AppDimensions.radiusLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: AppDimensions.productImageHeight,
                width: double.infinity,
                child: ProductIllustration(visual: visual, radius: AppDimensions.radiusSmall),
              ),
              if (badge != null)
                Positioned(
                  left: 8,
                  top: 8,
                  child: AppPill(label: badge!, tone: badgeTone, dense: true, filled: true),
                ),
              if (!product.isAvailable)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.surface.withValues(alpha: 0.72),
                      borderRadius: AppDimensions.brSmall,
                    ),
                    child: const Center(
                      child: AppPill(label: 'Mavjud emas', tone: PillTone.neutral, dense: true),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.space10),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.headline.copyWith(color: c.textPrimary, fontSize: 15),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(Icons.storefront_rounded, size: 12, color: c.textTertiary),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  product.companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: c.textTertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          RatingWidget(rating: product.rating, reviewCount: product.reviewCount, size: 12),
          const Spacer(),
          const SizedBox(height: AppDimensions.space8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppFormatters.currencyShort(product.price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.price.copyWith(color: c.textPrimary, fontSize: 16),
                    ),
                    Text(
                      "so'm / ${product.unit}",
                      style: AppTypography.caption2.copyWith(color: c.textTertiary),
                    ),
                  ],
                ),
              ),
              _AddButton(enabled: product.isAvailable, onTap: onAdd),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppTappable(
      onTap: enabled ? onTap : null,
      pressedScale: 0.85,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          gradient: enabled ? c.brandGradient : null,
          color: enabled ? null : c.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: c.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.add_rounded,
          size: 19,
          color: enabled ? c.onPrimary : c.textTertiary,
        ),
      ),
    );
  }
}

/// Horizontal product row — cart, checkout summary, order details.
class ProductListTile extends StatelessWidget {
  const ProductListTile({
    super.key,
    required this.title,
    required this.price,
    this.subtitle,
    this.visual = EnergyVisual.cylinder,
    this.trailing,
    this.quantity,
    this.onTap,
  });

  final String title;
  final int price;
  final String? subtitle;
  final EnergyVisual visual;
  final Widget? trailing;
  final int? quantity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppTappable(
      onTap: onTap,
      child: Row(
        children: [
          EnergyAvatar(visual: visual, size: 54),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.callout.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(color: c.textTertiary),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  quantity != null && quantity! > 1
                      ? '${AppFormatters.currency(price)} × $quantity'
                      : AppFormatters.currency(price),
                  style: AppTypography.priceSmall.copyWith(color: c.primary),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppDimensions.space8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
