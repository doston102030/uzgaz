import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/app_tappable.dart';
import '../../../../core/widgets/dashboard_widgets.dart';
import '../../../seller/presentation/providers/seller_provider.dart';
import '../providers/admin_provider.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final stats = ref.watch(adminStatsProvider);
    final pendingSellers = ref.watch(pendingSellersProvider);
    final pendingProducts = ref.watch(pendingProductsProvider);

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
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: c.brandGradient,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.shield_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Boshqaruv paneli',
                          style: AppTypography.title3.copyWith(color: c.textPrimary),
                        ),
                        Text(
                          'Marketplace umumiy holati',
                          style: AppTypography.caption.copyWith(color: c.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ],
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
                    icon: Icons.storefront_rounded,
                    label: 'Sotuvchilar',
                    value: '${stats.totalSellers}',
                    tone: c.primary,
                    onTap: () => context.go('/admin/sellers'),
                  ),
                  StatCard(
                    icon: Icons.inventory_2_rounded,
                    label: 'Mahsulotlar',
                    value: '${stats.totalProducts}',
                    tone: AppColors.energyAmber,
                    onTap: () => context.go('/admin/products'),
                  ),
                  StatCard(
                    icon: Icons.receipt_long_rounded,
                    label: 'Buyurtmalar',
                    value: '${stats.totalOrders}',
                    tone: AppColors.energyElectric,
                    onTap: () => context.go('/admin/orders'),
                  ),
                  StatCard(
                    icon: Icons.percent_rounded,
                    label: 'Komissiya daromadi',
                    value: AppFormatters.currencyCompact(stats.commissionEarned),
                    tone: c.success,
                  ),
                ],
              ),
            ),
          ),
          if (pendingSellers.isNotEmpty || pendingProducts.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.gutter,
                  AppDimensions.space24,
                  AppDimensions.gutter,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tasdiqlash kutmoqda',
                      style: AppTypography.title3.copyWith(color: c.textPrimary),
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    if (pendingSellers.isNotEmpty)
                      _PendingBanner(
                        icon: Icons.storefront_rounded,
                        tone: c.warning,
                        label: '${pendingSellers.length} ta yangi sotuvchi arizasi',
                        onTap: () => context.go('/admin/sellers'),
                      ),
                    if (pendingSellers.isNotEmpty && pendingProducts.isNotEmpty)
                      const SizedBox(height: AppDimensions.space10),
                    if (pendingProducts.isNotEmpty)
                      _PendingBanner(
                        icon: Icons.inventory_2_rounded,
                        tone: c.info,
                        label: '${pendingProducts.length} ta mahsulot moderatsiyada',
                        onTap: () => context.go('/admin/products'),
                      ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'So‘nggi sotuvchi arizalari',
              actionLabel: 'Barchasi',
              onAction: () => context.go('/admin/sellers'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.gutter,
              0,
              AppDimensions.gutter,
              AppDimensions.bottomBarClearance,
            ),
            sliver: SliverList.separated(
              itemCount: pendingSellers.length.clamp(0, 3) == 0 ? 1 : pendingSellers.length.clamp(0, 3),
              separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.space10),
              itemBuilder: (context, i) {
                if (pendingSellers.isEmpty) {
                  return AppCard(
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: c.success, size: 20),
                        const SizedBox(width: AppDimensions.space10),
                        Expanded(
                          child: Text(
                            'Hozircha kutayotgan ariza yo‘q',
                            style: AppTypography.callout.copyWith(color: c.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final seller = pendingSellers[i];
                return AppCard(
                  onTap: () => context.go('/admin/sellers'),
                  padding: const EdgeInsets.all(AppDimensions.space14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: c.warningSoft,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(Icons.hourglass_top_rounded, size: 19, color: c.warning),
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              seller.companyName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.callout.copyWith(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              seller.category.titleUz,
                              style: AppTypography.caption.copyWith(color: c.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: c.textTertiary),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner({
    required this.icon,
    required this.tone,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color tone;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppTappable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space14),
        decoration: BoxDecoration(
          color: c.tint(tone, 0.10),
          borderRadius: AppDimensions.brMedium,
        ),
        child: Row(
          children: [
            Icon(icon, color: tone, size: 20),
            const SizedBox(width: AppDimensions.space10),
            Expanded(
              child: Text(
                label,
                style: AppTypography.callout.copyWith(color: tone, fontWeight: FontWeight.w700),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: tone, size: 20),
          ],
        ),
      ),
    );
  }
}
