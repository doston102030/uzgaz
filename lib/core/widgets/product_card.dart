import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/motion.dart';
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
    final visual =
        EnergyVisualX.fromCategory(product.categoryId, name: product.name);
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
                _CardPhoto(
                  productId: product.id,
                  images: product.gallery,
                  fallback: illustration,
                ),
                if (badge != null)
                  Positioned(
                    left: AppDimensions.space10,
                    top: AppDimensions.space10,
                    child: AppPill(
                        label: badge!,
                        tone: badgeTone,
                        dense: true,
                        filled: true),
                  ),
                if (product.reviewCount > 0)
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
                      child: AppPill(
                          label: 'Mavjud emas',
                          tone: PillTone.neutral,
                          dense: true),
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
                      CompanyLogo(
                          name: product.companyName, size: 22, radius: 7),
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

/// The card's photo area. Several photos cross-fade by themselves — each
/// card on its own beat, so a grid never flips all at once — and only once
/// the next photo is loaded. A neutral background keeps the product in focus.
class _CardPhoto extends StatefulWidget {
  const _CardPhoto(
      {required this.productId, required this.images, required this.fallback});

  final String productId;
  final List<String> images;
  final Widget fallback;

  @override
  State<_CardPhoto> createState() => _CardPhotoState();
}

/// One clock for every card's photo rotation. Each card used to run its
/// own timer at its own offset, so with N cards on screen a cross-fade —
/// and a full redraw — started N times per cycle. On one shared beat the
/// cards turn together and the screen redraws once per beat.
class _PhotoBeat {
  static const every = Duration(milliseconds: 4500);
  static final _listeners = <VoidCallback>{};
  static Timer? _timer;

  static void add(VoidCallback listener) {
    _listeners.add(listener);
    _timer ??= Timer.periodic(every, (_) {
      for (final listener in List.of(_listeners)) {
        listener();
      }
    });
  }

  static void remove(VoidCallback listener) {
    _listeners.remove(listener);
    if (_listeners.isEmpty) {
      _timer?.cancel();
      _timer = null;
    }
  }
}

class _CardPhotoState extends State<_CardPhoto> {
  int _index = 0;
  bool _loading = false;
  bool _listening = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(_CardPhoto old) {
    super.didUpdateWidget(old);
    if (old.productId != widget.productId ||
        !listEquals(old.images, widget.images)) {
      _generation++;
      _index = 0;
      _schedule();
    }
  }

  @override
  void dispose() {
    _PhotoBeat.remove(_next);
    super.dispose();
  }

  void _schedule() {
    final rotate = widget.images.length > 1;
    if (rotate && !_listening) {
      _PhotoBeat.add(_next);
    } else if (!rotate && _listening) {
      _PhotoBeat.remove(_next);
    }
    _listening = rotate;
  }

  Future<void> _next() async {
    if (_loading || widget.images.length < 2 || !_canTurn) return;
    _loading = true;
    final generation = _generation;
    final next = (_index + 1) % widget.images.length;
    final url = widget.images[next];
    try {
      var failed = false;
      await precacheImage(
        CachedNetworkImageProvider(url),
        context,
        onError: (_, __) => failed = true,
      );
      if (failed || !_canTurn || generation != _generation) return;
      if (_canTurn && generation == _generation) setState(() => _index = next);
    } finally {
      _loading = false;
    }
  }

  bool get _canTurn =>
      mounted &&
      TickerMode.valuesOf(context).enabled &&
      !MediaQuery.disableAnimationsOf(context) &&
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    if (images.isEmpty) return widget.fallback;
    final url = images[_index.clamp(0, images.length - 1)];
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: AppMotion.slow,
          // Keep every frame full-size while fading between different
          // photo proportions, including narrow transparent cut-outs.
          layoutBuilder: (current, previous) => Stack(
            fit: StackFit.expand,
            children: [...previous, if (current != null) current],
          ),
          child: ColoredBox(
            key: ValueKey(url),
            color: context.palette.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                fadeInDuration: AppMotion.fast,
                placeholder: (_, __) => widget.fallback,
                errorWidget: (_, __, ___) => widget.fallback,
              ),
            ),
          ),
        ),
        if (images.length > 1)
          Positioned(
            right: AppDimensions.space10,
            bottom: AppDimensions.space12,
            child: Row(
              children: [
                for (var i = 0; i < images.length; i++)
                  AnimatedContainer(
                    duration: AppMotion.base,
                    curve: AppMotion.standard,
                    margin: const EdgeInsets.only(left: 3),
                    width: i == _index ? 12 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? context.palette.textSecondary
                          : context.palette.textTertiary.withValues(alpha: 0.3),
                      borderRadius: AppDimensions.brPill,
                    ),
                  ),
              ],
            ),
          ),
      ],
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
                    style:
                        AppTypography.caption.copyWith(color: c.textTertiary),
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
