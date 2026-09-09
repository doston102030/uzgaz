import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/price_row.dart';
import '../../../../core/widgets/status_pills.dart';
import '../../domain/entities/seller_order.dart';
import '../providers/seller_provider.dart';

enum _OrderFilter { faol, yopilgan, hammasi }

class SellerOrdersPage extends ConsumerStatefulWidget {
  const SellerOrdersPage({super.key});

  @override
  ConsumerState<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends ConsumerState<SellerOrdersPage> {
  _OrderFilter _filter = _OrderFilter.faol;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(currentSellerOrdersProvider);

    final orders = switch (_filter) {
      _OrderFilter.faol => all
          .where((o) =>
              o.status != SellerOrderStatus.yopildi &&
              o.status != SellerOrderStatus.bekorQilindi)
          .toList(),
      _OrderFilter.yopilgan => all
          .where((o) =>
              o.status == SellerOrderStatus.yopildi ||
              o.status == SellerOrderStatus.bekorQilindi)
          .toList(),
      _OrderFilter.hammasi => all,
    };

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverNavBar(
            title: 'Buyurtmalar',
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
              child: AppSegmentedControl<_OrderFilter>(
                value: _filter,
                segments: const {
                  _OrderFilter.faol: 'Faol',
                  _OrderFilter.yopilgan: 'Yopilgan',
                  _OrderFilter.hammasi: 'Hammasi',
                },
                onChanged: (f) => setState(() => _filter = f),
              ),
            ),
          ),
          if (orders.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Buyurtma yo‘q',
                subtitle: 'Yangi buyurtmalar shu yerda paydo bo‘ladi.',
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
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.space12),
                itemBuilder: (context, i) => _SellerOrderCard(
                  order: orders[i],
                  onTap: () => _showDetail(context, ref, orders[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showDetail(BuildContext context, WidgetRef ref, SellerOrder order) async {
    await AppSheet.show<void>(
      context,
      title: order.orderNumber,
      child: _OrderDetailSheet(order: order),
    );
  }
}

class _SellerOrderCard extends ConsumerWidget {
  const _SellerOrderCard({required this.order, required this.onTap});

  final SellerOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.space14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.callout.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              AppPill(label: order.status.labelUz, tone: order.status.tone, icon: order.status.icon, dense: true),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            AppFormatters.relativeDate(order.placedAt),
            style: AppTypography.caption.copyWith(color: c.textTertiary),
          ),
          const SizedBox(height: AppDimensions.space10),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_rounded, size: 18, color: c.textSecondary),
              ),
              const SizedBox(width: AppDimensions.space10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.buyerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.callout.copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${order.summary} · ${order.itemCount} dona',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(color: c.textTertiary),
                    ),
                  ],
                ),
              ),
              Text(
                AppFormatters.currency(order.total),
                style: AppTypography.priceSmall.copyWith(color: c.textPrimary),
              ),
            ],
          ),
          if (order.status.nextActionLabel != null) ...[
            const SizedBox(height: AppDimensions.space12),
            AppButton(
              label: order.status.nextActionLabel!,
              size: AppButtonSize.small,
              icon: Icons.arrow_forward_rounded,
              onPressed: () => ref.read(sellerOrdersProvider.notifier).advance(order.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderDetailSheet extends ConsumerWidget {
  const _OrderDetailSheet({required this.order});

  final SellerOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    // Re-read the live order so status updates while the sheet is open.
    final live = ref
        .watch(currentSellerOrdersProvider)
        .firstWhere((o) => o.id == order.id, orElse: () => order);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppPill(label: live.status.labelUz, tone: live.status.tone, icon: live.status.icon),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: Text(
                  AppFormatters.date(live.placedAt),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: c.textTertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),
          AppCard(
            padding: const EdgeInsets.all(AppDimensions.space14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: c.surfaceMuted, shape: BoxShape.circle),
                  child: Icon(Icons.person_rounded, color: c.textSecondary),
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        live.buyerName,
                        style: AppTypography.callout.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        AppFormatters.phone(live.buyerPhone),
                        style: AppTypography.caption.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                AppIconButton(
                  icon: Icons.call_rounded,
                  iconSize: 17,
                  background: c.success,
                  foreground: Colors.white,
                  bordered: false,
                  onTap: () => launchUrl(Uri.parse('tel:${live.buyerPhone}')),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space12),
          AppCard(
            child: Row(
              children: [
                Icon(live.deliveryMethod.icon, size: 18, color: c.primary),
                const SizedBox(width: AppDimensions.space10),
                Expanded(
                  child: Text(
                    live.address ?? live.deliveryMethod.labelUz,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.callout.copyWith(color: c.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mahsulotlar',
                  style: AppTypography.headline.copyWith(color: c.textPrimary),
                ),
                const SizedBox(height: AppDimensions.space10),
                for (final item in live.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.productName} × ${item.quantity}',
                            style: AppTypography.callout.copyWith(color: c.textSecondary),
                          ),
                        ),
                        Text(
                          AppFormatters.currency(item.subtotal),
                          style: AppTypography.priceSmall.copyWith(color: c.textPrimary),
                        ),
                      ],
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppDimensions.space10),
                  child: DashedDivider(),
                ),
                PriceRow(label: 'Jami', amount: live.total, isTotal: true),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space20),
          if (live.status.nextActionLabel != null)
            AppButton(
              label: live.status.nextActionLabel!,
              icon: Icons.arrow_forward_rounded,
              onPressed: () => ref.read(sellerOrdersProvider.notifier).advance(live.id),
            ),
          if (live.status == SellerOrderStatus.yangi) ...[
            const SizedBox(height: AppDimensions.space10),
            AppButton(
              label: 'Bekor qilish',
              variant: AppButtonVariant.outline,
              onPressed: () async {
                final confirmed = await CustomDialog.confirm(
                  context,
                  title: 'Buyurtmani bekor qilish',
                  message: 'Xaridorga bekor qilinganligi haqida xabar boradi.',
                  confirmLabel: 'Ha, bekor qilish',
                  destructive: true,
                );
                if (confirmed) {
                  ref.read(sellerOrdersProvider.notifier).cancel(live.id);
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
            ),
          ],
          const SizedBox(height: AppDimensions.space8),
        ],
      ),
    );
  }
}
