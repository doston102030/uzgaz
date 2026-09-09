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

  SellerProfile copyWith({
    SellerStatus? status,
    String? rejectionReason,
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
      );

  @override
  List<Object?> get props => [id, status];
}
