import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/price_row.dart';
import '../../../../core/widgets/product_illustration.dart';
import '../../../../core/widgets/quantity_selector.dart';
import '../../../checkout/presentation/providers/checkout_provider.dart';
import '../../domain/entities/cart_item.dart';
import '../providers/cart_provider.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final items = ref.watch(cartProvider);
    final subtotal = ref.watch(cartTotalProvider);
    final deliveryFee = ref.watch(deliveryFeeProvider);
    final company = ref.watch(effectiveCompanyProvider);
    final total = subtotal + deliveryFee;

    if (items.isEmpty) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            const AppSliverNavBar(title: 'Savat'),
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.shopping_bag_outlined,
                title: 'Savatingiz bo‘sh',
                subtitle:
                    'Katalogdan gaz ballon, yoqilg‘i yoki boshqa energiya '
                    'mahsulotlarini tanlang.',
                actionLabel: 'Katalogga o‘tish',
                onAction: () => context.go('/catalog'),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverNavBar(
            title: 'Savat',
            subtitle: '${items.length} ta mahsulot',
            actions: [
              AppIconButton(
                icon: Icons.delete_outline_rounded,
                onTap: () async {
                  final confirmed = await CustomDialog.confirm(
                    context,
                    title: 'Savatni tozalash',
                    message: 'Barcha mahsulotlar savatdan olib tashlanadi.',
                    confirmLabel: 'Tozalash',
                    icon: Icons.delete_outline_rounded,
                    destructive: true,
                  );
                  if (confirmed) ref.read(cartProvider.notifier).clear();
                },
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.gutter,
              AppDimensions.space12,
              AppDimensions.gutter,
              AppDimensions.space16,
            ),
            sliver: SliverList.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimensions.space10),
              itemBuilder: (context, i) => _CartRow(item: items[i]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.gutter),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  _PromoRow(
                    onTap: () => AppToast.show(
                      context,
                      'Promokod maydoni to‘lov bosqichida ochiladi',
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  AppCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.storefront_rounded,
                                size: 16, color: c.textTertiary),
                            const SizedBox(width: AppDimensions.space6),
                            Expanded(
                              child: Text(
                                company.name,
                                style: AppTypography.callout.copyWith(
                                  color: c.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            AppButton(
                              label: 'O‘zgartirish',
                              variant: AppButtonVariant.text,
                              size: AppButtonSize.small,
                              expand: false,
                              onPressed: () => context.push('/companies'),
                            ),
                          ],
                        ),
                        Divider(height: AppDimensions.space20, color: c.separator),
                        PriceRow(label: 'Mahsulotlar', amount: subtotal),
                        PriceRow(
                          label: 'Yetkazib berish',
                          amount: deliveryFee,
                          isFree: deliveryFee == 0,
                          hint: deliveryFee == 0
                              ? 'O‘zingiz olib ketasiz'
                              : '${company.name} · ${AppFormatters.eta(company.etaMinutes)}',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: AppDimensions.space10),
                          child: DashedDivider(),
                        ),
                        PriceRow(label: 'Jami', amount: total, isTotal: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppDimensions.space32),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.separator)),
          boxShadow: c.shadowLg,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.gutter),
            child: AppButton(
              label: 'Rasmiylashtirish',
              trailingLabel: AppFormatters.currencyShort(total),
              onPressed: () => context.push('/checkout'),
            ),
          ),
        ),
      ),
    );
  }
}

class _CartRow extends ConsumerWidget {
  const _CartRow({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final notifier = ref.read(cartProvider.notifier);

    return Dismissible(
      key: ValueKey(item.product.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimensions.space20),
        decoration: BoxDecoration(
          color: c.danger,
          borderRadius: AppDimensions.brLarge,
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        notifier.remove(item.product.id);
        AppToast.show(
          context,
          '${item.product.name} olib tashlandi',
          tone: ToastTone.warning,
        );
      },
      child: AppCard(
        padding: const EdgeInsets.all(AppDimensions.space12),
        onTap: () => context.push('/product/${item.product.id}'),
        child: Row(
          children: [
            EnergyAvatar(
              visual: EnergyVisualX.fromCategory(
                item.product.categoryId,
                name: item.product.name,
              ),
              size: 58,
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.callout.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${AppFormatters.currency(item.product.price)} / ${item.product.unit}',
                    style: AppTypography.caption.copyWith(color: c.textTertiary),
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppFormatters.currency(item.subtotal),
                          style: AppTypography.priceSmall.copyWith(color: c.primary),
                        ),
                      ),
                      QuantitySelector(
                        quantity: item.quantity,
                        compact: true,
                        onIncrement: () => notifier.increment(item.product.id),
                        onDecrement: () => notifier.decrement(item.product.id),
                        onRemove: () => notifier.remove(item.product.id),
                      ),
                    ],
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

class _PromoRow extends StatelessWidget {
  const _PromoRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.space14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: c.tint(c.warning, 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.local_offer_rounded, size: 18, color: c.warning),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Text(
              'Promokod kiritish',
              style: AppTypography.callout.copyWith(
                color: c.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 20, color: c.textTertiary),
        ],
      ),
    );
  }
}
