import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../../core/widgets/dashboard_widgets.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/product_illustration.dart';
import '../../../../core/widgets/status_pills.dart';
import '../../../seller/domain/entities/seller_product.dart';
import '../../../seller/presentation/providers/seller_provider.dart';

enum _ProductTab { moderatsiyada, faol, radEtilgan }

class AdminProductsPage extends ConsumerStatefulWidget {
  const AdminProductsPage({super.key});

  @override
  ConsumerState<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends ConsumerState<AdminProductsPage> {
  _ProductTab _tab = _ProductTab.moderatsiyada;

  Future<void> _reject(SellerProduct product) async {
    final controller = TextEditingController();
    final reason = await AppSheet.show<String>(
      context,
      title: 'Rad etish sababi',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: controller,
              label: 'Sabab',
              hint: 'Masalan: rasm yoki tavsif noaniq',
              maxLines: 2,
              autofocus: true,
            ),
            const SizedBox(height: AppDimensions.space16),
            AppButton(
              label: 'Rad etish',
              variant: AppButtonVariant.danger,
              onPressed: () => Navigator.of(context).pop(
                controller.text.trim().isEmpty ? 'Talablarga javob bermaydi' : controller.text.trim(),
              ),
            ),
          ],
        ),
      ),
    );
    if (reason != null) {
      ref.read(sellerProductsProvider.notifier).reject(product.id, reason: reason);
      if (mounted) AppToast.show(context, '${product.name} rad etildi', tone: ToastTone.warning);
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(sellerProductsProvider);
    final sellers = ref.watch(sellerProfilesProvider);
    String sellerName(String id) =>
        sellers.where((s) => s.id == id).map((s) => s.companyName).firstOrNull ?? 'Noma’lum sotuvchi';

    final pending = all.where((p) => p.moderationStatus == ProductModerationStatus.pending).toList();
    final live = all.where((p) => p.moderationStatus == ProductModerationStatus.approved).toList();
    final rejected = all.where((p) => p.moderationStatus == ProductModerationStatus.rejected).toList();

    final list = switch (_tab) {
      _ProductTab.moderatsiyada => pending,
      _ProductTab.faol => live,
      _ProductTab.radEtilgan => rejected,
    };

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverNavBar(
            title: 'Mahsulotlar',
            subtitle: '${all.length} ta jami',
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
              child: AppSegmentedControl<_ProductTab>(
                value: _tab,
                segments: {
                  _ProductTab.moderatsiyada: 'Moderatsiya (${pending.length})',
                  _ProductTab.faol: 'Faol (${live.length})',
                  _ProductTab.radEtilgan: 'Rad etilgan',
                },
                onChanged: (t) => setState(() => _tab = t),
              ),
            ),
          ),
          if (list.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(icon: Icons.inventory_2_outlined, title: 'Ro‘yxat bo‘sh'),
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
                  final product = list[i];
                  final visual = EnergyVisualX.fromCategory(product.category.id, name: product.name);
                  if (product.moderationStatus == ProductModerationStatus.pending) {
                    return ApprovalRow(
                      leading: EnergyAvatar(visual: visual, size: 44),
                      title: product.name,
                      subtitle: '${sellerName(product.sellerId)} · ${AppFormatters.currency(product.price)}',
                      meta: '${product.category.titleUz} · Ombor: ${product.stockQty} ta',
                      onApprove: () {
                        ref.read(sellerProductsProvider.notifier).approve(product.id);
                        AppToast.show(context, '${product.name} tasdiqlandi', tone: ToastTone.success);
                      },
                      onReject: () => _reject(product),
                    );
                  }
                  return AppCard(
                    padding: const EdgeInsets.all(AppDimensions.space14),
                    child: Row(
                      children: [
                        EnergyAvatar(visual: visual, size: 44),
                        const SizedBox(width: AppDimensions.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.callout.copyWith(
                                  color: context.palette.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                sellerName(product.sellerId),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption
                                    .copyWith(color: context.palette.textTertiary),
                              ),
                              if (product.moderationStatus == ProductModerationStatus.rejected &&
                                  product.rejectionReason != null)
                                Text(
                                  product.rejectionReason!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption2
                                      .copyWith(color: context.palette.danger),
                                ),
                            ],
                          ),
                        ),
                        AppPill(
                          label: product.moderationStatus.labelUz,
                          tone: product.moderationStatus.tone,
                          dense: true,
                        ),
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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
