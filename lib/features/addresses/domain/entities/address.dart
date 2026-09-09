import 'package:equatable/equatable.dart';

class Address extends Equatable {
  const Address({
    required this.id,
    required this.title,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    this.apartment,
    this.entrance,
    this.floor,
    this.isDefault = false,
  });

  final String id;
  final String title; // "Uy", "Ish", ...
  final String fullAddress;
  final double latitude;
  final double longitude;
  final String? apartment;
  final String? entrance;
  final String? floor;
  final bool isDefault;

  @override
  List<Object?> get props => [id, fullAddress];
}
