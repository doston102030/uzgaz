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
/// Records when the buyer will pay the seller. No money is collected here.
class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  bool _loading = false;

  Future<void> _pay() async {
    if (_loading) return;
    final total = ref.read(orderTotalProvider);
    final method = ref.read(paymentMethodProvider);
    // Online methods must not create a pretend successful payment.
    if (method != PaymentMethod.cashOnDelivery &&
        method != PaymentMethod.sellerPrepayment) {
      return;
    }

    final confirmed = await CustomDialog.confirm(
      context,
      title: 'Buyurtmani tasdiqlash',
      message: method == PaymentMethod.cashOnDelivery
          ? 'Mahsulotni qabul qilganda to‘laysiz. Hozir pul yechilmaydi.'
          : 'Buyurtmadan keyin sotuvchidan rekvizitlarni olib, kelishilgan usulda oldindan to‘laysiz. Ilova pul yechmaydi.',
      highlight: AppFormatters.currency(total),
      confirmLabel: 'Buyurtma berish',
      icon: Icons.verified_rounded,
    );
    if (!confirmed || !mounted) return;

    setState(() => _loading = true);

    final items = ref.read(cartProvider);
    final company = ref.read(effectiveCompanyProvider);
    final deliveryMethod = ref.read(deliveryMethodProvider);

    final Order order;
    try {
      order = await ref.read(ordersProvider.notifier).place(
            companyId: company.id,
            companyName: company.name,
            items: [
              for (final item in items)
                OrderItem(
                  productId: item.product.id,
                  productName: item.product.name,
                  quantity: item.quantity,
                  price: item.product.price,
                  categoryId: item.product.categoryId,
                ),
            ],
            deliveryFee: ref.read(deliveryFeeProvider),
            total: total,
            deliveryMethod: deliveryMethod,
            paymentMethod: method,
            address: ref.read(checkoutAddressProvider),
          );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppToast.show(
        context,
        'Buyurtma yuborilmadi — internetni tekshirib, qayta urinib ko‘ring',
        tone: ToastTone.danger,
      );
      return;
    }
    if (!mounted) return;

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
    final onDelivery = selected == PaymentMethod.cashOnDelivery;

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
                  Text('QACHON TO‘LAYSIZ?',
                      style: AppTypography.overline
                          .copyWith(color: c.textSecondary)),
                  const SizedBox(height: AppDimensions.space10),
                  PaymentMethodCard(
                    method: PaymentMethod.cashOnDelivery,
                    selected: onDelivery,
                    onTap: () => ref
                        .read(paymentMethodProvider.notifier)
                        .state = PaymentMethod.cashOnDelivery,
                  ),
                  const SizedBox(height: AppDimensions.space10),
                  PaymentMethodCard(
                    method: PaymentMethod.sellerPrepayment,
                    selected: !onDelivery,
                    onTap: () => ref
                        .read(paymentMethodProvider.notifier)
                        .state = PaymentMethod.sellerPrepayment,
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  if (onDelivery)
                    Text(
                        'Buyurtmani tasdiqlang. Mahsulotni olganda sotuvchiga to‘laysiz.',
                        style: AppTypography.callout
                            .copyWith(color: c.textSecondary)),
                  if (!onDelivery) ...[
                    Text(
                        'Buyurtmadan keyin sotuvchi bilan bog‘lanib, to‘lov rekvizitlari va shartlarini kelishib oling. Ilova kartangizdan pul yechmaydi.',
                        style: AppTypography.callout
                            .copyWith(color: c.textSecondary)),
                  ],
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
              label: 'Buyurtma berish',
              icon: Icons.check_rounded,
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
        color: c.surface,
        borderRadius: AppDimensions.brLarge,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'TO‘LOV SUMMASI',
                style: AppTypography.overline.copyWith(
                  color: c.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: c.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shield_outlined, color: c.primary, size: 18),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              AppFormatters.currency(total),
              style: AppTypography.title1.copyWith(color: c.textPrimary),
            ),
          ),
          const SizedBox(height: AppDimensions.space4),
          Text(
            'Yetkazib berish narxi hisobga olingan',
            style: AppTypography.caption.copyWith(
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
