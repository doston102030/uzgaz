import 'package:equatable/equatable.dart';

class Company extends Equatable {
  const Company({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.productPrice,
    required this.deliveryFee,
    required this.etaMinutes,
    required this.workingHours,
    required this.isAvailable,
    required this.latitude,
    required this.longitude,
    this.address = '',
    this.phone = '',
    this.tags = const [],
  });

  final String id;
  final String name;
  final String logoUrl;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final int productPrice;
  final int deliveryFee;
  final int etaMinutes;
  final String workingHours;
  final bool isAvailable;
  final double latitude;
  final double longitude;
  final String address;
  final String phone;

  /// Short badges: "24/7", "Sertifikatlangan", "Tez yetkazish".
  final List<String> tags;

  /// What the buyer actually pays — the number worth comparing on.
  int get totalPrice => productPrice + deliveryFee;

  bool get isOpenAllDay => workingHours.contains('24');

  @override
  List<Object?> get props => [id, name];
}

enum CompanySortOption { engYaqin, engArzon, reyting, narx, masofa }

extension CompanySortOptionX on CompanySortOption {
  String get label => switch (this) {
        CompanySortOption.masofa => 'Masofa',
        CompanySortOption.reyting => 'Reyting',
        CompanySortOption.narx => 'Narx',
        CompanySortOption.engYaqin => 'Eng yaqin',
        CompanySortOption.engArzon => 'Eng arzon',
      };
}
