import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/company_card.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/product_illustration.dart';
import '../../../../core/widgets/quantity_selector.dart';
import '../../../../core/widgets/rating_widget.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../companies/presentation/providers/company_provider.dart';
import '../providers/product_provider.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  const ProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  int _quantity = 1;
  bool _favourite = false;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final product = ref.watch(productByIdProvider(widget.productId));

    if (product == null) {
      return Scaffold(
        body: SafeArea(
          child: EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Mahsulot topilmadi',
            subtitle: 'Ehtimol u katalogdan olib tashlangan.',
            actionLabel: 'Orqaga',
            onAction: () => context.pop(),
          ),
        ),
      );
    }

    final visual = EnergyVisualX.fromCategory(product.categoryId, name: product.name);
    final cheapest = ref.watch(companyHighlightsProvider).cheapestId;
    final bestCompany =
        cheapest == null ? null : ref.watch(companyByIdProvider(cheapest));
    final total = product.price * _quantity;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: AppDimensions.heroImageHeight,
            backgroundColor: c.background,
            surfaceTintColor: Colors.transparent,
            leadingWidth: 64,
            leading: Padding(
              padding: const EdgeInsets.only(left: AppDimensions.gutter),
              child: Center(
                child: AppIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  iconSize: 16,
                  onTap: () => context.pop(),
                ),
              ),
            ),
            actions: [
              AppIconButton(
                icon: _favourite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                foreground: _favourite ? c.danger : c.textPrimary,
                onTap: () => setState(() => _favourite = !_favourite),
              ),
              const SizedBox(width: AppDimensions.space8),
              AppIconButton(
                icon: Icons.ios_share_rounded,
                iconSize: 18,
                onTap: () => AppToast.show(context, 'Havola nusxalandi'),
              ),
              const SizedBox(width: AppDimensions.gutter),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: product.imageUrl.startsWith('http')
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => ProductIllustration(visual: visual),
                          errorWidget: (_, __, ___) => ProductIllustration(visual: visual),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                c.background.withValues(alpha: 0.9),
                              ],
                              stops: const [0.6, 1],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            visual.accent.withValues(alpha: c.isDark ? 0.28 : 0.16),
                            c.background,
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: ProductIllustration(visual: visual, showStage: false),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.gutter,
                AppDimensions.space4,
                AppDimensions.gutter,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppPill(
                        label: product.isAvailable ? 'Mavjud' : 'Mavjud emas',
                        tone: product.isAvailable ? PillTone.success : PillTone.neutral,
                        icon: product.isAvailable
                            ? Icons.check_circle_rounded
                            : Icons.remove_circle_outline_rounded,
                      ),
                      if (product.isPopular) ...[
                        const SizedBox(width: AppDimensions.space6),
                        const AppPill(
                          label: 'Ommabop',
                          tone: PillTone.flame,
                          icon: Icons.local_fire_department_rounded,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  Text(
                    product.name,
                    style: AppTypography.title1.copyWith(color: c.textPrimary),
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  Row(
                    children: [
                      RatingWidget(
                        rating: product.rating,
                        reviewCount: product.reviewCount,
                        size: 14,
                        showReviewsLabel: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      Text(
                        AppFormatters.currency(product.price),
                        style: AppTypography.priceLarge.copyWith(color: c.textPrimary),
                      ),
                      const SizedBox(width: AppDimensions.space8),
                      if (product.hasDiscount) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            AppFormatters.currency(product.oldPrice!),
                            style: AppTypography.callout.copyWith(
                              color: c.textTertiary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: AppPill(
                            label: '-${product.discountPercent}%',
                            tone: PillTone.danger,
                            filled: true,
                            dense: true,
                          ),
                        ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            '/ ${product.unit}',
                            style: AppTypography.callout.copyWith(color: c.textTertiary),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space20),
                  _SellerRow(
                    companyName: product.companyName,
                    onTap: () => context.push('/companies'),
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  const _GuaranteeStrip(),
                  const SizedBox(height: AppDimensions.space24),
                  Text(
                    'Tavsif',
                    style: AppTypography.title3.copyWith(color: c.textPrimary),
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  Text(
                    product.description ?? '',
                    style: AppTypography.body.copyWith(
                      color: c.textSecondary,
                      height: 1.55,
                    ),
                  ),
                  if (product.specs.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.space24),
                    Text(
                      'Xususiyatlari',
                      style: AppTypography.title3.copyWith(color: c.textPrimary),
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space16,
                        vertical: AppDimensions.space4,
                      ),
                      child: Column(
                        children: [
                          for (final entry in product.specs.entries)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppDimensions.space10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: AppTypography.callout
                                          .copyWith(color: c.textSecondary),
                                    ),
                                  ),
                                  Text(
                                    entry.value,
                                    style: AppTypography.callout.copyWith(
                                      color: c.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (bestCompany != null) ...[
                    const SizedBox(height: AppDimensions.space24),
                    AppCard(
                      onTap: () => context.push('/companies'),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          c.primarySoft,
                          c.primarySoft.withValues(alpha: c.isDark ? 0.6 : 0.4),
                        ],
                      ),
                      borderColor: c.primary.withValues(alpha: 0.25),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: c.primary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.compare_arrows_rounded,
                                color: c.onPrimary, size: 22),
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '6 ta kompaniyani solishtiring',
                                  style: AppTypography.callout.copyWith(
                                    color: c.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Eng arzoni: ${bestCompany.name} · '
                                  '${AppFormatters.currency(bestCompany.totalPrice)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption
                                      .copyWith(color: c.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: c.primary, size: 20),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppDimensions.space40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BuyBar(
        quantity: _quantity,
        total: total,
        enabled: product.isAvailable,
        onIncrement: () => setState(() => _quantity++),
        onDecrement: () => setState(() => _quantity--),
        onAdd: () {
          for (var i = 0; i < _quantity; i++) {
            ref.read(cartProvider.notifier).add(product);
          }
          AppToast.show(
            context,
            'Savatga qo‘shildi',
            tone: ToastTone.success,
          );
          context.push('/cart');
        },
      ),
    );
  }
}

class _SellerRow extends StatelessWidget {
  const _SellerRow({required this.companyName, required this.onTap});

  final String companyName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.space12),
      child: Row(
        children: [
          CompanyLogo(name: companyName, size: 40),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sotuvchi',
                  style: AppTypography.caption2.copyWith(color: c.textTertiary),
                ),
                Text(
                  companyName,
                  style: AppTypography.callout.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Barcha takliflar',
            style: AppTypography.caption.copyWith(
              color: c.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 18, color: c.primary),
        ],
      ),
    );
  }
}

class _GuaranteeStrip extends StatelessWidget {
  const _GuaranteeStrip();

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    const items = [
      (Icons.local_shipping_rounded, 'Tez\nyetkazish'),
      (Icons.verified_user_rounded, 'Sertifikat\nbilan'),
      (Icons.replay_rounded, 'Qaytarish\nkafolati'),
    ];

    return Row(
      children: [
        for (final item in items) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.space12),
              decoration: BoxDecoration(
                color: c.isDark ? c.surfaceMuted : c.backgroundSunken,
                borderRadius: AppDimensions.brSmall,
              ),
              child: Column(
                children: [
                  Icon(item.$1, size: 19, color: c.primary),
                  const SizedBox(height: 6),
                  Text(
                    item.$2,
                    textAlign: TextAlign.center,
                    style: AppTypography.caption2.copyWith(
                      color: c.textSecondary,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (item != items.last) const SizedBox(width: AppDimensions.space8),
        ],
      ],
    );
  }
}

class _BuyBar extends StatelessWidget {
  const _BuyBar({
    required this.quantity,
    required this.total,
    required this.enabled,
    required this.onIncrement,
    required this.onDecrement,
    required this.onAdd,
  });

  final int quantity;
  final int total;
  final bool enabled;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.separator)),
        boxShadow: c.shadowLg,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.gutter,
            AppDimensions.space12,
            AppDimensions.gutter,
            AppDimensions.space12,
          ),
          child: Row(
            children: [
              QuantitySelector(
                quantity: quantity,
                onIncrement: onIncrement,
                onDecrement: onDecrement,
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: AppButton(
                  label: enabled ? 'Savatga' : 'Mavjud emas',
                  trailingLabel: enabled ? AppFormatters.currencyShort(total) : null,
                  icon: enabled ? Icons.shopping_bag_outlined : null,
                  onPressed: enabled ? onAdd : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
