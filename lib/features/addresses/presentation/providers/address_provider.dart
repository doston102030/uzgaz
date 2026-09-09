import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/mock_addresses.dart';
import '../../domain/entities/address.dart';

class AddressesNotifier extends StateNotifier<List<Address>> {
  AddressesNotifier() : super(mockAddresses);

  Address add({
    required String title,
    required String fullAddress,
    double? latitude,
    double? longitude,
    String? apartment,
    String? entrance,
    String? floor,
  }) {
    final address = Address(
      id: 'a${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      fullAddress: fullAddress,
      latitude: latitude ?? 41.311081,
      longitude: longitude ?? 69.240562,
      apartment: apartment,
      entrance: entrance,
      floor: floor,
      isDefault: state.isEmpty,
    );
    state = [...state, address];
    return address;
  }

  void remove(String id) => state = state.where((a) => a.id != id).toList();
}

final addressesProvider =
    StateNotifierProvider<AddressesNotifier, List<Address>>((ref) => AddressesNotifier());

/// Currently chosen delivery address. Falls back to the default address
/// so checkout always has something sensible pre-filled.
class SelectedAddressNotifier extends StateNotifier<Address?> {
  SelectedAddressNotifier(this._ref) : super(null);

  final Ref _ref;

  Address? get value {
    if (state != null) return state;
    final list = _ref.read(addressesProvider);
    if (list.isEmpty) return null;
    return list.firstWhere((a) => a.isDefault, orElse: () => list.first);
  }

  void select(Address address) => state = address;
}

final selectedAddressNotifierProvider =
    StateNotifierProvider<SelectedAddressNotifier, Address?>(
  (ref) => SelectedAddressNotifier(ref),
);

final selectedAddressProvider = Provider<Address?>((ref) {
  final explicit = ref.watch(selectedAddressNotifierProvider);
  if (explicit != null) return explicit;
  final list = ref.watch(addressesProvider);
  if (list.isEmpty) return null;
  return list.firstWhere((a) => a.isDefault, orElse: () => list.first);
});
