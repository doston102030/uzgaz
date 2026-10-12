import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../addresses/presentation/providers/address_provider.dart';
import '../../../companies/domain/entities/company.dart';
import '../providers/checkout_provider.dart';

/// "Yetkazib berish" vs "O‘zim borib olaman". The difference is made
/// obvious: each option states its price and what happens next.
class DeliveryMethodPage extends ConsumerWidget {
  const DeliveryMethodPage({super.key, this.company});

  final Company? company;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final method = ref.watch(deliveryMethodProvider);
    final Company selectedCompany =
        company ?? ref.watch(effectiveCompanyProvider);
    final address = ref.watch(selectedAddressProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const AppSliverNavBar(
            title: 'Yetkazib berish',
            subtitle: 'Buyurtmani qanday olasiz?',
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.gutter,
              AppDimensions.space12,
              AppDimensions.gutter,
              AppDimensions.space32,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  _MethodCard(
                    method: DeliveryMethod.delivery,
                    selected: method == DeliveryMethod.delivery,
                    price: selectedCompany.deliveryFee,
                    detail: address?.fullAddress ?? 'Manzil tanlanmagan',
                    eta:
                        'Taxminan ${AppFormatters.duration(selectedCompany.etaMinutes)}',
                    onTap: () => ref
                        .read(deliveryMethodProvider.notifier)
                        .state = DeliveryMethod.delivery,
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  _MethodCard(
                    method: DeliveryMethod.selfPickup,
                    selected: method == DeliveryMethod.selfPickup,
                    price: 0,
                    detail: selectedCompany.address.trim().isEmpty ||
                            RegExp(r'^[?\s]+$')
                                .hasMatch(selectedCompany.address)
                        ? 'Manzilni sotuvchidan aniqlashtiring'
                        : selectedCompany.address,
                    eta:
                        '${AppFormatters.distance(selectedCompany.distanceKm)} · ${selectedCompany.workingHours}',
                    onTap: () => ref
                        .read(deliveryMethodProvider.notifier)
                        .state = DeliveryMethod.selfPickup,
                  ),
                  const SizedBox(height: AppDimensions.space20),
                  AnimatedSize(
                    duration: AppMotion.base,
                    curve: AppMotion.standard,
                    child: method == DeliveryMethod.delivery
                        ? _AddressBlock(
                            address: address?.fullAddress,
                            onChange: () => context.push('/addresses'),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              'Olib ketish vaqtini sotuvchi bilan kelishib oling.',
                              style: AppTypography.caption
                                  .copyWith(color: c.textSecondary),
                            ),
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
          boxShadow: c.shadowSm,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.gutter, vertical: 12),
            child: AppButton(
              label: 'Davom etish',
              size: AppButtonSize.medium,
              trailingIcon: Icons.arrow_forward_rounded,
              onPressed: method == DeliveryMethod.delivery && address == null
                  ? null
                  : () {
                      ref.read(selectedCompanyProvider.notifier).state =
                          selectedCompany;
                      context.push('/checkout');
                    },
            ),
          ),
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.method,
    required this.selected,
    required this.price,
    required this.detail,
    required this.eta,
    required this.onTap,
  });

  final DeliveryMethod method;
  final bool selected;
  final int price;
  final String detail;
  final String eta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppCard(
      onTap: onTap,
      selected: selected,
      elevation: AppElevation.none,
      padding: const EdgeInsets.all(AppDimensions.space12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: selected ? c.brandGradient : null,
              color: selected ? null : c.surfaceMuted,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              method.icon,
              size: 20,
              color: selected ? c.onPrimary : c.textSecondary,
            ),
          ),
          const SizedBox(width: AppDimensions.space10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        method.labelUz,
                        style: AppTypography.headline
                            .copyWith(color: c.textPrimary),
                      ),
                    ),
                    AppPill(
                      label:
                          price == 0 ? 'Bepul' : AppFormatters.currency(price),
                      tone: price == 0 ? PillTone.success : PillTone.neutral,
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const SizedBox(height: AppDimensions.space8),
                Row(
                  children: [
                    Icon(
                      method == DeliveryMethod.delivery
                          ? Icons.place_outlined
                          : Icons.storefront_outlined,
                      size: 13,
                      color: c.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption2
                            .copyWith(color: c.textTertiary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 13, color: c.textTertiary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        eta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption2
                            .copyWith(color: c.textTertiary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressBlock extends StatelessWidget {
  const _AddressBlock({required this.address, required this.onChange});

  final String? address;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppCard(
      key: const ValueKey('address'),
      onTap: onChange,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: c.primarySoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.home_rounded, size: 20, color: c.primary),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yetkazish manzili',
                  style: AppTypography.caption2.copyWith(color: c.textTertiary),
                ),
                const SizedBox(height: 2),
                Text(
                  address ?? 'Manzil tanlanmagan',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.callout.copyWith(
                    color: address == null ? c.danger : c.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            address == null ? 'Tanlash' : 'O‘zgartirish',
            style: AppTypography.caption.copyWith(
              color: c.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
