import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../orders/domain/entities/order.dart';
import '../../domain/entities/seller_order.dart';
import '../../domain/entities/seller_product.dart';
import '../../domain/entities/seller_profile.dart';

/// Seller companies in the `sellers` table (see `supabase/all_setup.sql`) —
/// the same rows the web admin panel lists and moderates. The table only
/// has the admin-facing columns; description, hours, delivery fee and logo
/// stay on the device until the schema grows them.
Future<List<SellerProfile>> fetchSellerProfiles() async {
  final rows = await SupabaseService.client
      .from('sellers')
      .select()
      .order('created_at', ascending: false);
  return rows.map(_sellerFromRow).toList();
}

/// Sends a new application (or an admin-added company) to the admin panel.
Future<void> insertSellerProfile(SellerProfile profile) async {
  await SupabaseService.client.from('sellers').insert({
    'id': profile.id,
    'company_name': profile.companyName,
    'owner_name': profile.ownerName,
    'category': profile.category.id,
    'district': profile.district,
    'address': profile.address,
    'phone': profile.phone,
    'status': profile.status.name,
  });
}

Future<void> updateSellerStatus(String id, SellerStatus status) async {
  await SupabaseService.client
      .from('sellers')
      .update({'status': status.name}).eq('id', id);
}

/// The buyer-facing terms from the application form. The company row is
/// created by a trigger when the seller row is (marketplace_setup.sql);
/// before that SQL runs there is no row and this changes nothing.
Future<void> updateCompanyTerms(
  String id, {
  required String workingHours,
  required int deliveryFee,
}) async {
  await SupabaseService.client.from('companies').update({
    'working_hours': workingHours,
    'delivery_fee': deliveryFee,
  }).eq('id', id);
}

// ── Products (same rows the seller web panel manages) ─────────────────

const _productColumns =
    'id, company_id, name, category_id, description, price, old_price, '
    'stock_qty, unit, image_url, moderation_status, rejection_reason, created_at';

Future<List<SellerProduct>> fetchSellerProducts() async {
  final rows = await SupabaseService.client
      .from('products')
      .select(_productColumns)
      .not('company_id', 'is', null)
      .order('created_at', ascending: false);
  return rows.map(_productFromRow).toList();
}

Future<void> insertSellerProduct(SellerProduct product, {required String companyName}) async {
  await SupabaseService.client.from('products').insert({
    'id': product.id,
    'company_id': product.sellerId,
    'company_name': companyName,
    'category_id': product.category.id,
    ..._productFields(product),
    'moderation_status': product.moderationStatus.name,
  });
}

/// [categoryChanged] false keeps the stored `category_id` — the web panel
/// allows categories the app's [ServiceCategory] has no value for.
Future<void> updateSellerProduct(SellerProduct product, {required bool categoryChanged}) async {
  await SupabaseService.client.from('products').update({
    if (categoryChanged) 'category_id': product.category.id,
    ..._productFields(product),
    'moderation_status': product.moderationStatus.name,
    // An edit goes back to moderation; the old rejection no longer applies.
    'rejection_reason': null,
  }).eq('id', product.id);
}

Future<void> updateSellerProductStock(String id, int stockQty) async {
  await SupabaseService.client.from('products').update({'stock_qty': stockQty}).eq('id', id);
}

Future<void> updateProductModeration(
  String id,
  ProductModerationStatus status, {
  String? reason,
}) async {
  await SupabaseService.client.from('products').update({
    'moderation_status': status.name,
    'rejection_reason': reason,
  }).eq('id', id);
}

Future<void> deleteSellerProduct(String id) async {
  await SupabaseService.client.from('products').delete().eq('id', id);
}

Map<String, dynamic> _productFields(SellerProduct product) => {
      'name': product.name,
      'description': product.description,
      'price': product.price,
      'old_price': product.oldPrice,
      'stock_qty': product.stockQty,
      'unit': product.unit,
      'image_url': product.imageUrl ?? '',
    };

SellerProduct _productFromRow(Map<String, dynamic> row) {
  final imageUrl = row['image_url'] as String?;
  return SellerProduct(
    id: row['id'] as String,
    sellerId: row['company_id'] as String,
    name: row['name'] as String,
    category: ServiceCategory.values.firstWhere(
      (c) => c.id == row['category_id'],
      orElse: () => ServiceCategory.gazBallon,
    ),
    description: (row['description'] as String?) ?? '',
    price: row['price'] as int,
    oldPrice: row['old_price'] as int?,
    stockQty: (row['stock_qty'] as int?) ?? 0,
    unit: (row['unit'] as String?) ?? 'dona',
    imageUrl: imageUrl == null || imageUrl.isEmpty ? null : imageUrl,
    moderationStatus: ProductModerationStatus.values.firstWhere(
      (s) => s.name == row['moderation_status'],
      orElse: () => ProductModerationStatus.pending,
    ),
    rejectionReason: row['rejection_reason'] as String?,
    createdAt: DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
  );
}

// ── Orders (the `orders` table the buyer app writes) ──────────────────

const _orderColumns =
    'id, order_number, company_id, buyer_name, buyer_phone, items, total, '
    'status, delivery_method, address, created_at';

/// Every seller's orders — the cabinet filters to its own company, the
/// in-app admin sees them all.
Future<List<SellerOrder>> fetchSellerOrders() async {
  final rows = await SupabaseService.client
      .from('orders')
      .select(_orderColumns)
      .order('created_at', ascending: false);
  return rows.map(_sellerOrderFromRow).toList();
}

/// Moves an order from [from] to [to]; if the buyer cancelled meanwhile
/// nothing is written and the stored order comes back.
Future<SellerOrder> updateSellerOrderStatus(
  String id, {
  required SellerOrderStatus from,
  required SellerOrderStatus to,
}) async {
  final updated = await SupabaseService.client
      .from('orders')
      .update({'status': to.toOrderStatus.name})
      .eq('id', id)
      .eq('status', from.toOrderStatus.name)
      .select(_orderColumns);
  if (updated.isNotEmpty) return _sellerOrderFromRow(updated.first);
  final current = await SupabaseService.client
      .from('orders')
      .select(_orderColumns)
      .eq('id', id)
      .single();
  return _sellerOrderFromRow(current);
}

SellerOrder _sellerOrderFromRow(Map<String, dynamic> row) {
  final status = OrderStatus.values.firstWhere(
    (s) => s.name == row['status'],
    orElse: () => OrderStatus.qabulQilindi,
  );
  final buyerName = (row['buyer_name'] as String?) ?? '';
  final items = ((row['items'] as List?) ?? const []).cast<Map<String, dynamic>>();
  return SellerOrder(
    id: row['id'] as String,
    orderNumber: row['order_number'] as String,
    sellerId: (row['company_id'] as String?) ?? '',
    buyerName: buyerName.isEmpty ? 'Mehmon' : buyerName,
    buyerPhone: (row['buyer_phone'] as String?) ?? '',
    items: [
      for (final item in items)
        OrderItem(
          productId: (item['product_id'] as String?) ?? '',
          productName: item['name'] as String,
          quantity: (item['quantity'] as num).toInt(),
          price: (item['price'] as num).toInt(),
          categoryId: (item['category_id'] as String?) ?? 'gazBallon',
        ),
    ],
    total: row['total'] as int,
    status: SellerOrderStatus.values.firstWhere(
      (s) => s.toOrderStatus == status,
      orElse: () => SellerOrderStatus.yangi,
    ),
    deliveryMethod: row['delivery_method'] == DeliveryMethod.selfPickup.name
        ? DeliveryMethod.selfPickup
        : DeliveryMethod.delivery,
    placedAt: DateTime.parse(row['created_at'] as String).toLocal(),
    address: row['address'] as String?,
  );
}

SellerProfile _sellerFromRow(Map<String, dynamic> row) {
  return SellerProfile(
    id: row['id'] as String,
    // The table doesn't record which app account applied; the signed-in
    // user's own company is linked through `AppUser.sellerId` instead.
    ownerUserId: '',
    ownerName: (row['owner_name'] as String?) ?? '',
    companyName: row['company_name'] as String,
    category: ServiceCategory.values.firstWhere(
      (c) => c.id == row['category'],
      orElse: () => ServiceCategory.gazBallon,
    ),
    description: '',
    district: (row['district'] as String?) ?? '',
    address: (row['address'] as String?) ?? '',
    phone: (row['phone'] as String?) ?? '',
    workingHours: '',
    deliveryFee: 0,
    status: SellerStatus.values.firstWhere(
      (s) => s.name == row['status'],
      orElse: () => SellerStatus.pending,
    ),
    createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
        DateTime.now(),
    rating: (row['rating'] as num?)?.toDouble() ?? 0,
    reviewCount: (row['review_count'] as num?)?.toInt() ?? 0,
  );
}
