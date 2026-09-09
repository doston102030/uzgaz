import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../orders/domain/entities/order.dart';

/// An incoming order as seen from the seller's side — same line items as
/// the buyer-side [Order], plus the buyer's contact and the seller-only
/// fulfilment status ([SellerOrderStatus]).
class SellerOrder extends Equatable {
  const SellerOrder({
    required this.id,
    required this.orderNumber,
    required this.sellerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.items,
    required this.total,
    required this.status,
    required this.deliveryMethod,
    required this.placedAt,
    this.address,
  });

  final String id;
  final String orderNumber;
  final String sellerId;
  final String buyerName;
  final String buyerPhone;
  final List<OrderItem> items;
  final int total;
  final SellerOrderStatus status;
  final DeliveryMethod deliveryMethod;
  final DateTime placedAt;
  final String? address;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get summary => items.isEmpty
      ? ''
      : items.length == 1
          ? items.first.productName
          : '${items.first.productName} +${items.length - 1} mahsulot';

  SellerOrder copyWith({SellerOrderStatus? status}) => SellerOrder(
        id: id,
        orderNumber: orderNumber,
        sellerId: sellerId,
        buyerName: buyerName,
        buyerPhone: buyerPhone,
        items: items,
        total: total,
        status: status ?? this.status,
        deliveryMethod: deliveryMethod,
        placedAt: placedAt,
        address: address,
      );

  @override
  List<Object?> get props => [id, status];
}
