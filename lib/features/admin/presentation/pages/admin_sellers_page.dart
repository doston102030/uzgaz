import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/company_card.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../../core/widgets/dashboard_widgets.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_pills.dart';
import '../../../seller/domain/entities/seller_profile.dart';
import '../../../seller/presentation/providers/seller_provider.dart';

enum _SellerTab { kutilayotgan, faol, boshqa }

class AdminSellersPage extends ConsumerStatefulWidget {
  const AdminSellersPage({super.key});

  @override
  ConsumerState<AdminSellersPage> createState() => _AdminSellersPageState();
}

class _AdminSellersPageState extends ConsumerState<AdminSellersPage> {
  _SellerTab _tab = _SellerTab.kutilayotgan;

  Future<void> _reject(SellerProfile seller) async {
    final controller = TextEditingController();
    final reason = await AppSheet.show<String>(
      context,
      title: 'Radi etish sababi',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: controller,
              label: 'Sabab',
              hint: 'Masalan: hujjatlar to‘liq emas',
              maxLines: 2,
              autofocus: true,
            ),
            const SizedBox(height: AppDimensions.space16),
            AppButton(
              label: 'Rad etish',
              variant: AppButtonVariant.danger,
              onPressed: () => Navigator.of(context).pop(
                controller.text.trim().isEmpty ? 'Ma’lumotlar yetarli emas' : controller.text.trim(),
              ),
            ),
          ],
        ),
      ),
    );
    if (reason != null) {
      ref.read(sellerProfilesProvider.notifier).reject(seller.id, reason: reason);
      if (mounted) AppToast.show(context, '${seller.companyName} rad etildi', tone: ToastTone.warning);
    }
  }

  void _approve(SellerProfile seller) {
    ref.read(sellerProfilesProvider.notifier).approve(seller.id);
    AppToast.show(context, '${seller.companyName} tasdiqlandi', tone: ToastTone.success);
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(sellerProfilesProvider);
    final pending = all.where((s) => s.status == SellerStatus.pending).toList();
    final active = all.where((s) => s.status == SellerStatus.approved).toList();
    final other = all
        .where((s) => s.status == SellerStatus.rejected || s.status == SellerStatus.suspended)
        .toList();

    final list = switch (_tab) {
      _SellerTab.kutilayotgan => pending,
      _SellerTab.faol => active,
      _SellerTab.boshqa => other,
    };

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverNavBar(
            title: 'Sotuvchilar',
            subtitle: '${all.length} ta firma',
            showBack: false,
          ),
          SliverPinnedBar(
            height: 58,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.gutter,
                0,
                AppDimensions.gutter,
                AppDimensions.space12,
              ),
              child: AppSegmentedControl<_SellerTab>(
                value: _tab,
                segments: {
                  _SellerTab.kutilayotgan: 'Kutilmoqda (${pending.length})',
                  _SellerTab.faol: 'Faol (${active.length})',
                  _SellerTab.boshqa: 'Boshqa',
                },
                onChanged: (t) => setState(() => _tab = t),
              ),
            ),
          ),
          if (list.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.storefront_outlined,
                title: 'Ro‘yxat bo‘sh',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.gutter,
                AppDimensions.space4,
                AppDimensions.gutter,
                AppDimensions.bottomBarClearance,
              ),
              sliver: SliverList.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.space12),
                itemBuilder: (context, i) {
                  final seller = list[i];
                  if (seller.status == SellerStatus.pending) {
                    return ApprovalRow(
                      leading: CompanyLogo(name: seller.companyName, size: 44),
                      title: seller.companyName,
                      subtitle: '${seller.category.titleUz} · ${seller.address}',
                      meta: seller.phone,
                      onApprove: () => _approve(seller),
                      onReject: () => _reject(seller),
                    );
                  }
                  return _SellerRow(
                    seller: seller,
                    onSuspend: seller.status == SellerStatus.approved
                        ? () {
                            ref.read(sellerProfilesProvider.notifier).suspend(seller.id);
                            AppToast.show(context, '${seller.companyName} to‘xtatildi',
                                tone: ToastTone.warning);
                          }
                        : null,
                    onReactivate: seller.status == SellerStatus.suspended
                        ? () {
                            ref.read(sellerProfilesProvider.notifier).reactivate(seller.id);
                            AppToast.show(context, '${seller.companyName} qayta faollashtirildi',
                                tone: ToastTone.success);
                          }
                        : null,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SellerRow extends StatelessWidget {
  const _SellerRow({required this.seller, this.onSuspend, this.onReactivate});

  final SellerProfile seller;
  final VoidCallback? onSuspend;
  final VoidCallback? onReactivate;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.space14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CompanyLogo(name: seller.companyName, size: 44),
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
              AppPill(label: seller.status.labelUz, tone: seller.status.tone, dense: true),
            ],
          ),
          if (seller.status == SellerStatus.rejected && seller.rejectionReason != null) ...[
            const SizedBox(height: AppDimensions.space10),
            Text(
              seller.rejectionReason!,
              style: AppTypography.caption.copyWith(color: c.danger),
            ),
          ],
          if (onSuspend != null || onReactivate != null) ...[
            const SizedBox(height: AppDimensions.space12),
            AppButton(
              label: onSuspend != null ? 'To‘xtatish' : 'Qayta faollashtirish',
              variant: onSuspend != null ? AppButtonVariant.outline : AppButtonVariant.primary,
              size: AppButtonSize.small,
              onPressed: onSuspend ?? onReactivate,
            ),
          ],
        ],
      ),
    );
  }
}
