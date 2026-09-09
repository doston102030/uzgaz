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
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/company_card.dart';
import '../../../../core/widgets/price_row.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../core/widgets/product_illustration.dart';
import '../../../addresses/presentation/providers/address_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../providers/checkout_provider.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final items = ref.watch(cartProvider);
    final subtotal = ref.watch(cartTotalProvider);
    final deliveryFee = ref.watch(deliveryFeeProvider);
    final total = ref.watch(orderTotalProvider);
    final method = ref.watch(deliveryMethodProvider);
    final company = ref.watch(effectiveCompanyProvider);
    final address = ref.watch(selectedAddressProvider);
    final user = ref.watch(authProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const AppSliverNavBar(
            title: 'Rasmiylashtirish',
            subtitle: 'Buyurtmani tasdiqlashdan oldin tekshiring',
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
                children: [
                  const _CheckoutSteps(current: 1),
                  const SizedBox(height: AppDimensions.space20),

                  // Delivery method + destination
                  _Section(
                    title: method.labelUz,
                    icon: method.icon,
                    actionLabel: 'O‘zgartirish',
                    onAction: () => context.push('/delivery-method'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method == DeliveryMethod.delivery
                              ? (address?.fullAddress ?? 'Manzil tanlanmagan')
                              : '${company.name} · ${company.address}',
                          style: AppTypography.callout.copyWith(
                            color: c.textPrimary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space8),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 14, color: c.textTertiary),
                            const SizedBox(width: 4),
                            Text(
                              method == DeliveryMethod.delivery
                                  ? 'Taxminan ${AppFormatters.duration(company.etaMinutes)} ichida'
                                  : 'Ish vaqti: ${company.workingHours}',
                              style: AppTypography.caption
                                  .copyWith(color: c.textTertiary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space12),

                  // Company
                  _Section(
                    title: 'Kompaniya',
                    icon: Icons.storefront_rounded,
                    actionLabel: 'Solishtirish',
                    onAction: () => context.push('/companies'),
                    child: Row(
                      children: [
                        CompanyLogo(name: company.name, size: 42),
                        const SizedBox(width: AppDimensions.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                company.name,
                                style: AppTypography.callout.copyWith(
                                  color: c.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '★ ${company.rating} · ${AppFormatters.distance(company.distanceKm)}',
                                style: AppTypography.caption
                                    .copyWith(color: c.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (company.deliveryFee == 0)
                          const AppPill(
                            label: 'Yetkazish bepul',
                            tone: PillTone.success,
                            dense: true,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space12),

                  // Items
                  _Section(
                    title: 'Mahsulotlar (${items.length})',
                    icon: Icons.shopping_bag_outlined,
                    actionLabel: 'Savat',
                    onAction: () => context.pop(),
                    child: Column(
                      children: [
                        for (int i = 0; i < items.length; i++) ...[
                          if (i != 0)
                            Divider(height: AppDimensions.space20, color: c.separator),
                          ProductListTile(
                            title: items[i].product.name,
                            subtitle: items[i].product.companyName,
                            price: items[i].product.price,
                            quantity: items[i].quantity,
                            visual: EnergyVisualX.fromCategory(
                              items[i].product.categoryId,
                              name: items[i].product.name,
                            ),
                            trailing: Text(
                              AppFormatters.currency(items[i].subtotal),
                              style: AppTypography.priceSmall
                                  .copyWith(color: c.textPrimary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space12),

                  // Contact
                  _Section(
                    title: 'Aloqa ma’lumotlari',
                    icon: Icons.person_outline_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Mehmon foydalanuvchi',
                          style: AppTypography.callout.copyWith(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppFormatters.phone(user?.phone ?? '+998901234567'),
                          style: AppTypography.callout.copyWith(color: c.textSecondary),
                        ),
                        const SizedBox(height: AppDimensions.space14),
                        AppTextField(
                          controller: _noteController,
                          hint: 'Kuryer uchun izoh (ixtiyoriy)',
                          prefixIcon: Icons.chat_bubble_outline_rounded,
                          maxLines: 2,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space12),

                  // Summary
                  _Section(
                    title: 'To‘lov',
                    icon: Icons.receipt_long_rounded,
                    child: Column(
                      children: [
                        PriceRow(label: 'Mahsulotlar narxi', amount: subtotal),
                        PriceRow(
                          label: 'Yetkazib berish',
                          amount: deliveryFee,
                          isFree: deliveryFee == 0,
                          hint: method == DeliveryMethod.selfPickup
                              ? 'O‘zingiz olib ketasiz'
                              : null,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: AppDimensions.space10),
                          child: DashedDivider(),
                        ),
                        PriceRow(label: 'Jami to‘lov', amount: total, isTotal: true),
                      ],
                    ),
                  ),
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
              label: 'To‘lovga o‘tish',
              trailingLabel: AppFormatters.currencyShort(total),
              onPressed: items.isEmpty ||
                      (method == DeliveryMethod.delivery && address == null)
                  ? null
                  : () => context.push('/payment'),
            ),
          ),
        ),
      ),
    );
  }
}

/// Three-step progress so the buyer always knows how much is left.
class _CheckoutSteps extends StatelessWidget {
  const _CheckoutSteps({required this.current});

  final int current;

  static const _labels = ['Savat', 'Manzil', 'To‘lov'];

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Row(
      children: [
        for (int i = 0; i < _labels.length; i++) ...[
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: i <= current ? c.primary : c.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: i < current
                ? Icon(Icons.check_rounded, size: 13, color: c.onPrimary)
                : Center(
                    child: Text(
                      '${i + 1}',
                      style: AppTypography.caption2.copyWith(
                        color: i == current ? c.onPrimary : c.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: AppDimensions.space6),
          Text(
            _labels[i],
            style: AppTypography.caption.copyWith(
              color: i <= current ? c.textPrimary : c.textTertiary,
              fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          if (i != _labels.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: AppDimensions.space8),
                decoration: BoxDecoration(
                  color: i < current ? c.primary : c.border,
                  borderRadius: AppDimensions.brPill,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: c.textTertiary),
              const SizedBox(width: AppDimensions.space6),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    color: c.textTertiary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null)
                AppButton(
                  label: actionLabel!,
                  variant: AppButtonVariant.text,
                  size: AppButtonSize.small,
                  expand: false,
                  onPressed: onAction,
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.space10),
          child,
        ],
      ),
    );
  }
}
