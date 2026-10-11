import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/supabase_orders_datasource.dart';
import '../../domain/entities/order.dart';

/// The buyer's orders, backed by the Supabase `orders` table.
///
/// The device remembers the ids it placed, so a guest still finds their
/// orders after a reload; a signed-in buyer also gets the orders placed
/// with their phone number. While an order is in progress the list is
/// re-read every [_pollInterval] — the seller panel moves the status.
class OrdersNotifier extends StateNotifier<List<Order>> {
  OrdersNotifier(this._ref) : super(const []) {
    _ref.listen(authProvider.select((user) => user?.phone), (_, __) => refresh());
    refresh();
  }

  final Ref _ref;
  Timer? _poll;
  Set<String>? _placedIds;

  static const _pollInterval = Duration(seconds: 10);
  static const _placedIdsKey = 'placed_order_ids';

  Future<Set<String>> _loadPlacedIds() async {
    if (_placedIds != null) return _placedIds!;
    try {
      final raw = (await LocalStorage.create()).getString(_placedIdsKey);
      _placedIds = raw == null ? <String>{} : (jsonDecode(raw) as List).cast<String>().toSet();
    } catch (_) {
      // No storage (tests, private mode) — this session's orders only.
      _placedIds = <String>{};
    }
    return _placedIds!;
  }

  Future<void> _rememberPlaced(String id) async {
    final ids = await _loadPlacedIds();
    ids.add(id);
    try {
      await (await LocalStorage.create()).setString(_placedIdsKey, jsonEncode(ids.toList()));
    } catch (_) {}
  }

  /// Re-reads the list; keeps the current one if the network fails.
  Future<void> refresh() async {
    try {
      final orders = await fetchBuyerOrders(
        ids: await _loadPlacedIds(),
        phone: _ref.read(authProvider)?.phone,
      );
      if (!mounted) return;
      state = orders;
    } catch (_) {
      // Offline or Supabase not configured — keep what we have.
    }
    _syncPolling();
  }

  void _syncPolling() {
    if (!mounted) return;
    final hasActive = state.any((o) => o.status.isActive);
    if (hasActive && _poll == null) {
      _poll = Timer.periodic(_pollInterval, (_) => refresh());
    } else if (!hasActive) {
      _poll?.cancel();
      _poll = null;
    }
  }

  /// Sends the order to the seller. Throws if Supabase rejects it — the
  /// payment screen shows the error and keeps the cart.
  Future<Order> place({
    required String companyId,
    required String companyName,
    required List<OrderItem> items,
    required int deliveryFee,
    required int total,
    required DeliveryMethod deliveryMethod,
    required PaymentMethod paymentMethod,
    String? address,
  }) async {
    final user = _ref.read(authProvider);
    final order = await insertOrder(
      id: 'o${DateTime.now().millisecondsSinceEpoch}',
      companyId: companyId,
      companyName: companyName,
      buyerName: user?.fullName ?? 'Mehmon',
      buyerPhone: user?.phone ?? '',
      items: items,
      subtotal: items.fold(0, (sum, item) => sum + item.subtotal),
      deliveryFee: deliveryFee,
      total: total,
      deliveryMethod: deliveryMethod,
      paymentMethod: paymentMethod,
      address: address,
    );
    await _rememberPlaced(order.id);
    if (mounted) {
      state = [order, ...state.where((o) => o.id != order.id)];
      _syncPolling();
    }
    return order;
  }

  /// Buyer cancels while the order is still "Qabul qilindi". Returns the
  /// status it ended in — the seller may have started on it meanwhile.
  Future<OrderStatus> cancel(String id) async {
    final status = await cancelOrder(id);
    if (mounted) {
      state = [
        for (final order in state)
          order.id == id ? order.copyWith(status: status) : order,
      ];
      _syncPolling();
    }
    return status;
  }

  Order? byId(String id) {
    for (final order in state) {
      if (order.id == id) return order;
    }
    return null;
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, List<Order>>((ref) => OrdersNotifier(ref));

final orderByIdProvider = Provider.family<Order?, String>((ref, id) {
  final orders = ref.watch(ordersProvider);
  for (final order in orders) {
    if (order.id == id) return order;
  }
  return orders.isNotEmpty ? orders.first : null;
});

final activeOrdersProvider = Provider<List<Order>>(
  (ref) => ref.watch(ordersProvider).where((o) => o.status.isActive).toList(),
);

final completedOrdersProvider = Provider<List<Order>>(
  (ref) => ref.watch(ordersProvider).where((o) => !o.status.isActive).toList(),
);

/// The single most recent in-progress order — shown as a live tracker
/// card at the top of Home.
final currentOrderProvider = Provider<Order?>((ref) {
  final active = ref.watch(activeOrdersProvider);
  return active.isEmpty ? null : active.first;
});
