import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/app_user.dart';

/// Auth state placeholder. Wire this up to Firebase Auth in Phase 9 —
/// for now it drives the Splash → Onboarding/Login → Home redirect logic
/// with a simple mock sign-in, and carries the [UserRole] the router
/// uses to pick the buyer / seller / admin shell.
class AuthNotifier extends StateNotifier<AppUser?> {
  AuthNotifier() : super(null);

  Future<void> signInWithPhone(String phone) async {
    await Future.delayed(const Duration(milliseconds: 600));
    state = AppUser(id: 'u1', fullName: 'Doston Adhamjonov', phone: phone);
  }

  Future<void> register({required String fullName, required String phone}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    state = AppUser(id: 'u1', fullName: fullName, phone: phone);
  }

  /// Demo-only entry point for the admin shell (mirrors what a real build
  /// would gate behind a Firebase custom claim / Firestore role field).
  Future<void> signInAsAdmin() async {
    await Future.delayed(const Duration(milliseconds: 500));
    state = const AppUser(
      id: 'admin1',
      fullName: 'Admin',
      phone: '+998712000000',
      role: UserRole.admin,
    );
  }

  /// "Men sotuvchiman" — promotes the signed-in buyer once their company
  /// application is submitted; [SellerNotifier.apply] calls this with the
  /// new [SellerProfile.id].
  void linkSeller(String sellerId) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(role: UserRole.seller, sellerId: sellerId);
  }

  /// Lets a seller (or admin) step back into the buyer app without
  /// signing out — the company/admin access stays linked for next time.
  void switchToBuyer() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(role: UserRole.buyer);
  }

  void signOut() => state = null;

  bool get isAuthenticated => state != null;
}

final authProvider = StateNotifierProvider<AuthNotifier, AppUser?>((ref) => AuthNotifier());

final onboardingSeenProvider = StateProvider<bool>((ref) => false);

/// Convenience read used throughout the router and shells.
final userRoleProvider = Provider<UserRole>((ref) {
  return ref.watch(authProvider)?.role ?? UserRole.buyer;
});
