import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

class OrderItem extends Equatable {
  const OrderItem({
    required this.productName,
    required this.quantity,
    required this.price,
    this.categoryId = 'gazBallon',
    this.productId = '',
  });

  /// Catalogue id at order time — "Takrorlash" puts the same product back
  /// in the cart. Empty for items whose product is unknown.
  final String productId;
  final String productName;
  final int quantity;
  final int price;
  final String categoryId;

  int get subtotal => price * quantity;

  @override
  List<Object?> get props => [productName, quantity, price];
}

class DriverInfo extends Equatable {
  const DriverInfo({
    required this.name,
    required this.phone,
    required this.vehicle,
    required this.photoUrl,
    required this.latitude,
    required this.longitude,
    this.rating = 4.9,
  });

  final String name;
  final String phone;
  final String vehicle;
  final String photoUrl;
  final double latitude;
  final double longitude;
  final double rating;

  @override
  List<Object?> get props => [name, phone];
}

class Order extends Equatable {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.date,
    required this.companyName,
    required this.items,
    required this.total,
    required this.status,
    required this.deliveryMethod,
    this.companyId = '',
    this.driver,
    this.address,
    this.deliveryFee = 0,
    this.etaMinutes = 35,
    this.paymentMethod = PaymentMethod.cashOnDelivery,
  });

  final String id;
  final String orderNumber;
  final DateTime date;
  final String companyName;
  final List<OrderItem> items;
  final int total;
  final OrderStatus status;
  final DeliveryMethod deliveryMethod;

  /// The seller's id (`orders.company_id`) — who fulfils the order.
  final String companyId;
  final DriverInfo? driver;
  final String? address;
  final int deliveryFee;
  final int etaMinutes;
  final PaymentMethod paymentMethod;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  int get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);

  /// "Gaz ballon 50L" or "Gaz ballon 50L +2 mahsulot"
  String get summary => items.isEmpty
      ? ''
      : items.length == 1
          ? items.first.productName
          : '${items.first.productName} +${items.length - 1} mahsulot';

  /// Expected delivery moment, used for the "taxminan 14:20" line.
  DateTime get eta => date.add(Duration(minutes: etaMinutes));

  Order copyWith({
    OrderStatus? status,
    DriverInfo? driver,
    String? address,
    int? etaMinutes,
  }) {
    return Order(
      id: id,
      orderNumber: orderNumber,
      date: date,
      companyName: companyName,
      items: items,
      total: total,
      status: status ?? this.status,
      deliveryMethod: deliveryMethod,
      paymentMethod: paymentMethod,
      companyId: companyId,
      driver: driver ?? this.driver,
      address: address ?? this.address,
      deliveryFee: deliveryFee,
      etaMinutes: etaMinutes ?? this.etaMinutes,
    );
  }

  @override
  List<Object?> get props => [id, status];
}
