import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../../core/widgets/payment_method_card.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../checkout/presentation/providers/checkout_provider.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/presentation/providers/order_provider.dart';

/// Payment screen.
///
/// Security rule from the spec: this screen never collects or stores a
/// raw card number or CVV. Selecting a card method hands off to the
/// provider's tokenising SDK — the app only ever sees a token.
class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  bool _loading = false;

  Future<void> _pay() async {
    final total = ref.read(orderTotalProvider);
    final method = ref.read(paymentMethodProvider);

    final confirmed = await CustomDialog.confirm(
      context,
      title: 'Buyurtmani tasdiqlash',
      message: '${method.label} orqali to‘lov amalga oshiriladi.',
      highlight: AppFormatters.currency(total),
      confirmLabel: 'Ha, to‘lash',
      icon: Icons.verified_rounded,
    );
    if (!confirmed || !mounted) return;

    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;

    final items = ref.read(cartProvider);
    final company = ref.read(effectiveCompanyProvider);
    final deliveryMethod = ref.read(deliveryMethodProvider);

    final order = ref.read(ordersProvider.notifier).place(
          companyName: company.name,
          items: [
            for (final item in items)
              OrderItem(
                productName: item.product.name,
                quantity: item.quantity,
                price: item.product.price,
                categoryId: item.product.categoryId,
              ),
          ],
          total: total,
          deliveryMethod: deliveryMethod,
          address: ref.read(checkoutAddressProvider),
        );

    ref.read(lastOrderProvider.notifier).state = order;
    ref.read(cartProvider.notifier).clear();

    if (!mounted) return;
    setState(() => _loading = false);
    context.go('/order-confirmation');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final total = ref.watch(orderTotalProvider);
    final selected = ref.watch(paymentMethodProvider);
    final cards = PaymentMethod.values.where((m) => m.isCard).toList();
    final wallets = PaymentMethod.values.where((m) => !m.isCard).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const AppSliverNavBar(
            title: 'To‘lov',
            subtitle: 'To‘lov usulini tanlang',
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.gutter,
              AppDimensions.space8,
              AppDimensions.gutter,
              AppDimensions.space32,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TotalCard(total: total),
                  const SizedBox(height: AppDimensions.space24),
                  Text(
                    'MILLIY VA XALQARO KARTALAR',
                    style: AppTypography.overline.copyWith(color: c.textTertiary),
                  ),
                  const SizedBox(height: AppDimensions.space10),
                  for (final method in cards) ...[
                    PaymentMethodCard(
                      method: method,
                      selected: selected == method,
                      onTap: () =>
                          ref.read(paymentMethodProvider.notifier).state = method,
                    ),
                    const SizedBox(height: AppDimensions.space10),
                  ],
                  const SizedBox(height: AppDimensions.space8),
                  Text(
                    'TO‘LOV ILOVALARI',
                    style: AppTypography.overline.copyWith(color: c.textTertiary),
                  ),
                  const SizedBox(height: AppDimensions.space10),
                  for (final method in wallets) ...[
                    PaymentMethodCard(
                      method: method,
                      selected: selected == method,
                      onTap: () =>
                          ref.read(paymentMethodProvider.notifier).state = method,
                    ),
                    const SizedBox(height: AppDimensions.space10),
                  ],
                  const SizedBox(height: AppDimensions.space8),
                  const PaymentSecurityNote(),
                ],
              ),
            ),
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
              label: 'To‘lash',
              trailingLabel: AppFormatters.currencyShort(total),
              icon: Icons.lock_rounded,
              isLoading: _loading,
              onPressed: total == 0 ? null : _pay,
            ),
          ),
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        gradient: c.brandGradient,
        borderRadius: AppDimensions.brXLarge,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'TO‘LOV SUMMASI',
                style: AppTypography.overline.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 15),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space10),
          Text(
            AppFormatters.currency(total),
            style: AppTypography.largeTitle.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppDimensions.space4),
          Text(
            'Yetkazib berish narxi hisobga olingan',
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}
