import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/app_tappable.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/admin_provider.dart';

class AdminSettingsPage extends ConsumerWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final commission = ref.watch(commissionRateProvider);
    final promoActive = ref.watch(promoBannerActiveProvider);
    final user = ref.watch(authProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const AppSliverNavBar(title: 'Sozlamalar', showBack: false),
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
                  Text(
                    'MARKETPLACE',
                    style: AppTypography.overline.copyWith(color: c.textTertiary),
                  ),
                  const SizedBox(height: AppDimensions.space10),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.percent_rounded, size: 19, color: c.primary),
                            const SizedBox(width: AppDimensions.space10),
                            Expanded(
                              child: Text(
                                'Komissiya stavkasi',
                                style: AppTypography.callout.copyWith(
                                  color: c.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${commission.toStringAsFixed(0)}%',
                              style: AppTypography.priceSmall.copyWith(color: c.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.space4),
                        Text(
                          'Har bir yopilgan buyurtmadan ushlab qolinadigan foiz',
                          style: AppTypography.caption.copyWith(color: c.textTertiary),
                        ),
                        Slider(
                          value: commission,
                          min: 0,
                          max: 20,
                          divisions: 20,
                          label: '${commission.toStringAsFixed(0)}%',
                          activeColor: c.primary,
                          onChanged: (v) => ref.read(commissionRateProvider.notifier).state = v,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  AppCard(
                    child: Row(
                      children: [
                        const Icon(Icons.campaign_rounded, size: 19, color: AppColors.energyRose),
                        const SizedBox(width: AppDimensions.space10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aholi uchun reklama banneri',
                                style: AppTypography.callout.copyWith(
                                  color: c.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Bosh sahifadagi "Suyultirilgan gaz" bannerini yoqish',
                                style: AppTypography.caption.copyWith(color: c.textTertiary),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: promoActive,
                          onChanged: (v) => ref.read(promoBannerActiveProvider.notifier).state = v,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space24),
                  Text(
                    'HISOB',
                    style: AppTypography.overline.copyWith(color: c.textTertiary),
                  ),
                  const SizedBox(height: AppDimensions.space10),
                  AppGroupedList(
                    children: [
                      _Row(
                        icon: Icons.person_rounded,
                        title: user?.fullName ?? 'Administrator',
                        subtitle: user?.phone,
                      ),
                      _Row(
                        icon: Icons.logout_rounded,
                        title: 'Chiqish',
                        danger: true,
                        onTap: () async {
                          final confirmed = await CustomDialog.confirm(
                            context,
                            title: 'Hisobdan chiqish',
                            message: 'Admin panelidan chiqmoqchimisiz?',
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
  const _Row({required this.icon, required this.title, this.subtitle, this.onTap, this.danger = false});

  final IconData icon;
  final String title;
  final String? subtitle;
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
          vertical: AppDimensions.space12,
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: danger ? c.danger : c.textSecondary),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.callout.copyWith(
                      color: danger ? c.danger : c.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppTypography.caption.copyWith(color: c.textTertiary),
                    ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded, size: 20, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}
