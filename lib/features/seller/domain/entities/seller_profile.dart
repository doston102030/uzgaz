import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

/// A seller's company — created via "Men sotuvchiman" registration and
/// held in [SellerStatus.pending] until an admin approves it.
class SellerProfile extends Equatable {
  const SellerProfile({
    required this.id,
    required this.ownerUserId,
    required this.companyName,
    required this.category,
    required this.description,
    required this.address,
    required this.phone,
    required this.workingHours,
    required this.deliveryFee,
    required this.status,
    required this.createdAt,
    this.latitude = 41.311081,
    this.longitude = 69.240562,
    this.rating = 0,
    this.reviewCount = 0,
    this.rejectionReason,
    this.offersDelivery = true,
    this.offersPickup = true,
    this.logoUrl,
    this.ownerName = '',
    this.district = '',
  });

  final String id;
  final String ownerUserId;
  final String companyName;
  final ServiceCategory category;
  final String description;
  final String address;
  final String phone;
  final String workingHours;
  final int deliveryFee;
  final SellerStatus status;
  final DateTime createdAt;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final String? rejectionReason;
  final bool offersDelivery;
  final bool offersPickup;

  /// Public Supabase Storage URL of the company logo (`company-logos`
  /// bucket) — null until the seller uploads one.
  final String? logoUrl;

  /// Owner's full name and Andijon district — what the admin panel lists
  /// next to the company (`sellers.owner_name`, `sellers.district`).
  final String ownerName;
  final String district;

  SellerProfile copyWith({
    SellerStatus? status,
    String? rejectionReason,
    String? logoUrl,
  }) =>
      SellerProfile(
        id: id,
        ownerUserId: ownerUserId,
        companyName: companyName,
        category: category,
        description: description,
        address: address,
        phone: phone,
        workingHours: workingHours,
        deliveryFee: deliveryFee,
        status: status ?? this.status,
        createdAt: createdAt,
        latitude: latitude,
        longitude: longitude,
        rating: rating,
        reviewCount: reviewCount,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        offersDelivery: offersDelivery,
        offersPickup: offersPickup,
        logoUrl: logoUrl ?? this.logoUrl,
        ownerName: ownerName,
        district: district,
      );

  @override
  List<Object?> get props => [id, status];
}
