import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/company_card.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../../core/widgets/order_status_widget.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../core/widgets/promo_carousel.dart';
import '../../../../core/widgets/service_category_grid.dart';
import '../../../../core/widgets/responsive_product_grid.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../checkout/presentation/providers/checkout_provider.dart';
import '../../../companies/domain/entities/company.dart';
import '../../../companies/presentation/providers/company_provider.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/presentation/providers/order_provider.dart';
import '../../../admin/presentation/providers/admin_provider.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../widgets/home_header.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(popularProductsProvider).take(4).toList();
    final companies = ref.watch(sortedCompaniesProvider).take(5).toList();
    final recentOrders = ref.watch(ordersProvider).take(2).toList();
    final activeOrder = ref.watch(currentOrderProvider);
    final promoActive = ref.watch(promoBannerActiveProvider);

    return Scaffold(
      // The header sits on the plain page background now, so the status
      // bar needs dark icons in light mode (light in dark mode).
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: context.palette.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: RefreshIndicator(
          color: context.palette.primary,
          backgroundColor: context.palette.surface,
          onRefresh: () {
            AppHaptics.selection();
            return Future<void>.delayed(const Duration(milliseconds: 700));
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const HomeHeader(),
                    if (activeOrder != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppDimensions.gutter,
                          AppDimensions.space16,
                          AppDimensions.gutter,
                          0,
                        ),
                        child: _LiveOrderCard(order: activeOrder),
                      ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: AppDimensions.space8),
                  child: _CategoryRail(),
                ),
              ),
              if (promoActive)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.gutter,
                      AppDimensions.space24,
                      AppDimensions.gutter,
                      0,
                    ),
                    child: PromoCarousel(
                      slides: [
                        PromoSlide(
                          title: 'Suyultirilgan gaz',
                          caption: 'Subsidiya narxida, aholi uchun',
                          accent: AppColors.success,
                          footIcon: Icons.savings_outlined,
                          icon: Icons.local_fire_department_rounded,
                          onTap: () {
                            ref.read(categoryFilterProvider.notifier).state =
                                ServiceCategory.suyultirilganGaz;
                            context.go('/catalog');
                          },
                        ),
                        PromoSlide(
                          title: 'Gaz ballon yetkazish',
                          caption: '35 daqiqada eshigingizga',
                          accent: AppColors.primary,
                          footIcon: Icons.local_shipping_outlined,
                          motionLines: true,
                          image: 'assets/images/promo_gas_cylinder.png',
                          icon: Icons.propane_tank_rounded,
                          onTap: () {
                            ref.read(categoryFilterProvider.notifier).state =
                                ServiceCategory.gazBallon;
                            context.go('/catalog');
                          },
                        ),
                        PromoSlide(
                          title: 'Elektr quvvatlash',
                          caption: 'Zaryadlash tarmog‘i kengaymoqda',
                          accent: AppColors.energyElectric,
                          footIcon: Icons.ev_station_outlined,
                          icon: Icons.bolt_rounded,
                          onTap: () => context.push('/services'),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Mashhur mahsulotlar',
                  actionLabel: 'Barchasi',
                  onAction: () => context.go('/catalog'),
                ),
              ),
              SliverPadding(
                padding: AppDimensions.pagePadding,
                sliver: ResponsiveProductGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final product = products[i];
                      return ProductCard(
                        product: product,
                        badge: product.hasDiscount
                            ? '-${product.discountPercent}%'
                            : (product.isPopular ? 'TOP' : null),
                        badgeTone:
                            product.hasDiscount ? PillTone.danger : PillTone.flame,
                        onTap: () => context.push('/product/${product.id}'),
                        onAdd: () {
                          ref.read(cartProvider.notifier).add(product);
                          AppToast.show(
                            context,
                            '${product.name} savatga qo‘shildi',
                            tone: ToastTone.success,
                            actionLabel: 'Savat',
                            onAction: () => context.push('/cart'),
                          );
                        },
                      );
                    },
                    childCount: products.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Yaqin atrofdagi kompaniyalar',
                  actionLabel: 'Solishtirish',
                  onAction: () => context.push('/companies'),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 168,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: AppDimensions.pagePadding,
                    itemCount: companies.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppDimensions.space12),
                    itemBuilder: (context, i) => _CompanyTile(
                      company: companies[i],
                      onTap: () {
                        ref.read(selectedCompanyProvider.notifier).state =
                            companies[i];
                        context.push('/companies');
                      },
                    ),
                  ),
                ),
              ),
              if (recentOrders.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'So‘nggi buyurtmalar',
                    actionLabel: 'Barchasi',
                    onAction: () => context.go('/orders'),
                  ),
                ),
                SliverPadding(
                  padding: AppDimensions.pagePadding,
                  sliver: SliverList.separated(
                    itemCount: recentOrders.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppDimensions.space10),
                    itemBuilder: (context, i) => _RecentOrderRow(
                      order: recentOrders[i],
                      onTap: () =>
                          context.push('/orders/${recentOrders[i].id}/tracking'),
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(
                child: SizedBox(height: AppDimensions.bottomBarClearance),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Live order strip — the highest-value thing on the screen for anyone
/// who already ordered, so it sits above everything else.
class _LiveOrderCard extends StatelessWidget {
  const _LiveOrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppCard(
      elevation: AppElevation.lg,
      onTap: () => context.push('/orders/${order.id}/tracking'),
      padding: const EdgeInsets.all(AppDimensions.space14),
      child: Column(
        children: [
          Row(
            children: [
              const LivePulse(),
              const SizedBox(width: AppDimensions.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          order.status.labelUz,
                          style: AppTypography.callout.copyWith(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space6),
                        Text(
                          order.orderNumber,
                          style: AppTypography.caption
                              .copyWith(color: c.textTertiary),
                        ),
                      ],
                    ),
                    Text(
                      '${order.companyName} · taxminan ${AppFormatters.time(order.eta)} da',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              Icon(Icons.chevron_right_rounded, color: c.textTertiary, size: 20),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          OrderStatusTimeline(currentStatus: order.status),
        ],
      ),
    );
  }
}

class _CategoryRail extends ConsumerWidget {
  const _CategoryRail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Xizmat turlari',
          actionLabel: 'Barchasi',
          onAction: () => context.push('/services'),
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.gutter,
            AppDimensions.space4,
            AppDimensions.gutter,
            AppDimensions.space12,
          ),
        ),
        ServiceCategoryGrid(
          padding: AppDimensions.pagePadding,
          onSelected: (category) {
            if (!ServiceCategoryGrid.isAvailable(category)) {
              AppToast.show(
                context,
                '${category.titleUz} tez orada ishga tushadi',
                icon: Icons.schedule_rounded,
              );
              return;
            }
            ref.read(categoryFilterProvider.notifier).state = category;
            context.go('/catalog');
          },
        ),
      ],
    );
  }
}

class _CompanyTile extends StatelessWidget {
  const _CompanyTile({required this.company, required this.onTap});

  final Company company;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppCard(
      width: 176,
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CompanyLogo(name: company.name, size: 34),
              const Spacer(),
              AppPill(
                label: company.isAvailable ? 'Ochiq' : 'Yopiq',
                tone: company.isAvailable ? PillTone.success : PillTone.neutral,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            company.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.callout.copyWith(
              color: c.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.star_rounded, size: 13, color: c.star),
              const SizedBox(width: 2),
              Text(
                '${company.rating}',
                style: AppTypography.caption.copyWith(color: c.textSecondary),
              ),
              const SizedBox(width: AppDimensions.space6),
              Icon(Icons.route_rounded, size: 12, color: c.textTertiary),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  AppFormatters.distance(company.distanceKm),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          ),
          if (company.tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: AppPill(label: company.tags.first, tone: PillTone.primary, dense: true),
            ),
          ],
          const Spacer(),
          Text(
            AppFormatters.currency(company.productPrice),
            style: AppTypography.priceSmall.copyWith(color: c.primary),
          ),
        ],
      ),
    );
  }
}

class _RecentOrderRow extends StatelessWidget {
  const _RecentOrderRow({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.space12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: c.tint(c.primary, 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(order.status.icon, color: c.primary, size: 20),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.callout.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.companyName} · ${AppFormatters.relativeDate(order.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: c.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.space8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppFormatters.currency(order.total),
                style: AppTypography.priceSmall.copyWith(color: c.textPrimary),
              ),
              const SizedBox(height: 4),
              OrderStatusBadge(status: order.status, dense: true),
            ],
          ),
        ],
      ),
    );
  }
}
