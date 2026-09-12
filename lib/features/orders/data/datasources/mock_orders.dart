import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/order.dart';

const DriverInfo mockDriver = DriverInfo(
  name: 'Doston Adhamjonov',
  phone: '+998901234567',
  vehicle: 'Chevrolet Damas · 01 A 234 BC',
  photoUrl: 'assets/images/driver_1.png',
  latitude: 40.7860,
  longitude: 72.3480,
  rating: 4.9,
);

const DriverInfo mockDriver2 = DriverInfo(
  name: 'Sardor Qodirov',
  phone: '+998935557788',
  vehicle: 'Isuzu · 30 B 771 AA',
  photoUrl: 'assets/images/driver_2.png',
  latitude: 40.7790,
  longitude: 72.3510,
  rating: 4.7,
);

final List<Order> mockOrders = [
  Order(
    id: 'o1',
    orderNumber: '#GE234521',
    date: DateTime.now().subtract(const Duration(minutes: 12)),
    companyName: 'Andijon Gaz Ta‘minot',
    items: const [
      OrderItem(productName: 'Gaz ballon 50L', quantity: 1, price: 120000),
    ],
    total: 135000,
    deliveryFee: 15000,
    etaMinutes: 35,
    status: OrderStatus.yolda,
    deliveryMethod: DeliveryMethod.delivery,
    address: 'Andijon shahri, Bog‘ishamol ko‘chasi 12',
    driver: mockDriver,
  ),
  Order(
    id: 'o2',
    orderNumber: '#GE234498',
    date: DateTime.now().subtract(const Duration(days: 2)),
    companyName: 'Andijon GazPlus',
    items: const [
      OrderItem(
        productName: 'Propan ballon 27L',
        quantity: 2,
        price: 62000,
        categoryId: 'propanGaz',
      ),
    ],
    total: 134000,
    deliveryFee: 10000,
    status: OrderStatus.yetkazildi,
    deliveryMethod: DeliveryMethod.delivery,
    address: 'Asaka tumani, Mustaqillik ko‘chasi 24',
    driver: mockDriver2,
  ),
  Order(
    id: 'o3',
    orderNumber: '#GE234410',
    date: DateTime.now().subtract(const Duration(days: 6)),
    companyName: 'Asaka Energiya Servis',
    items: const [
      OrderItem(productName: 'Gaz ballon 25L', quantity: 1, price: 76000),
    ],
    total: 76000,
    status: OrderStatus.yetkazildi,
    deliveryMethod: DeliveryMethod.selfPickup,
  ),
  Order(
    id: 'o4',
    orderNumber: '#GE234377',
    date: DateTime.now().subtract(const Duration(days: 11)),
    companyName: 'Marhamat Sanoat Gaz',
    items: const [
      OrderItem(
        productName: 'Dizel Yevro-5',
        quantity: 40,
        price: 13800,
        categoryId: 'dizel',
      ),
    ],
    total: 552000,
    status: OrderStatus.yetkazildi,
    deliveryMethod: DeliveryMethod.selfPickup,
  ),
];
