import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

/// A product as managed from the seller's side — same catalogue data the
/// buyer sees, plus the stock and moderation fields only a seller/admin
/// needs.
class SellerProduct extends Equatable {
  const SellerProduct({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.stockQty,
    required this.moderationStatus,
    required this.createdAt,
    this.unit = 'dona',
    this.oldPrice,
    this.rejectionReason,
    this.imageUrl,
  });

  final String id;
  final String sellerId;
  final String name;
  final ServiceCategory category;
  final String description;
  final int price;
  final int stockQty;
  final ProductModerationStatus moderationStatus;
  final DateTime createdAt;
  final String unit;
  final int? oldPrice;
  final String? rejectionReason;

  /// Public Supabase Storage URL of the product photo (`product-images`
  /// bucket) — null until the seller uploads one.
  final String? imageUrl;

  bool get isInStock => stockQty > 0;
  bool get isLive => moderationStatus == ProductModerationStatus.approved && isInStock;

  SellerProduct copyWith({
    String? name,
    ServiceCategory? category,
    String? description,
    int? price,
    int? stockQty,
    ProductModerationStatus? moderationStatus,
    String? unit,
    int? oldPrice,
    String? rejectionReason,
    String? imageUrl,
  }) =>
      SellerProduct(
        id: id,
        sellerId: sellerId,
        name: name ?? this.name,
        category: category ?? this.category,
        description: description ?? this.description,
        price: price ?? this.price,
        stockQty: stockQty ?? this.stockQty,
        moderationStatus: moderationStatus ?? this.moderationStatus,
        createdAt: createdAt,
        unit: unit ?? this.unit,
        oldPrice: oldPrice ?? this.oldPrice,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        imageUrl: imageUrl ?? this.imageUrl,
      );

  @override
  List<Object?> get props => [id, sellerId, moderationStatus, stockQty];
}
