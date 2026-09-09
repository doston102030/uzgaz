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
import '../../../../core/widgets/app_tappable.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/company_card.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../../core/widgets/order_status_widget.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../core/widgets/service_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../checkout/presentation/providers/checkout_provider.dart';
import '../../../companies/domain/entities/company.dart';
import '../../../companies/presentation/providers/company_provider.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/presentation/providers/order_provider.dart';
import '../../../admin/presentation/providers/admin_provider.dart';
import '../../../products/presentation/providers/product_provider.dart';

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
      body: RefreshIndicator(
        color: context.palette.primary,
        backgroundColor: context.palette.surface,
        onRefresh: () => Future<void>.delayed(const Duration(milliseconds: 700)),
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _HomeHeader()),
            if (activeOrder != null)
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -26),
                  child: Padding(
                    padding: AppDimensions.pagePadding,
                    child: _LiveOrderCard(order: activeOrder),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: activeOrder != null ? 0 : AppDimensions.space20),
                child: const _CategoryRail(),
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
                  child: HighlightServiceCard(
                    onTap: () => context.push('/services'),
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
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppDimensions.space12,
                  crossAxisSpacing: AppDimensions.space12,
                  childAspectRatio: 0.60,
                ),
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
    );
  }
}

/// Gradient hero: location, alerts, greeting and search. Everything a
/// returning buyer needs before scrolling.
class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final cartCount = ref.watch(cartCountProvider);
    final topPad = MediaQuery.paddingOf(context).top;
    final c = context.palette;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.gutter,
        topPad + AppDimensions.space12,
        AppDimensions.gutter,
        AppDimensions.space40,
      ),
      decoration: BoxDecoration(
        gradient: c.brandGradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppDimensions.radiusSheet),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: c.isDark ? 0.28 : 0.24),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppTappable(
                  onTap: () => context.go('/map'),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded,
                            color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: AppDimensions.space8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Yetkazish manzili',
                              style: AppTypography.caption2.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Toshkent, Yunusobod',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.callout.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.expand_more_rounded,
                                    color: Colors.white, size: 17),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppIconButton(
                icon: Icons.notifications_none_rounded,
                background: Colors.white.withValues(alpha: 0.18),
                foreground: Colors.white,
                bordered: false,
                showDot: true,
                onTap: () => CustomDialog.info(
                  context,
                  title: 'Bildirishnomalar',
                  message:
                      'Yangi bildirishnomalar bu yerda ko‘rinadi. Buyurtma holati '
                      'o‘zgarganda sizga darhol xabar beramiz.',
                  icon: Icons.notifications_active_rounded,
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              AppIconButton(
                icon: Icons.shopping_bag_outlined,
                background: Colors.white.withValues(alpha: 0.18),
                foreground: Colors.white,
                bordered: false,
                badgeCount: cartCount,
                onTap: () => context.push('/cart'),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),
          Text(
            user == null
                ? 'Assalomu alaykum 👋'
                : 'Assalomu alaykum, ${user.fullName.split(' ').first} 👋',
            style: AppTypography.title2.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 3),
          Text(
            'Bugun qanday energiya kerak?',
            style: AppTypography.callout.copyWith(
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: AppDimensions.space16),
          AppSearchField(
            hint: 'Mahsulot yoki kompaniya qidirish',
            readOnly: true,
            onTap: () => context.go('/catalog'),
            trailing: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: c.brandGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune_rounded, color: Colors.white, size: 17),
            ),
          ),
        ],
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
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: AppDimensions.pagePadding,
            itemCount: ServiceCategory.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppDimensions.space10),
            itemBuilder: (context, i) {
              final category = ServiceCategory.values[i];
              return ServiceTile(
                label: category.titleUz,
                icon: category.icon,
                color: category.color,
                onTap: () {
                  if (category == ServiceCategory.elektrQuvvatlash) {
                    context.push('/services');
                    return;
                  }
                  ref.read(categoryFilterProvider.notifier).state = category;
                  context.go('/catalog');
                },
              );
            },
          ),
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
