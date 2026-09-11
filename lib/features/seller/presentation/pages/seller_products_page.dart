import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cached_network_image/cached_network_image.dart';

import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/app_tappable.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/product_illustration.dart';
import '../../../../core/widgets/status_pills.dart';
import '../../domain/entities/seller_product.dart';
import '../providers/seller_provider.dart';

enum _ProductFilter { barchasi, faol, moderatsiyada, radEtilgan }

class SellerProductsPage extends ConsumerStatefulWidget {
  const SellerProductsPage({super.key});

  @override
  ConsumerState<SellerProductsPage> createState() => _SellerProductsPageState();
}

class _SellerProductsPageState extends ConsumerState<SellerProductsPage> {
  _ProductFilter _filter = _ProductFilter.barchasi;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(currentSellerProductsProvider);

    final products = switch (_filter) {
      _ProductFilter.barchasi => all,
      _ProductFilter.faol =>
        all.where((p) => p.moderationStatus == ProductModerationStatus.approved).toList(),
      _ProductFilter.moderatsiyada =>
        all.where((p) => p.moderationStatus == ProductModerationStatus.pending).toList(),
      _ProductFilter.radEtilgan =>
        all.where((p) => p.moderationStatus == ProductModerationStatus.rejected).toList(),
    };

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverNavBar(
            title: 'Mahsulotlar',
            subtitle: '${all.length} ta mahsulot',
            showBack: false,
            actions: [
              AppIconButton(
                icon: Icons.add_rounded,
                onTap: () => context.push('/seller/products/add'),
              ),
            ],
          ),
          SliverPinnedBar(
            height: AppDimensions.chipHeight + 14,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: AppDimensions.chipHeight + 4,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: AppDimensions.pagePadding,
                  children: [
                    AppChip(
                      label: 'Barchasi (${all.length})',
                      selected: _filter == _ProductFilter.barchasi,
                      onTap: () => setState(() => _filter = _ProductFilter.barchasi),
                    ),
                    const SizedBox(width: AppDimensions.space8),
                    AppChip(
                      label: 'Faol',
                      selected: _filter == _ProductFilter.faol,
                      onTap: () => setState(() => _filter = _ProductFilter.faol),
                    ),
                    const SizedBox(width: AppDimensions.space8),
                    AppChip(
                      label: 'Moderatsiyada',
                      selected: _filter == _ProductFilter.moderatsiyada,
                      onTap: () => setState(() => _filter = _ProductFilter.moderatsiyada),
                    ),
                    const SizedBox(width: AppDimensions.space8),
                    AppChip(
                      label: 'Rad etilgan',
                      selected: _filter == _ProductFilter.radEtilgan,
                      onTap: () => setState(() => _filter = _ProductFilter.radEtilgan),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (products.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'Mahsulot topilmadi',
                subtitle: 'Yangi mahsulot qo‘shib, savdoni boshlang.',
                actionLabel: 'Mahsulot qo‘shish',
                onAction: () => context.push('/seller/products/add'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.gutter,
                AppDimensions.space12,
                AppDimensions.gutter,
                AppDimensions.bottomBarClearance,
              ),
              sliver: SliverList.separated(
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.space12),
                itemBuilder: (context, i) => _SellerProductCard(
                  product: products[i],
                  onTap: () => context.push('/seller/products/${products[i].id}/edit'),
                  onDelete: () => _confirmDelete(context, ref, products[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SellerProduct product,
  ) async {
    final confirmed = await CustomDialog.confirm(
      context,
      title: 'Mahsulotni o‘chirish',
      message: '"${product.name}" ro‘yxatdan butunlay o‘chiriladi.',
      confirmLabel: 'O‘chirish',
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (confirmed) {
      ref.read(sellerProductsProvider.notifier).remove(product.id);
      if (context.mounted) {
        AppToast.show(context, 'Mahsulot o‘chirildi', tone: ToastTone.warning);
      }
    }
  }
}

class _SellerProductCard extends StatelessWidget {
  const _SellerProductCard({
    required this.product,
    required this.onTap,
    required this.onDelete,
  });

  final SellerProduct product;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final visual = EnergyVisualX.fromCategory(product.category.id, name: product.name);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.space12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          product.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(56 * 0.32),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => EnergyAvatar(visual: visual, size: 56),
                  ),
                )
              : EnergyAvatar(visual: visual, size: 56),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.callout.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    AppPill(
                      label: product.moderationStatus.labelUz,
                      tone: product.moderationStatus.tone,
                      icon: product.moderationStatus.icon,
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  AppFormatters.currency(product.price),
                  style: AppTypography.priceSmall.copyWith(color: c.primary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      product.isInStock ? Icons.inventory_2_outlined : Icons.remove_shopping_cart_rounded,
                      size: 13,
                      color: product.isInStock ? c.textTertiary : c.danger,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      product.isInStock ? 'Omborda: ${product.stockQty} ta' : 'Omborda yo‘q',
                      style: AppTypography.caption.copyWith(
                        color: product.isInStock ? c.textTertiary : c.danger,
                      ),
                    ),
                  ],
                ),
                if (product.moderationStatus == ProductModerationStatus.rejected &&
                    product.rejectionReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    product.rejectionReason!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption2.copyWith(color: c.danger),
                  ),
                ],
              ],
            ),
          ),
          AppTappable(
            onTap: onDelete,
            child: Padding(
              padding: const EdgeInsets.only(left: AppDimensions.space4),
              child: Icon(Icons.delete_outline_rounded, size: 19, color: c.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}
