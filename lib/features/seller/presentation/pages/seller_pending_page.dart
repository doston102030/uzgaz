import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_pills.dart';
import '../providers/seller_provider.dart';

/// Shown in place of the seller shell while an application is
/// [SellerStatus.pending] / [SellerStatus.rejected] / [SellerStatus.suspended].
/// Admins decide in the web panel, so while this page is open it asks
/// Supabase every few seconds; the moment the company is approved the
/// reactive state flips the router's gate and the real dashboard appears.
class SellerPendingPage extends ConsumerStatefulWidget {
  const SellerPendingPage({super.key});

  @override
  ConsumerState<SellerPendingPage> createState() => _SellerPendingPageState();
}

class _SellerPendingPageState extends ConsumerState<SellerPendingPage> {
  static const _pollEvery = Duration(seconds: 10);

  Timer? _poll;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(_pollEvery, (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() =>
      ref.read(sellerProfilesProvider.notifier).refresh();

  Future<void> _checkNow() async {
    setState(() => _checking = true);
    await _refresh();
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final seller = ref.watch(currentSellerProvider);

    // The moment an admin approves this company (even from another shell
    // in the same session) the state flips and this page hands off to the
    // real dashboard on its own — no manual refresh needed.
    ref.listen(currentSellerProvider, (previous, next) {
      if (next?.status == SellerStatus.approved && previous?.status != SellerStatus.approved) {
        if (context.mounted) context.go('/seller/dashboard');
      }
    });

    if (seller == null) {
      return Scaffold(
        body: SafeArea(
          child: EmptyState(
            icon: Icons.storefront_outlined,
            title: 'Sotuvchi profili topilmadi',
            actionLabel: 'Ro‘yxatdan o‘tish',
            onAction: () => context.go('/seller/start'),
          ),
        ),
      );
    }

    final (title, subtitle, icon) = switch (seller.status) {
      SellerStatus.pending => (
          'Arizangiz ko‘rib chiqilmoqda',
          '${seller.companyName} arizasi admin tomonidan tekshirilmoqda. '
              'Tasdiqlangach sizga bildirishnoma keladi.',
          Icons.hourglass_top_rounded,
        ),
      SellerStatus.rejected => (
          'Ariza rad etildi',
          seller.rejectionReason ?? 'Ma’lumotlarni tekshirib, qaytadan yuboring.',
          Icons.cancel_rounded,
        ),
      SellerStatus.suspended => (
          'Firma vaqtincha to‘xtatilgan',
          'Savollar bo‘lsa qo‘llab-quvvatlash xizmatiga murojaat qiling.',
          Icons.pause_circle_rounded,
        ),
      SellerStatus.approved => ('Tasdiqlangan', '', Icons.verified_rounded),
    };

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              EmptyState(
                icon: icon,
                tone: seller.status.tone == PillTone.danger
                    ? c.danger
                    : (seller.status.tone == PillTone.neutral ? c.textTertiary : c.warning),
                title: title,
                subtitle: subtitle,
              ),
              const SizedBox(height: AppDimensions.space20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            seller.companyName,
                            style: AppTypography.headline.copyWith(color: c.textPrimary),
                          ),
                        ),
                        AppPill(label: seller.status.labelUz, tone: seller.status.tone, dense: true),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [seller.district, seller.address]
                          .where((part) => part.isNotEmpty)
                          .join(', '),
                      style: AppTypography.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              if (seller.status == SellerStatus.pending)
                AppButton(
                  label: 'Holatni tekshirish',
                  icon: Icons.sync_rounded,
                  isLoading: _checking,
                  onPressed: _checkNow,
                ),
              if (seller.status == SellerStatus.rejected)
                AppButton(
                  label: 'Qaytadan yuborish',
                  icon: Icons.refresh_rounded,
                  onPressed: () => context.push('/seller/register'),
                ),
              const SizedBox(height: AppDimensions.space10),
              AppButton(
                label: 'Bosh sahifaga qaytish',
                variant: AppButtonVariant.outline,
                onPressed: () => context.go('/home'),
              ),
              const SizedBox(height: AppDimensions.space20),
            ],
          ),
        ),
      ),
    );
  }
}
