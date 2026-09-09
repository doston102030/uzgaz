import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_pills.dart';
import '../../../seller/presentation/providers/seller_provider.dart';

class AdminOrdersPage extends ConsumerStatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  ConsumerState<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends ConsumerState<AdminOrdersPage> {
  SellerOrderStatus? _statusFilter;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final sellers = ref.watch(sellerProfilesProvider);
    String sellerName(String id) =>
        sellers.where((s) => s.id == id).map((s) => s.companyName).firstOrNull ?? '—';

    final orders = ref.watch(sellerOrdersProvider).where((o) {
      final matchesStatus = _statusFilter == null || o.status == _statusFilter;
      final query = _query.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          o.orderNumber.toLowerCase().contains(query) ||
          o.buyerName.toLowerCase().contains(query);
      return matchesStatus && matchesQuery;
    }).toList()
      ..sort((a, b) => b.placedAt.compareTo(a.placedAt));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverNavBar(
            title: 'Buyurtmalar',
            subtitle: '${orders.length} ta topildi',
            showBack: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.gutter,
                AppDimensions.space8,
                AppDimensions.gutter,
                AppDimensions.space12,
              ),
              child: AppSearchField(
                hint: 'Buyurtma raqami yoki xaridor',
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
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
                      label: 'Barchasi',
                      selected: _statusFilter == null,
                      onTap: () => setState(() => _statusFilter = null),
                    ),
                    for (final status in SellerOrderStatus.values) ...[
                      const SizedBox(width: AppDimensions.space8),
                      AppChip(
                        label: status.labelUz,
                        icon: status.icon,
                        selected: _statusFilter == status,
                        onTap: () => setState(() => _statusFilter = status),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (orders.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(icon: Icons.receipt_long_outlined, title: 'Buyurtma topilmadi'),
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
                separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.space10),
                itemBuilder: (context, i) {
                  final order = orders[i];
                  return AppCard(
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
                            AppPill(label: order.status.labelUz, tone: order.status.tone, dense: true),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          AppFormatters.relativeDate(order.placedAt),
                          style: AppTypography.caption.copyWith(color: c.textTertiary),
                        ),
                        const SizedBox(height: AppDimensions.space8),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.storefront_outlined, size: 13, color: c.textTertiary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      sellerName(order.sellerId),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.caption.copyWith(color: c.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppDimensions.space10),
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.person_outline_rounded, size: 13, color: c.textTertiary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      order.buyerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.caption.copyWith(color: c.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.space8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                order.summary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(color: c.textTertiary),
                              ),
                            ),
                            Text(
                              AppFormatters.currency(order.total),
                              style: AppTypography.priceSmall.copyWith(color: c.textPrimary),
                            ),
                          ],
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
