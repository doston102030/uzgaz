import 'package:equatable/equatable.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.rating,
    required this.reviewCount,
    required this.isAvailable,
    required this.companyId,
    required this.companyName,
    required this.categoryId,
    this.description,
    this.unit = 'dona',
    this.oldPrice,
    this.isPopular = false,
    this.specs = const {},
  });

  final String id;
  final String name;
  final String imageUrl;
  final int price;
  final double rating;
  final int reviewCount;
  final bool isAvailable;
  final String companyId;
  final String companyName;
  final String categoryId;
  final String? description;
  final String unit;

  /// Pre-discount price; drives the "-N%" badge when higher than [price].
  final int? oldPrice;
  final bool isPopular;

  /// Short key/value facts shown on the detail screen (hajm, material, …).
  final Map<String, String> specs;

  bool get hasDiscount => oldPrice != null && oldPrice! > price;

  int get discountPercent =>
      hasDiscount ? (((oldPrice! - price) / oldPrice!) * 100).round() : 0;

  @override
  List<Object?> get props => [id, name, price, companyId];
}
