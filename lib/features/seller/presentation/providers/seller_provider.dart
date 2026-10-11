import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/mock_seller.dart';
import '../../data/datasources/supabase_sellers_datasource.dart' as remote;
import '../../domain/entities/seller_order.dart';
import '../../domain/entities/seller_product.dart';
import '../../domain/entities/seller_profile.dart';

// ── Seller profiles (companies) ───────────────────────────────────────

class SellerProfilesNotifier extends StateNotifier<List<SellerProfile>> {
  SellerProfilesNotifier() : super(mockSellerProfiles) {
    refresh();
  }

  /// Pulls the companies and their status from Supabase — applications
  /// from other devices, approvals made in the web admin panel. Details
  /// only this device knows (description, hours, delivery, logo) are kept
  /// for companies it already has. Without a connection (or in tests) the
  /// local list simply stays as it is.
  Future<void> refresh() async {
    final List<SellerProfile> rows;
    try {
      rows = await remote.fetchSellerProfiles();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    final local = {for (final profile in state) profile.id: profile};
    final onServer = {for (final row in rows) row.id};
    state = [
      // Not on the server (yet) — keep rather than lose it.
      for (final profile in state)
        if (!onServer.contains(profile.id)) profile,
      for (final row in rows) local[row.id]?.copyWith(status: row.status) ?? row,
    ];
  }

  /// Submits a new company application — the "Firma ma'lumotlari" step —
  /// to Supabase, where the admin panel picks it up. Only once it is
  /// stored is it added here and returned, so the caller can link it to
  /// the signed-in user. Throws when it could not be sent.
  Future<SellerProfile> submitApplication({
    required String ownerUserId,
    required String ownerName,
    required String companyName,
    required ServiceCategory category,
    required String district,
    required String description,
    required String address,
    required String phone,
    required String workingHours,
    required int deliveryFee,
    required bool offersDelivery,
    required bool offersPickup,
    String? logoUrl,
  }) async {
    final profile = _newApplication(
      ownerUserId: ownerUserId,
      ownerName: ownerName,
      companyName: companyName,
      category: category,
      district: district,
      description: description,
      address: address,
      phone: phone,
      workingHours: workingHours,
      deliveryFee: deliveryFee,
      offersDelivery: offersDelivery,
      offersPickup: offersPickup,
      logoUrl: logoUrl,
    );
    await remote.insertSellerProfile(profile);
    // Hours and delivery fee are what buyers see on the company card.
    remote
        .updateCompanyTerms(profile.id, workingHours: workingHours, deliveryFee: deliveryFee)
        .ignore();
    state = [profile, ...state];
    return profile;
  }

  /// Same as [submitApplication] but adds the company here straight away
  /// and sends it in the background — for callers that can't wait.
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
    String ownerName = '',
    String district = '',
  }) {
    final profile = _newApplication(
      ownerUserId: ownerUserId,
      ownerName: ownerName,
      companyName: companyName,
      category: category,
      district: district,
      description: description,
      address: address,
      phone: phone,
      workingHours: workingHours,
      deliveryFee: deliveryFee,
      offersDelivery: offersDelivery,
      offersPickup: offersPickup,
      logoUrl: logoUrl,
    );
    state = [profile, ...state];
    remote.insertSellerProfile(profile).ignore();
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
    // Mirrored so the web admin panel and the seller's own device agree;
    // offline the change stays on this device.
    remote.updateSellerStatus(id, status).ignore();
  }

  static SellerProfile _newApplication({
    required String ownerUserId,
    required String ownerName,
    required String companyName,
    required ServiceCategory category,
    required String district,
    required String description,
    required String address,
    required String phone,
    required String workingHours,
    required int deliveryFee,
    required bool offersDelivery,
    required bool offersPickup,
    String? logoUrl,
  }) {
    return SellerProfile(
      id: 's${DateTime.now().millisecondsSinceEpoch}',
      ownerUserId: ownerUserId,
      ownerName: ownerName,
      companyName: companyName,
      category: category,
      district: district,
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

/// Every seller's products, mirrored to Supabase `products` — the same rows
/// the seller web panel edits and the web admin moderates. Changes show
/// here at once and are written in the background; offline (or in tests)
/// they stay on this device.
class SellerProductsNotifier extends StateNotifier<List<SellerProduct>> {
  SellerProductsNotifier(this._ref) : super(mockSellerProducts) {
    refresh();
  }

  final Ref _ref;

  /// Added here but not yet confirmed by Supabase — kept across a refresh.
  final Set<String> _unsent = {};

  Future<void> refresh() async {
    final List<SellerProduct> rows;
    try {
      rows = await remote.fetchSellerProducts();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    final onServer = {for (final row in rows) row.id};
    state = [
      for (final product in state)
        if (_unsent.contains(product.id) && !onServer.contains(product.id)) product,
      ...rows,
    ];
  }

  String _companyName(String sellerId) {
    for (final profile in _ref.read(sellerProfilesProvider)) {
      if (profile.id == sellerId) return profile.companyName;
    }
    return '';
  }

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
    _unsent.add(product.id);
    remote
        .insertSellerProduct(product, companyName: _companyName(sellerId))
        .then((_) => _unsent.remove(product.id))
        .ignore();
    return product;
  }

  void update(SellerProduct updated) {
    SellerProduct? before;
    for (final product in state) {
      if (product.id == updated.id) before = product;
    }
    // Editing resets moderation — a changed price/description is
    // reviewed again before it goes live.
    final pending = updated.copyWith(moderationStatus: ProductModerationStatus.pending);
    state = [
      for (final product in state)
        if (product.id == updated.id) pending else product,
    ];
    remote
        .updateSellerProduct(pending, categoryChanged: before?.category != updated.category)
        .ignore();
  }

  void updateStock(String id, int stockQty) {
    state = [
      for (final product in state)
        if (product.id == id) product.copyWith(stockQty: stockQty) else product,
    ];
    remote.updateSellerProductStock(id, stockQty).ignore();
  }

  void remove(String id) {
    state = state.where((p) => p.id != id).toList();
    _unsent.remove(id);
    remote.deleteSellerProduct(id).ignore();
  }

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
    remote.updateProductModeration(id, status, reason: reason).ignore();
  }
}

final sellerProductsProvider =
    StateNotifierProvider<SellerProductsNotifier, List<SellerProduct>>(
  (ref) => SellerProductsNotifier(ref),
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

/// Orders from the Supabase `orders` table — what buyers place in the app.
/// Re-read every [_pollInterval] so a new order shows up on its own;
/// status changes are written straight back for the buyer's tracking.
class SellerOrdersNotifier extends StateNotifier<List<SellerOrder>> {
  SellerOrdersNotifier() : super(mockSellerOrders) {
    refresh();
    if (SupabaseService.isReady) {
      _poll = Timer.periodic(_pollInterval, (_) => refresh());
    }
  }

  static const _pollInterval = Duration(seconds: 15);
  Timer? _poll;

  /// Orders whose status change is still on its way — a refresh must not
  /// put the old status back meanwhile.
  final Set<String> _saving = {};

  Future<void> refresh() async {
    final List<SellerOrder> rows;
    try {
      rows = await remote.fetchSellerOrders();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    final local = {for (final order in state) order.id: order};
    state = [
      for (final row in rows)
        if (_saving.contains(row.id) && local[row.id] != null) local[row.id]! else row,
    ];
  }

  void _move(String id, SellerOrderStatus Function(SellerOrderStatus) to) {
    SellerOrder? before;
    for (final order in state) {
      if (order.id == id) before = order;
    }
    if (before == null) return;
    final next = to(before.status);
    if (next == before.status) return;
    state = [
      for (final order in state)
        if (order.id == id) order.copyWith(status: next) else order,
    ];
    _saving.add(id);
    remote
        .updateSellerOrderStatus(id, from: before.status, to: next)
        .then((saved) {
          // The buyer may have cancelled meanwhile — show what was stored.
          if (mounted) {
            state = [for (final order in state) order.id == id ? saved : order];
          }
        })
        .whenComplete(() => _saving.remove(id))
        .ignore();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  static const List<SellerOrderStatus> _flow = [
    SellerOrderStatus.yangi,
    SellerOrderStatus.tayyorlanmoqda,
    SellerOrderStatus.yetkazishga,
    SellerOrderStatus.yopildi,
  ];

  void advance(String id) => _move(id, _next);

  void cancel(String id) => _move(id, (_) => SellerOrderStatus.bekorQilindi);

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
