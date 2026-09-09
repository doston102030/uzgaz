import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../orders/presentation/providers/order_provider.dart';
import '../../../seller/presentation/providers/seller_provider.dart';

/// Marketplace-wide numbers for the admin dashboard — aggregated over the
/// mock datasets (sellers, products, seller-side orders). A real backend
/// would compute these with a Cloud Function / scheduled aggregation.
class AdminStats {
  const AdminStats({
    required this.totalSellers,
    required this.pendingSellers,
    required this.totalProducts,
    required this.pendingProducts,
    required this.totalOrders,
    required this.totalRevenue,
    required this.commissionEarned,
  });

  final int totalSellers;
  final int pendingSellers;
  final int totalProducts;
  final int pendingProducts;
  final int totalOrders;
  final int totalRevenue;
  final int commissionEarned;
}

/// Marketplace commission percentage — editable from Admin → Sozlamalar.
final commissionRateProvider = StateProvider<double>((ref) => 8);

/// Whether the homepage promo banner ("Aholi uchun — SUYULTIRILGAN GAZ")
/// is currently active — the simplest possible "reklama" toggle.
final promoBannerActiveProvider = StateProvider<bool>((ref) => true);

final adminStatsProvider = Provider<AdminStats>((ref) {
  final sellers = ref.watch(sellerProfilesProvider);
  final products = ref.watch(sellerProductsProvider);
  final orders = ref.watch(sellerOrdersProvider);
  final commissionRate = ref.watch(commissionRateProvider);

  final totalRevenue = orders.fold(0, (sum, o) => sum + o.total);

  return AdminStats(
    totalSellers: sellers.length,
    pendingSellers: ref.watch(pendingSellersProvider).length,
    totalProducts: products.length,
    pendingProducts: ref.watch(pendingProductsProvider).length,
    totalOrders: orders.length,
    totalRevenue: totalRevenue,
    commissionEarned: (totalRevenue * commissionRate / 100).round(),
  );
});

/// Reuses the buyer-side order history as the admin's marketplace-wide
/// order feed — in this mock build it is the same pool of orders every
/// role ultimately looks at, just through a different lens.
final adminOrderFeedProvider = Provider((ref) => ref.watch(ordersProvider));
