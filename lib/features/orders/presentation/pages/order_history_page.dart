import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/order_status_widget.dart';
import '../../../../core/widgets/product_illustration.dart';
import '../../domain/entities/order.dart';
import '../providers/order_provider.dart';

enum OrderTab { barchasi, faol, yakunlangan }

class OrderHistoryPage extends ConsumerStatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  ConsumerState<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends ConsumerState<OrderHistoryPage> {
  OrderTab _tab = OrderTab.barchasi;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(ordersProvider);
    final active = ref.watch(activeOrdersProvider);
    final completed = ref.watch(completedOrdersProvider);

    final orders = switch (_tab) {
      OrderTab.barchasi => all,
      OrderTab.faol => active,
      OrderTab.yakunlangan => completed,
    };

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverNavBar(
            title: 'Buyurtmalar',
            subtitle: active.isEmpty
                ? '${all.length} ta buyurtma'
                : '${active.length} ta faol buyurtma',
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
              child: AppSegmentedControl<OrderTab>(
                value: _tab,
                segments: const {
                  OrderTab.barchasi: 'Barchasi',
                  OrderTab.faol: 'Faol',
                  OrderTab.yakunlangan: 'Yakunlangan',
                },
                onChanged: (tab) => setState(() => _tab = tab),
              ),
            ),
          ),
          if (orders.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: switch (_tab) {
                  OrderTab.faol => 'Faol buyurtma yo‘q',
                  OrderTab.yakunlangan => 'Yakunlangan buyurtma yo‘q',
                  OrderTab.barchasi => 'Hali buyurtma bermagansiz',
                },
                subtitle:
                    'Katalogdan mahsulot tanlang — buyurtmalaringiz shu yerda '
                    'ko‘rinadi.',
                actionLabel: 'Katalogga o‘tish',
                onAction: () => context.go('/catalog'),
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
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppDimensions.space12),
                itemBuilder: (context, i) => _OrderCard(order: orders[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final isActive = order.status.isActive;

    return AppCard(
      onTap: () => context.push('/orders/${order.id}/tracking'),
      padding: const EdgeInsets.all(AppDimensions.space14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                order.orderNumber,
                style: AppTypography.callout.copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: Text(
                  AppFormatters.relativeDate(order.date),
                  style: AppTypography.caption.copyWith(color: c.textTertiary),
                ),
              ),
              OrderStatusBadge(status: order.status, dense: true),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          Row(
            children: [
              EnergyAvatar(
                visual: EnergyVisualX.fromCategory(
                  order.items.isEmpty ? '' : order.items.first.categoryId,
                  name: order.summary,
                ),
                size: 48,
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.callout.copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.storefront_rounded,
                            size: 12, color: c.textTertiary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${order.companyName} · ${order.itemCount} dona',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption
                                .copyWith(color: c.textTertiary),
                          ),
                        ),
                      ],
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
          if (isActive) ...[
            Divider(height: AppDimensions.space24, color: c.separator),
            Row(
              children: [
                const LivePulse(),
                const SizedBox(width: AppDimensions.space4),
                Expanded(
                  child: Text(
                    order.deliveryMethod == DeliveryMethod.delivery
                        ? 'Taxminan ${AppFormatters.time(order.eta)} da yetkaziladi'
                        : 'Olib ketishga tayyorlanmoqda',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(color: c.textSecondary),
                  ),
                ),
                AppButton(
                  label: 'Kuzatish',
                  size: AppButtonSize.small,
                  expand: false,
                  onPressed: () => context.push('/orders/${order.id}/tracking'),
                ),
              ],
            ),
          ] else ...[
            Divider(height: AppDimensions.space24, color: c.separator),
            Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 15, color: c.success),
                const SizedBox(width: AppDimensions.space6),
                Expanded(
                  child: Text(
                    'Yetkazildi · ${AppFormatters.dateOnly(order.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(color: c.textSecondary),
                  ),
                ),
                AppButton(
                  label: 'Takrorlash',
                  size: AppButtonSize.small,
                  variant: AppButtonVariant.ghost,
                  expand: false,
                  onPressed: () => AppToast.show(
                    context,
                    'Mahsulotlar savatga qo‘shildi',
                    tone: ToastTone.success,
                    actionLabel: 'Savat',
                    onAction: () => context.push('/cart'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
