import '../../../../core/constants/app_constants.dart';
import '../../../orders/domain/entities/order.dart';
import '../../domain/entities/seller_order.dart';
import '../../domain/entities/seller_product.dart';
import '../../domain/entities/seller_profile.dart';

const _catalogBase =
    'https://haurszcvivpqdyenfwbb.supabase.co/storage/v1/object/public/product-images/catalog';

/// One already-approved demo seller ("UzGaz Servis", owned by the mock
/// buyer u1) so the seller shell has real data to show the moment the
/// role is switched, without requiring the registration flow first.
final List<SellerProfile> mockSellerProfiles = [
  SellerProfile(
    id: 's1',
    ownerUserId: 'u1',
    companyName: 'UzGaz Servis',
    category: ServiceCategory.gazBallon,
    description: '50 va 25 litrlik gaz ballonlari, tez yetkazib berish bilan.',
    address: 'Yunusobod tumani, Amir Temur shoh ko‘chasi 108',
    phone: '+998712001010',
    workingHours: '08:00 - 22:00',
    deliveryFee: 15000,
    status: SellerStatus.approved,
    createdAt: DateTime.now().subtract(const Duration(days: 40)),
    rating: 4.8,
    reviewCount: 214,
  ),
];

final List<SellerProduct> mockSellerProducts = [
  SellerProduct(
    id: 'sp1',
    sellerId: 's1',
    name: 'Gaz ballon 50L',
    category: ServiceCategory.gazBallon,
    description: '50 litrlik po‘lat gaz ballon, uy va tijorat ehtiyojlari uchun.',
    price: 120000,
    oldPrice: 135000,
    stockQty: 34,
    moderationStatus: ProductModerationStatus.approved,
    createdAt: DateTime.now().subtract(const Duration(days: 38)),
    imageUrl: '$_catalogBase/gazBallon.jpg',
  ),
  SellerProduct(
    id: 'sp2',
    sellerId: 's1',
    name: 'Gaz ballon 25L',
    category: ServiceCategory.gazBallon,
    description: 'Kichik uy xo‘jaligi uchun qulay 25 litrlik ballon.',
    price: 76000,
    stockQty: 18,
    moderationStatus: ProductModerationStatus.approved,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    imageUrl: '$_catalogBase/gazBallon.jpg',
  ),
  SellerProduct(
    id: 'sp3',
    sellerId: 's1',
    name: 'Gaz reduktori (yangi)',
    category: ServiceCategory.market,
    description: 'Ballon uchun bosim reduktori, manometr bilan.',
    price: 98000,
    stockQty: 12,
    moderationStatus: ProductModerationStatus.pending,
    createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    imageUrl: '$_catalogBase/market.jpg',
  ),
  SellerProduct(
    id: 'sp4',
    sellerId: 's1',
    name: 'Metan konvertori',
    category: ServiceCategory.metanGaz,
    description: 'Avtomobilga o‘rnatiladigan metan gaz konvertori to‘plami.',
    price: 3200000,
    stockQty: 3,
    moderationStatus: ProductModerationStatus.rejected,
    rejectionReason: 'Mahsulot rasmiga texnik xavfsizlik sertifikati biriktirilmagan.',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    imageUrl: '$_catalogBase/metanGaz.jpg',
  ),
];

final List<SellerOrder> mockSellerOrders = [
  SellerOrder(
    id: 'so1',
    orderNumber: '#GE234701',
    sellerId: 's1',
    buyerName: 'Nodira Yusupova',
    buyerPhone: '+998901112233',
    items: const [OrderItem(productName: 'Gaz ballon 50L', quantity: 1, price: 120000)],
    total: 135000,
    status: SellerOrderStatus.yangi,
    deliveryMethod: DeliveryMethod.delivery,
    placedAt: DateTime.now().subtract(const Duration(minutes: 8)),
    address: 'Toshkent, Mirzo Ulug‘bek tumani, 12-mavze',
  ),
  SellerOrder(
    id: 'so2',
    orderNumber: '#GE234690',
    sellerId: 's1',
    buyerName: 'Aziz Karimov',
    buyerPhone: '+998933334455',
    items: const [OrderItem(productName: 'Gaz ballon 25L', quantity: 2, price: 76000)],
    total: 152000,
    status: SellerOrderStatus.tayyorlanmoqda,
    deliveryMethod: DeliveryMethod.delivery,
    placedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
    address: 'Toshkent, Chilonzor tumani, 19-kvartal',
  ),
  SellerOrder(
    id: 'so3',
    orderNumber: '#GE234655',
    sellerId: 's1',
    buyerName: 'Malika Tosheva',
    buyerPhone: '+998971234567',
    items: const [OrderItem(productName: 'Gaz ballon 50L', quantity: 1, price: 120000)],
    total: 120000,
    status: SellerOrderStatus.yetkazishga,
    deliveryMethod: DeliveryMethod.selfPickup,
    placedAt: DateTime.now().subtract(const Duration(hours: 4)),
  ),
  SellerOrder(
    id: 'so4',
    orderNumber: '#GE234512',
    sellerId: 's1',
    buyerName: 'Bekzod Rashidov',
    buyerPhone: '+998909998877',
    items: const [OrderItem(productName: 'Gaz ballon 25L', quantity: 3, price: 76000)],
    total: 228000,
    status: SellerOrderStatus.yopildi,
    deliveryMethod: DeliveryMethod.delivery,
    placedAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    address: 'Toshkent, Yashnobod tumani, 4-uy',
  ),
  SellerOrder(
    id: 'so5',
    orderNumber: '#GE234488',
    sellerId: 's1',
    buyerName: 'Shahnoza Alieva',
    buyerPhone: '+998955556677',
    items: const [OrderItem(productName: 'Gaz ballon 50L', quantity: 2, price: 120000)],
    total: 240000,
    status: SellerOrderStatus.yopildi,
    deliveryMethod: DeliveryMethod.selfPickup,
    placedAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
];
