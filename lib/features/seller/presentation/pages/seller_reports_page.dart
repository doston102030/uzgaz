import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/dashboard_widgets.dart';
import '../../../orders/domain/entities/order.dart';
import '../../domain/entities/seller_order.dart';
import '../providers/seller_provider.dart';

class SellerReportsPage extends ConsumerWidget {
  const SellerReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final stats = ref.watch(sellerStatsProvider);
    final orders = ref.watch(currentSellerOrdersProvider);

    final topProducts = _topProducts(orders);
    final weekPoints = _weeklyRevenue(orders);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const AppSliverNavBar(
            title: 'Hisobot',
            subtitle: 'Savdo va daromad statistikasi',
            showBack: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.gutter,
              AppDimensions.space12,
              AppDimensions.gutter,
              AppDimensions.bottomBarClearance,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppDimensions.space12,
                    crossAxisSpacing: AppDimensions.space12,
                    childAspectRatio: 1.5,
                    children: [
                      StatCard(
                        icon: Icons.calendar_today_rounded,
                        label: 'Haftalik daromad',
                        value: AppFormatters.currencyCompact(stats.weekRevenue),
                        tone: c.primary,
                      ),
                      StatCard(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Umumiy daromad',
                        value: AppFormatters.currencyCompact(stats.totalRevenue),
                        tone: c.success,
                      ),
                      StatCard(
                        icon: Icons.receipt_long_rounded,
                        label: 'Jami buyurtmalar',
                        value: '${stats.totalOrders}',
                        tone: AppColors.energyElectric,
                      ),
                      StatCard(
                        icon: Icons.shopping_bag_rounded,
                        label: 'O‘rtacha chek',
                        value: AppFormatters.currencyCompact(stats.avgOrderValue),
                        tone: AppColors.energyAmber,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space24),
                  Text(
                    'So‘nggi 7 kunlik savdo',
                    style: AppTypography.title3.copyWith(color: c.textPrimary),
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  AppCard(child: SimpleBarChart(points: weekPoints)),
                  const SizedBox(height: AppDimensions.space24),
                  Text(
                    'Eng ko‘p sotilgan mahsulotlar',
                    style: AppTypography.title3.copyWith(color: c.textPrimary),
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  if (topProducts.isEmpty)
                    AppCard(
                      child: Text(
                        'Hali sotuvlar mavjud emas.',
                        style: AppTypography.callout.copyWith(color: c.textSecondary),
                      ),
                    )
                  else
                    AppCard(
                      padding: EdgeInsets.zero,
                      clip: true,
                      child: Column(
                        children: [
                          for (int i = 0; i < topProducts.length; i++) ...[
                            _TopProductRow(rank: i + 1, entry: topProducts[i]),
                            if (i != topProducts.length - 1)
                              Divider(height: 1, color: c.separator),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_ProductStat> _topProducts(List<SellerOrder> orders) {
    final map = <String, _ProductStat>{};
    for (final order in orders) {
      for (final OrderItem item in order.items) {
        final existing = map[item.productName];
        if (existing == null) {
          map[item.productName] = _ProductStat(item.productName, item.quantity, item.subtotal);
        } else {
          map[item.productName] = _ProductStat(
            item.productName,
            existing.quantity + item.quantity,
            existing.revenue + item.subtotal,
          );
        }
      }
    }
    final list = map.values.toList()..sort((a, b) => b.revenue.compareTo(a.revenue));
    return list.take(5).toList();
  }

  List<ChartPoint> _weeklyRevenue(List<SellerOrder> orders) {
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

class _ProductStat {
  const _ProductStat(this.name, this.quantity, this.revenue);
  final String name;
  final int quantity;
  final int revenue;
}

class _TopProductRow extends StatelessWidget {
  const _TopProductRow({required this.rank, required this.entry});

  final int rank;
  final _ProductStat entry;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space14,
        vertical: AppDimensions.space12,
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank == 1 ? c.primarySoft : c.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: AppTypography.caption.copyWith(
                color: rank == 1 ? c.primary : c.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.callout.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${entry.quantity} dona sotildi',
                  style: AppTypography.caption.copyWith(color: c.textTertiary),
                ),
              ],
            ),
          ),
          Text(
            AppFormatters.currency(entry.revenue),
            style: AppTypography.priceSmall.copyWith(color: c.primary),
          ),
        ],
      ),
    );
  }
}
