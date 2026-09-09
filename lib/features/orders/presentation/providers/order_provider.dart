import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/datasources/mock_orders.dart';
import '../../domain/entities/order.dart';

/// Orders live in memory for the mock build; the same API (place / advance)
/// is what a Firestore-backed repository will expose in Phase 9.
class OrdersNotifier extends StateNotifier<List<Order>> {
  OrdersNotifier() : super(mockOrders);

  static int _sequence = 234522;

  Order place({
    required String companyName,
    required List<OrderItem> items,
    required int total,
    required DeliveryMethod deliveryMethod,
    String? address,
    DriverInfo? driver,
  }) {
    final id = 'o${DateTime.now().millisecondsSinceEpoch}';
    final order = Order(
      id: id,
      orderNumber: '#GE${_sequence++}',
      date: DateTime.now(),
      companyName: companyName,
      items: items,
      total: total,
      status: OrderStatus.qabulQilindi,
      deliveryMethod: deliveryMethod,
      address: address,
      driver: driver ?? mockDriver,
    );
    state = [order, ...state];
    return order;
  }

  /// Moves an order to the next status — used by the tracking screen's
  /// simulated progress until live backend events exist.
  void advance(String id) {
    state = [
      for (final order in state)
        if (order.id == id && order.status != OrderStatus.yetkazildi)
          order.copyWith(
            status: OrderStatus.values[order.status.step + 1],
          )
        else
          order,
    ];
  }

  Order? byId(String id) {
    for (final order in state) {
      if (order.id == id) return order;
    }
    return null;
  }
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, List<Order>>((ref) => OrdersNotifier());

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
