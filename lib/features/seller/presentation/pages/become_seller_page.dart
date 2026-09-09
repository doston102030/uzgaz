import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/status_pills.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/seller_provider.dart';

/// Entry point behind "Men sotuvchiman" — pitches the marketplace, and
/// if this account already owns a company (an earlier application, or
/// the pre-seeded demo company), offers to jump straight into it instead
/// of filling the form again.
class BecomeSellerPage extends ConsumerWidget {
  const BecomeSellerPage({super.key});

  static const _benefits = [
    (Icons.storefront_rounded, 'O‘z do‘koningizni oching',
        'Mahsulotlaringizni minglab xaridorlarga ko‘rsating'),
    (Icons.receipt_long_rounded, 'Buyurtmalarni boshqaring',
        'Yangi buyurtmalar sizga darhol bildirishnoma bilan keladi'),
    (Icons.bar_chart_rounded, 'Hisobotlarni kuzating',
        'Kunlik savdo, daromad va eng ko‘p sotilgan mahsulotlar'),
    (Icons.verified_rounded, 'Ishonchli va xavfsiz',
        'Har bir firma va mahsulot admin tomonidan tekshiriladi'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final user = ref.watch(authProvider);
    final profiles = ref.watch(sellerProfilesProvider);
    final existing = user == null
        ? null
        : profiles.where((p) => p.ownerUserId == user.id).firstOrNull;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const AppSliverNavBar(title: 'Sotuvchi bo‘lish', largeTitle: false),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.gutter,
              AppDimensions.space12,
              AppDimensions.gutter,
              AppDimensions.space40,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space20),
                    decoration: BoxDecoration(
                      gradient: c.brandGradient,
                      borderRadius: AppDimensions.brXLarge,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.26),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gaz & Energiya marketpleysida soting',
                                style: AppTypography.title3.copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Firmangizni ro‘yxatdan o‘tkazing va bugunoq '
                                'birinchi buyurtmangizni qabul qiling.',
                                style: AppTypography.callout.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.storefront_rounded,
                              color: Colors.white, size: 26),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space24),

                  if (existing != null) ...[
                    AppCard(
                      selected: existing.status == SellerStatus.approved,
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: c.tint(existing.status.tone == PillTone.success
                                  ? c.success
                                  : c.warning),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(existing.status.icon,
                                color: existing.status.tone == PillTone.success
                                    ? c.success
                                    : c.warning),
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  existing.companyName,
                                  style: AppTypography.headline.copyWith(color: c.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                AppPill(label: existing.status.labelUz, tone: existing.status.tone, dense: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    if (existing.status == SellerStatus.approved)
                      AppButton(
                        label: 'Sotuvchi kabinetiga kirish',
                        icon: Icons.login_rounded,
                        onPressed: () {
                          ref.read(authProvider.notifier).linkSeller(existing.id);
                          context.go('/seller/dashboard');
                        },
                      )
                    else if (existing.status == SellerStatus.pending)
                      AppButton(
                        label: 'Ariza holatini ko‘rish',
                        icon: Icons.hourglass_top_rounded,
                        variant: AppButtonVariant.secondary,
                        onPressed: () {
                          ref.read(authProvider.notifier).linkSeller(existing.id);
                          context.push('/seller/pending');
                        },
                      )
                    else if (existing.status == SellerStatus.rejected)
                      AppButton(
                        label: 'Qaytadan yuborish',
                        icon: Icons.refresh_rounded,
                        variant: AppButtonVariant.secondary,
                        onPressed: () => context.push('/seller/register'),
                      ),
                    const SizedBox(height: AppDimensions.space28),
                  ],

                  Text(
                    'Nima uchun biz bilan ishlashingiz kerak',
                    style: AppTypography.title3.copyWith(color: c.textPrimary),
                  ),
                  const SizedBox(height: AppDimensions.space14),
                  for (final benefit in _benefits) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: c.primarySoft,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(benefit.$1, size: 19, color: c.primary),
                        ),
                        const SizedBox(width: AppDimensions.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                benefit.$2,
                                style: AppTypography.callout.copyWith(
                                  color: c.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                benefit.$3,
                                style: AppTypography.caption.copyWith(color: c.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space20),
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
              label: existing == null ? 'Firmani ro‘yxatdan o‘tkazish' : 'Yangi firma qo‘shish',
              icon: Icons.add_business_rounded,
              variant: existing == null ? AppButtonVariant.primary : AppButtonVariant.outline,
              onPressed: () => context.push('/seller/register'),
            ),
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
