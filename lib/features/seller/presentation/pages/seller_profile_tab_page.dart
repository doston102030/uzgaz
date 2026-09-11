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
import '../../../../core/widgets/company_card.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/seller_provider.dart';

class SellerProfileTabPage extends ConsumerWidget {
  const SellerProfileTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final seller = ref.watch(currentSellerProvider);
    final user = ref.watch(authProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const AppSliverNavBar(title: 'Profil', showBack: false),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.gutter,
              AppDimensions.space8,
              AppDimensions.gutter,
              AppDimensions.bottomBarClearance,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (seller != null)
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.space16),
                      decoration: BoxDecoration(
                        gradient: c.brandGradient,
                        borderRadius: AppDimensions.brXLarge,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.24),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CompanyLogo(name: seller.companyName, size: 56, logoUrl: seller.logoUrl),
                          const SizedBox(width: AppDimensions.space14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  seller.companyName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.title3.copyWith(color: Colors.white),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  user?.fullName ?? '',
                                  style: AppTypography.callout.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppDimensions.space20),
                  AppGroupedList(
                    header: 'Firma',
                    children: [
                      _Row(
                        icon: Icons.storefront_outlined,
                        tone: c.primary,
                        title: 'Firma ma’lumotlari',
                        value: seller?.category.titleUz,
                        onTap: () => AppToast.show(context, 'Tez orada'),
                      ),
                      _Row(
                        icon: Icons.place_outlined,
                        tone: AppColors.energyRose,
                        title: 'Manzil va ish vaqti',
                        value: seller?.workingHours,
                        onTap: () => AppToast.show(context, 'Tez orada'),
                      ),
                      _Row(
                        icon: Icons.local_shipping_outlined,
                        tone: AppColors.energyElectric,
                        title: 'Yetkazish narxi',
                        value: seller == null ? null : AppFormatters.currency(seller.deliveryFee),
                        onTap: () => AppToast.show(context, 'Tez orada'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space20),
                  AppGroupedList(
                    header: 'Hisob',
                    children: [
                      _Row(
                        icon: Icons.swap_horiz_rounded,
                        tone: AppColors.info,
                        title: 'Xaridor rejimiga qaytish',
                        onTap: () {
                          ref.read(authProvider.notifier).switchToBuyer();
                          context.go('/home');
                        },
                      ),
                      _Row(
                        icon: Icons.help_outline_rounded,
                        tone: c.textSecondary,
                        title: 'Yordam',
                        onTap: () => CustomDialog.info(
                          context,
                          title: 'Sotuvchi yordami',
                          message: 'Savollar bo‘yicha qo‘llab-quvvatlash xizmatiga murojaat qiling.',
                          icon: Icons.support_agent_rounded,
                        ),
                      ),
                      _Row(
                        icon: Icons.logout_rounded,
                        tone: c.danger,
                        title: 'Chiqish',
                        danger: true,
                        onTap: () async {
                          final confirmed = await CustomDialog.confirm(
                            context,
                            title: 'Hisobdan chiqish',
                            message: 'Rostdan ham chiqmoqchimisiz?',
                            confirmLabel: 'Chiqish',
                            destructive: true,
                          );
                          if (confirmed && context.mounted) {
                            ref.read(authProvider.notifier).signOut();
                            context.go('/login');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.tone,
    this.value,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final Color tone;
  final String? value;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppTappable(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space14,
          vertical: AppDimensions.space10,
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: c.tint(tone, 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: tone),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Text(
                title,
                style: AppTypography.callout.copyWith(
                  color: danger ? c.danger : c.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(right: AppDimensions.space6),
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.callout.copyWith(color: c.textTertiary),
                ),
              ),
            Icon(Icons.chevron_right_rounded, size: 20, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}
