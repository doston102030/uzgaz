import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/mock_seller.dart';
import '../../domain/entities/seller_order.dart';
import '../../domain/entities/seller_product.dart';
import '../../domain/entities/seller_profile.dart';

// ── Seller profiles (companies) ───────────────────────────────────────

class SellerProfilesNotifier extends StateNotifier<List<SellerProfile>> {
  SellerProfilesNotifier() : super(mockSellerProfiles);

  /// Submits a new company application — the "Firma ma'lumotlari" step —
  /// and returns it so the caller can link it to the signed-in user.
  SellerProfile apply({
    required String ownerUserId,
    required String companyName,
    required ServiceCategory category,
    required String description,
    required String address,
    required String phone,
    required String workingHours,
    required int deliveryFee,
    required bool offersDelivery,
    required bool offersPickup,
    String? logoUrl,
  }) {
    final profile = SellerProfile(
      id: 's${DateTime.now().millisecondsSinceEpoch}',
      ownerUserId: ownerUserId,
      companyName: companyName,
      category: category,
      description: description,
      address: address,
      phone: phone,
      workingHours: workingHours,
      deliveryFee: deliveryFee,
      status: SellerStatus.pending,
      createdAt: DateTime.now(),
      offersDelivery: offersDelivery,
      offersPickup: offersPickup,
      logoUrl: logoUrl,
    );
    state = [profile, ...state];
    return profile;
  }

  void approve(String id) => _setStatus(id, SellerStatus.approved);

  void reject(String id, {String? reason}) =>
      _setStatus(id, SellerStatus.rejected, reason: reason);

  void suspend(String id) => _setStatus(id, SellerStatus.suspended);

  void reactivate(String id) => _setStatus(id, SellerStatus.approved);

  void _setStatus(String id, SellerStatus status, {String? reason}) {
    state = [
      for (final profile in state)
        if (profile.id == id)
          profile.copyWith(status: status, rejectionReason: reason)
        else
          profile,
    ];
  }
}

final sellerProfilesProvider =
    StateNotifierProvider<SellerProfilesNotifier, List<SellerProfile>>(
  (ref) => SellerProfilesNotifier(),
);

/// The company belonging to the signed-in user, if any.
final currentSellerProvider = Provider<SellerProfile?>((ref) {
  final sellerId = ref.watch(authProvider)?.sellerId;
  if (sellerId == null) return null;
  final profiles = ref.watch(sellerProfilesProvider);
  for (final profile in profiles) {
    if (profile.id == sellerId) return profile;
  }
  return null;
});

final pendingSellersProvider = Provider<List<SellerProfile>>((ref) {
  return ref.watch(sellerProfilesProvider).where((p) => p.status == SellerStatus.pending).toList();
});

final approvedSellersProvider = Provider<List<SellerProfile>>((ref) {
  return ref.watch(sellerProfilesProvider).where((p) => p.status == SellerStatus.approved).toList();
});

// ── Seller products ─────────────────────────────────────────────────

class SellerProductsNotifier extends StateNotifier<List<SellerProduct>> {
  SellerProductsNotifier() : super(mockSellerProducts);

  SellerProduct add({
    required String sellerId,
    required String name,
    required ServiceCategory category,
    required String description,
    required int price,
    required int stockQty,
    String unit = 'dona',
    int? oldPrice,
    String? imageUrl,
  }) {
    final product = SellerProduct(
      id: 'sp${DateTime.now().millisecondsSinceEpoch}',
      sellerId: sellerId,
      name: name,
      category: category,
      description: description,
      price: price,
      oldPrice: oldPrice,
      stockQty: stockQty,
      unit: unit,
      moderationStatus: ProductModerationStatus.pending,
      createdAt: DateTime.now(),
      imageUrl: imageUrl,
    );
    state = [product, ...state];
    return product;
  }

  void update(SellerProduct updated) {
    state = [
      for (final product in state)
        if (product.id == updated.id)
          // Editing resets moderation — a changed price/description is
          // reviewed again before it goes live.
          updated.copyWith(moderationStatus: ProductModerationStatus.pending)
        else
          product,
    ];
  }

  void updateStock(String id, int stockQty) {
    state = [
      for (final product in state)
        if (product.id == id) product.copyWith(stockQty: stockQty) else product,
    ];
  }

  void remove(String id) => state = state.where((p) => p.id != id).toList();

  void approve(String id) => _setModeration(id, ProductModerationStatus.approved);

  void reject(String id, {String? reason}) =>
      _setModeration(id, ProductModerationStatus.rejected, reason: reason);

  void _setModeration(String id, ProductModerationStatus status, {String? reason}) {
    state = [
      for (final product in state)
        if (product.id == id)
          product.copyWith(moderationStatus: status, rejectionReason: reason)
        else
          product,
    ];
  }
}

final sellerProductsProvider =
    StateNotifierProvider<SellerProductsNotifier, List<SellerProduct>>(
  (ref) => SellerProductsNotifier(),
);

final currentSellerProductsProvider = Provider<List<SellerProduct>>((ref) {
  final sellerId = ref.watch(currentSellerProvider)?.id;
  if (sellerId == null) return const [];
  return ref.watch(sellerProductsProvider).where((p) => p.sellerId == sellerId).toList();
});

final pendingProductsProvider = Provider<List<SellerProduct>>((ref) {
  return ref
      .watch(sellerProductsProvider)
      .where((p) => p.moderationStatus == ProductModerationStatus.pending)
      .toList();
});

// ── Seller orders ──────────────────────────────────────────────────

class SellerOrdersNotifier extends StateNotifier<List<SellerOrder>> {
  SellerOrdersNotifier() : super(mockSellerOrders);

  static const List<SellerOrderStatus> _flow = [
    SellerOrderStatus.yangi,
    SellerOrderStatus.tayyorlanmoqda,
    SellerOrderStatus.yetkazishga,
    SellerOrderStatus.yopildi,
  ];

  void advance(String id) {
    state = [
      for (final order in state)
        if (order.id == id)
          order.copyWith(status: _next(order.status))
        else
          order,
    ];
  }

  void cancel(String id) {
    state = [
      for (final order in state)
        if (order.id == id) order.copyWith(status: SellerOrderStatus.bekorQilindi) else order,
    ];
  }

  SellerOrderStatus _next(SellerOrderStatus current) {
    final index = _flow.indexOf(current);
    if (index == -1 || index == _flow.length - 1) return current;
    return _flow[index + 1];
  }
}

final sellerOrdersProvider =
    StateNotifierProvider<SellerOrdersNotifier, List<SellerOrder>>(
  (ref) => SellerOrdersNotifier(),
);

final currentSellerOrdersProvider = Provider<List<SellerOrder>>((ref) {
  final sellerId = ref.watch(currentSellerProvider)?.id;
  if (sellerId == null) return const [];
  final orders = [...ref.watch(sellerOrdersProvider).where((o) => o.sellerId == sellerId)];
  orders.sort((a, b) => b.placedAt.compareTo(a.placedAt));
  return orders;
});

final newSellerOrdersProvider = Provider<List<SellerOrder>>((ref) {
  return ref
      .watch(currentSellerOrdersProvider)
      .where((o) => o.status == SellerOrderStatus.yangi)
      .toList();
});

/// Simple seller-side analytics — revenue and unit counts from closed
/// orders, computed client-side over the mock dataset for the reports tab.
class SellerStats {
  const SellerStats({
    required this.todayRevenue,
    required this.todayOrders,
    required this.weekRevenue,
    required this.totalRevenue,
    required this.totalOrders,
    required this.activeProducts,
    required this.avgOrderValue,
  });

  final int todayRevenue;
  final int todayOrders;
  final int weekRevenue;
  final int totalRevenue;
  final int totalOrders;
  final int activeProducts;
  final int avgOrderValue;
}

final sellerStatsProvider = Provider<SellerStats>((ref) {
  final orders = ref
      .watch(currentSellerOrdersProvider)
      .where((o) => o.status != SellerOrderStatus.bekorQilindi)
      .toList();
  final products = ref.watch(currentSellerProductsProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekAgo = today.subtract(const Duration(days: 7));

  final todayOrders = orders.where((o) => !o.placedAt.isBefore(today)).toList();
  final weekOrders = orders.where((o) => !o.placedAt.isBefore(weekAgo)).toList();
  final totalRevenue = orders.fold(0, (sum, o) => sum + o.total);

  return SellerStats(
    todayRevenue: todayOrders.fold(0, (sum, o) => sum + o.total),
    todayOrders: todayOrders.length,
    weekRevenue: weekOrders.fold(0, (sum, o) => sum + o.total),
    totalRevenue: totalRevenue,
    totalOrders: orders.length,
    activeProducts: products.where((p) => p.isLive).length,
    avgOrderValue: orders.isEmpty ? 0 : totalRevenue ~/ orders.length,
  );
});
