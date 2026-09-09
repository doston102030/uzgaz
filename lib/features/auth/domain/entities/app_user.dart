import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.phone,
    this.photoUrl,
    this.email,
    this.role = UserRole.buyer,
    this.sellerId,
  });

  final String id;
  final String fullName;
  final String phone;
  final String? photoUrl;
  final String? email;

  final UserRole role;

  /// Set once a buyer's seller application is created — links to
  /// `SellerProfile.id` so the seller shell knows whose data to load.
  final String? sellerId;

  AppUser copyWith({UserRole? role, String? sellerId}) => AppUser(
        id: id,
        fullName: fullName,
        phone: phone,
        photoUrl: photoUrl,
        email: email,
        role: role ?? this.role,
        sellerId: sellerId ?? this.sellerId,
      );

  @override
  List<Object?> get props => [id, phone, role, sellerId];
}
