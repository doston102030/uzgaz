import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/app_tappable.dart';
import '../../../../core/widgets/company_card.dart';
import '../../../../core/widgets/dashboard_widgets.dart';
import '../../../../core/widgets/status_pills.dart';
import '../providers/seller_provider.dart';

class SellerDashboardPage extends ConsumerWidget {
  const SellerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final seller = ref.watch(currentSellerProvider);
    final stats = ref.watch(sellerStatsProvider);
    final newOrders = ref.watch(newSellerOrdersProvider);
    final pendingProducts = ref
        .watch(currentSellerProductsProvider)
        .where((p) => p.moderationStatus == ProductModerationStatus.pending)
        .length;

    if (seller == null) return const SizedBox.shrink();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimensions.gutter,
                MediaQuery.paddingOf(context).top + AppDimensions.space12,
                AppDimensions.gutter,
                0,
              ),
              child: Row(
                children: [
                  CompanyLogo(name: seller.companyName, size: 46),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seller.companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.title3.copyWith(color: c.textPrimary),
                        ),
                        Row(
                          children: [
                            Icon(Icons.star_rounded, size: 13, color: c.star),
                            const SizedBox(width: 2),
                            Text(
                              '${seller.rating} (${seller.reviewCount})',
                              style: AppTypography.caption.copyWith(color: c.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppPill(label: seller.status.labelUz, tone: seller.status.tone, dense: true),
                ],
              ),
            ),
          ),
          if (newOrders.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.gutter,
                  AppDimensions.space16,
                  AppDimensions.gutter,
                  0,
                ),
                child: AppTappable(
                  onTap: () => context.go('/seller/orders'),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.space14),
                    decoration: BoxDecoration(
                      color: c.infoSoft,
                      borderRadius: AppDimensions.brMedium,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_active_rounded, color: c.info, size: 20),
                        const SizedBox(width: AppDimensions.space10),
                        Expanded(
                          child: Text(
                            '${newOrders.length} ta yangi buyurtma kutmoqda',
                            style: AppTypography.callout.copyWith(
                              color: c.info,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: c.info, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.gutter,
                AppDimensions.space20,
                AppDimensions.gutter,
                0,
              ),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppDimensions.space12,
                crossAxisSpacing: AppDimensions.space12,
                childAspectRatio: 1.5,
                children: [
                  StatCard(
                    icon: Icons.payments_rounded,
                    label: 'Bugungi daromad',
                    value: AppFormatters.currencyCompact(stats.todayRevenue),
                    tone: c.success,
                  ),
                  StatCard(
                    icon: Icons.receipt_long_rounded,
                    label: 'Bugungi buyurtmalar',
                    value: '${stats.todayOrders}',
                    tone: c.primary,
                  ),
                  StatCard(
                    icon: Icons.inventory_2_rounded,
                    label: 'Faol mahsulotlar',
                    value: '${stats.activeProducts}',
                    tone: AppColors.energyAmber,
                  ),
                  StatCard(
                    icon: Icons.shopping_bag_rounded,
                    label: 'O‘rtacha chek',
                    value: AppFormatters.currencyCompact(stats.avgOrderValue),
                    tone: AppColors.energyElectric,
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Tezkor amallar',
              padding: EdgeInsets.fromLTRB(
                AppDimensions.gutter,
                AppDimensions.space24,
                AppDimensions.gutter,
                AppDimensions.space12,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: AppDimensions.pagePadding,
              child: Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.add_circle_rounded,
                      label: 'Mahsulot qo‘shish',
                      color: c.primary,
                      onTap: () => context.push('/seller/products/add'),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.receipt_long_rounded,
                      label: 'Buyurtmalar',
                      color: AppColors.energyAmber,
                      badge: newOrders.isEmpty ? null : newOrders.length,
                      onTap: () => context.go('/seller/orders'),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.bar_chart_rounded,
                      label: 'Hisobot',
                      color: c.success,
                      onTap: () => context.go('/seller/reports'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (pendingProducts > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.gutter,
                  AppDimensions.space20,
                  AppDimensions.gutter,
                  0,
                ),
                child: AppTappable(
                  onTap: () => context.go('/seller/products'),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.space14),
                    decoration: BoxDecoration(
                      color: c.warningSoft,
                      borderRadius: AppDimensions.brMedium,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.hourglass_top_rounded, color: c.warning, size: 20),
                        const SizedBox(width: AppDimensions.space10),
                        Expanded(
                          child: Text(
                            '$pendingProducts ta mahsulot moderatsiyada',
                            style: AppTypography.callout.copyWith(
                              color: c.warning,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: c.warning, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Haftalik savdo',
              padding: EdgeInsets.fromLTRB(
                AppDimensions.gutter,
                AppDimensions.space24,
                AppDimensions.gutter,
                AppDimensions.space12,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: AppDimensions.pagePadding,
              child: AppCard(
                child: SimpleBarChart(points: _weeklyRevenue(ref)),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppDimensions.bottomBarClearance),
          ),
        ],
      ),
    );
  }

  List<ChartPoint> _weeklyRevenue(WidgetRef ref) {
    final orders = ref.read(currentSellerOrdersProvider);
    const days = ['Du', 'Se', 'Cho', 'Pa', 'Ju', 'Sha', 'Ya'];
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final revenue = orders
          .where((o) =>
              o.placedAt.year == day.year &&
              o.placedAt.month == day.month &&
              o.placedAt.day == day.day)
          .fold(0, (sum, o) => sum + o.total);
      return ChartPoint(days[day.weekday - 1], revenue);
    });
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppTappable(
      onTap: onTap,
      pressedScale: 0.95,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.space16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppDimensions.brLarge,
          border: Border.all(color: c.border),
          boxShadow: c.shadowSm,
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: c.tint(color, 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                if (badge != null)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: c.danger,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.surface, width: 2),
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        '$badge',
                        textAlign: TextAlign.center,
                        style: AppTypography.caption2.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: AppTypography.caption.copyWith(
                color: c.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
