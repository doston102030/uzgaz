import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/typography.dart';
import '../../features/products/domain/entities/product.dart';
import '../utils/formatters.dart';
import 'app_segmented_control.dart';
import 'app_surface.dart';
import 'app_tappable.dart';
import 'company_card.dart';
import 'price_row.dart';
import 'product_illustration.dart';

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
    final illustration = ProductIllustration(visual: visual, radius: 0);

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      radius: AppDimensions.radiusLarge,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Edge-to-edge photo; the card's own clip rounds the top corners.
          SizedBox(
            height: AppDimensions.productImageHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                product.imageUrl.startsWith('http')
                    // `contain` — mahsulot rasmi qirqilmasdan to'liq ko'rinadi
                    // (balon uzun, `cover` uning past/yuqorisini kesardi).
                    ? ColoredBox(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.space6),
                          child: CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => illustration,
                            errorWidget: (_, __, ___) => illustration,
                          ),
                        ),
                      )
                    : illustration,
                if (badge != null)
                  Positioned(
                    left: AppDimensions.space10,
                    top: AppDimensions.space10,
                    child: AppPill(label: badge!, tone: badgeTone, dense: true, filled: true),
                  ),
                Positioned(
                  left: AppDimensions.space10,
                  bottom: AppDimensions.space10,
                  child: _RatingChip(
                    rating: product.rating,
                    reviewCount: product.reviewCount,
                  ),
                ),
                if (!product.isAvailable)
                  ColoredBox(
                    color: c.surface.withValues(alpha: 0.72),
                    child: const Center(
                      child: AppPill(label: 'Mavjud emas', tone: PillTone.neutral, dense: true),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.space12,
                AppDimensions.space10,
                AppDimensions.space10,
                AppDimensions.space12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headline.copyWith(
                      color: c.textPrimary,
                      fontSize: 15,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Kompaniya: logo + yirik, ajralib turadigan nom.
                  Row(
                    children: [
                      CompanyLogo(name: product.companyName, size: 22, radius: 7),
                      const SizedBox(width: AppDimensions.space6),
                      Expanded(
                        child: Text(
                          product.companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.callout.copyWith(
                            color: c.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: _PriceBlock(product: product)),
                      const SizedBox(width: AppDimensions.space6),
                      _AddButton(enabled: product.isAvailable, onTap: onAdd),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted "★ 4.9 (301)" chip pinned to the photo's corner — keeps the
/// text block below down to name, seller and price.
class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.rating, required this.reviewCount});

  final double rating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 3, 7, 3),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.92),
        borderRadius: AppDimensions.brPill,
        boxShadow: c.shadowSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: c.star),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: AppTypography.numeric.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '($reviewCount)',
            style: AppTypography.caption2.copyWith(
              fontWeight: FontWeight.w500,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Old price struck through (when discounted), the price with an inline
/// "so'm", and what one unit means ("1 dona uchun", "1 litr uchun").
class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (product.hasDiscount)
          Text(
            AppFormatters.currencyShort(product.oldPrice!),
            maxLines: 1,
            style: AppTypography.caption.copyWith(
              color: c.textTertiary,
              decoration: TextDecoration.lineThrough,
              decorationColor: c.textTertiary,
            ),
          ),
        PriceText(
          product.price,
          color: product.hasDiscount ? c.danger : null,
        ),
        Text(
          '1 ${product.unit} uchun',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption2.copyWith(
            color: c.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Savatga qo‘shish',
      child: AppTappable(
        onTap: enabled ? onTap : null,
        pressedScale: 0.85,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: enabled ? c.brandGradient : null,
            color: enabled ? null : c.surfaceMuted,
            shape: BoxShape.circle,
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: c.primary.withValues(alpha: 0.24),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            Icons.add_rounded,
            size: 20,
            color: enabled ? c.onPrimary : c.textTertiary,
          ),
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
