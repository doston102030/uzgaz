import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/entities/order.dart';

/// Orders in the `orders` table (see `supabase/marketplace_setup.sql`) —
/// the buyer places them here, the seller panel moves them along, the
/// admin panel lists them all.
const _columns =
    'id, order_number, company_id, company_name, delivery_method, address, '
    'items, delivery_fee, total, status, created_at';

/// Writes a new order; the database assigns the `#GE…` number.
Future<Order> insertOrder({
  required String id,
  required String companyId,
  required String companyName,
  required String buyerName,
  required String buyerPhone,
  required List<OrderItem> items,
  required int subtotal,
  required int deliveryFee,
  required int total,
  required DeliveryMethod deliveryMethod,
  required PaymentMethod paymentMethod,
  String? address,
}) async {
  final row = await SupabaseService.client
      .from('orders')
      .insert({
        'id': id,
        // An empty id would break the foreign key; null = no company yet.
        'company_id': companyId.isEmpty ? null : companyId,
        'company_name': companyName,
        'buyer_name': buyerName,
        'buyer_phone': buyerPhone,
        'delivery_method': deliveryMethod.name,
        'payment_method': paymentMethod.name,
        'address': address,
        'items': [
          for (final item in items)
            {
              'product_id': item.productId,
              'name': item.productName,
              'quantity': item.quantity,
              'price': item.price,
              'category_id': item.categoryId,
            },
        ],
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'total': total,
      })
      .select(_columns)
      .single();
  return _orderFromRow(row);
}

/// The buyer's orders: everything placed from this device ([ids]) plus,
/// when signed in, everything placed with their phone number.
Future<List<Order>> fetchBuyerOrders({
  required Iterable<String> ids,
  String? phone,
}) async {
  final filters = [
    if (ids.isNotEmpty) 'id.in.(${ids.map((id) => '"$id"').join(',')})',
    if (phone != null && phone.isNotEmpty) 'buyer_phone.eq."$phone"',
  ];
  if (filters.isEmpty) return const [];
  final rows = await SupabaseService.client
      .from('orders')
      .select(_columns)
      .or(filters.join(','))
      .order('created_at', ascending: false);
  return rows.map(_orderFromRow).toList();
}

/// Buyer-side cancel — only while the seller hasn't started on it.
Future<OrderStatus> cancelOrder(String id) async {
  final rows = await SupabaseService.client
      .from('orders')
      .update({'status': OrderStatus.bekorQilindi.name})
      .eq('id', id)
      .eq('status', OrderStatus.qabulQilindi.name)
      .select('status');
  if (rows.isEmpty) {
    // The seller moved it on meanwhile — report the real status.
    final row = await SupabaseService.client
        .from('orders')
        .select('status')
        .eq('id', id)
        .single();
    return _status(row['status']);
  }
  return OrderStatus.bekorQilindi;
}

Order _orderFromRow(Map<String, dynamic> row) {
  final items = (row['items'] as List?) ?? const [];
  return Order(
    id: row['id'] as String,
    orderNumber: row['order_number'] as String,
    date: DateTime.parse(row['created_at'] as String).toLocal(),
    companyId: (row['company_id'] as String?) ?? '',
    companyName: row['company_name'] as String,
    items: [
      for (final item in items.cast<Map<String, dynamic>>())
        OrderItem(
          productId: (item['product_id'] as String?) ?? '',
          productName: item['name'] as String,
          quantity: (item['quantity'] as num).toInt(),
          price: (item['price'] as num).toInt(),
          categoryId: (item['category_id'] as String?) ?? 'gazBallon',
        ),
    ],
    total: row['total'] as int,
    status: _status(row['status']),
    deliveryMethod: row['delivery_method'] == DeliveryMethod.selfPickup.name
        ? DeliveryMethod.selfPickup
        : DeliveryMethod.delivery,
    address: row['address'] as String?,
    deliveryFee: row['delivery_fee'] as int,
  );
}

OrderStatus _status(Object? value) => OrderStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => OrderStatus.qabulQilindi,
    );
