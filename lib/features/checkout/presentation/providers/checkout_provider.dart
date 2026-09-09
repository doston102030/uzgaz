import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../addresses/presentation/providers/address_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../companies/domain/entities/company.dart';
import '../../../companies/presentation/providers/company_provider.dart';
import '../../../orders/domain/entities/order.dart';

/// Which company will fulfil the order. Defaults to the best-value one so
/// checkout is never blocked on a choice the user has not made yet.
final selectedCompanyProvider = StateProvider<Company?>((ref) => null);

final effectiveCompanyProvider = Provider<Company>((ref) {
  final selected = ref.watch(selectedCompanyProvider);
  if (selected != null) return selected;
  final companies = ref.watch(sortedCompaniesProvider);
  return companies.firstWhere(
    (c) => c.isAvailable,
    orElse: () => companies.first,
  );
});

final deliveryMethodProvider =
    StateProvider<DeliveryMethod>((ref) => DeliveryMethod.delivery);

/// Self-pickup is free — the rule that makes the two options meaningfully
/// different rather than cosmetic.
final deliveryFeeProvider = Provider<int>((ref) {
  final method = ref.watch(deliveryMethodProvider);
  if (method == DeliveryMethod.selfPickup) return 0;
  return ref.watch(effectiveCompanyProvider).deliveryFee;
});

final orderTotalProvider = Provider<int>((ref) {
  return ref.watch(cartTotalProvider) + ref.watch(deliveryFeeProvider);
});

final paymentMethodProvider =
    StateProvider<PaymentMethod>((ref) => PaymentMethod.payme);

/// The order produced by the last successful checkout — read by the
/// confirmation screen so it can deep-link straight into tracking.
final lastOrderProvider = StateProvider<Order?>((ref) => null);

/// Delivery address resolved for the current order, or `null` for pickup.
final checkoutAddressProvider = Provider<String?>((ref) {
  final method = ref.watch(deliveryMethodProvider);
  if (method == DeliveryMethod.selfPickup) {
    return ref.watch(effectiveCompanyProvider).name;
  }
  return ref.watch(selectedAddressProvider)?.fullAddress;
});
