import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gaz_energiya/app/app.dart';
import 'package:gaz_energiya/app/theme/app_theme.dart';
import 'package:gaz_energiya/features/addresses/presentation/pages/address_page.dart';
import 'package:gaz_energiya/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:gaz_energiya/features/admin/presentation/pages/admin_orders_page.dart';
import 'package:gaz_energiya/features/admin/presentation/pages/admin_products_page.dart';
import 'package:gaz_energiya/features/admin/presentation/pages/admin_sellers_page.dart';
import 'package:gaz_energiya/features/admin/presentation/pages/admin_settings_page.dart';
import 'package:gaz_energiya/core/constants/app_constants.dart';
import 'package:gaz_energiya/features/auth/presentation/pages/login_page.dart';
import 'package:gaz_energiya/features/auth/presentation/pages/onboarding_page.dart';
import 'package:gaz_energiya/features/auth/presentation/pages/register_page.dart';
import 'package:gaz_energiya/features/auth/presentation/providers/auth_provider.dart';
import 'package:gaz_energiya/features/cart/presentation/pages/cart_page.dart';
import 'package:gaz_energiya/features/cart/presentation/providers/cart_provider.dart';
import 'package:gaz_energiya/features/catalog/presentation/pages/catalog_page.dart';
import 'package:gaz_energiya/features/checkout/presentation/pages/checkout_page.dart';
import 'package:gaz_energiya/features/checkout/presentation/pages/delivery_method_page.dart';
import 'package:gaz_energiya/features/companies/presentation/pages/company_list_page.dart';
import 'package:gaz_energiya/features/home/presentation/pages/home_page.dart';
import 'package:gaz_energiya/features/map/presentation/pages/map_page.dart';
import 'package:gaz_energiya/features/orders/presentation/pages/order_confirmation_page.dart';
import 'package:gaz_energiya/features/orders/presentation/pages/order_history_page.dart';
import 'package:gaz_energiya/features/payment/presentation/pages/payment_page.dart';
import 'package:gaz_energiya/features/products/data/datasources/mock_products.dart';
import 'package:gaz_energiya/features/products/presentation/pages/product_detail_page.dart';
import 'package:gaz_energiya/features/profile/presentation/pages/profile_page.dart';
import 'package:gaz_energiya/features/seller/presentation/pages/add_edit_product_page.dart';
import 'package:gaz_energiya/features/seller/presentation/pages/become_seller_page.dart';
import 'package:gaz_energiya/features/seller/presentation/pages/seller_dashboard_page.dart';
import 'package:gaz_energiya/features/seller/presentation/pages/seller_orders_page.dart';
import 'package:gaz_energiya/features/seller/presentation/pages/seller_pending_page.dart';
import 'package:gaz_energiya/features/seller/presentation/pages/seller_products_page.dart';
import 'package:gaz_energiya/features/seller/presentation/pages/seller_profile_tab_page.dart';
import 'package:gaz_energiya/features/seller/presentation/pages/seller_registration_page.dart';
import 'package:gaz_energiya/features/seller/presentation/pages/seller_reports_page.dart';
import 'package:gaz_energiya/features/seller/presentation/providers/seller_provider.dart';
import 'package:gaz_energiya/features/services/presentation/pages/electric_charging_page.dart';
import 'package:gaz_energiya/features/tracking/presentation/pages/order_tracking_page.dart';

/// Wraps a screen in just enough app scaffolding (theme + Riverpod) to
/// render it in isolation, in both light and dark mode.
Widget _host(Widget child, {ThemeMode mode = ThemeMode.light}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      home: child,
    ),
  );
}

void main() {
  testWidgets('App boots and renders', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GazEnergiyaApp()));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  final screens = <String, Widget Function()>{
    'Onboarding': () => const OnboardingPage(),
    'Login': () => const LoginPage(),
    'Home': () => const HomePage(),
    'Catalog': () => const CatalogPage(),
    'Product detail': () => ProductDetailPage(productId: mockProducts.first.id),
    'Companies': () => const CompanyListPage(),
    'Map': () => const MapPage(),
    'Addresses': () => const AddressPage(),
    'Cart (empty)': () => const CartPage(),
    'Delivery method': () => const DeliveryMethodPage(),
    'Checkout': () => const CheckoutPage(),
    'Payment': () => const PaymentPage(),
    'Order confirmation': () => const OrderConfirmationPage(),
    'Order history': () => const OrderHistoryPage(),
    'Tracking': () => const OrderTrackingPage(orderId: 'o1'),
    'Profile': () => const ProfilePage(),
    'Services': () => const ElectricChargingPage(),
    'Register': () => const RegisterPage(),
    'Become seller': () => const BecomeSellerPage(),
    'Seller registration': () => const SellerRegistrationPage(),
    'Seller pending (no company)': () => const SellerPendingPage(),
    'Seller products (empty)': () => const SellerProductsPage(),
    'Seller orders (empty)': () => const SellerOrdersPage(),
    'Seller reports (empty)': () => const SellerReportsPage(),
    'Seller profile tab (empty)': () => const SellerProfileTabPage(),
    'Add product': () => const AddEditProductPage(),
    'Admin dashboard': () => const AdminDashboardPage(),
    'Admin sellers': () => const AdminSellersPage(),
    'Admin products': () => const AdminProductsPage(),
    'Admin orders': () => const AdminOrdersPage(),
    'Admin settings': () => const AdminSettingsPage(),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} renders in light and dark', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        await tester.pumpWidget(_host(entry.value(), mode: mode));
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('Cart shows items, totals and quantity stepping', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(cartProvider.notifier).add(mockProducts.first);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light, home: const CartPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(mockProducts.first.name), findsOneWidget);
    expect(find.text('Jami'), findsOneWidget);

    container.read(cartProvider.notifier).increment(mockProducts.first.id);
    await tester.pump(const Duration(milliseconds: 400));
    expect(container.read(cartCountProvider), 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Approved seller sees its own dashboard, products, orders and reports',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    // u1 is the mock buyer created by signInWithPhone; s1 ("UzGaz Servis")
    // is the pre-seeded, already-approved demo company owned by u1 — this
    // exercises the full seller shell without going through registration.
    // signInWithPhone has a mock `Future.delayed` inside it — awaiting it
    // directly would hang forever under the fake-async test clock, so it
    // runs in a real async zone via `runAsync`.
    await tester.runAsync(
      () => container.read(authProvider.notifier).signInWithPhone('+998901234567'),
    );
    container.read(authProvider.notifier).linkSeller('s1');

    expect(container.read(currentSellerProvider)?.companyName, 'UzGaz Servis');

    for (final page in [
      const SellerDashboardPage(),
      const SellerProductsPage(),
      const SellerOrdersPage(),
      const SellerReportsPage(),
      const SellerProfileTabPage(),
    ]) {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(theme: AppTheme.light, home: page),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: '${page.runtimeType} threw');
    }

    expect(find.text('UzGaz Servis'), findsWidgets);
  });

  testWidgets('Admin can see and act on the seller/product approval queues',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(authProvider.notifier).signInAsAdmin());

    for (final page in [
      const AdminDashboardPage(),
      const AdminSellersPage(),
      const AdminProductsPage(),
      const AdminOrdersPage(),
      const AdminSettingsPage(),
    ]) {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(theme: AppTheme.light, home: page),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: '${page.runtimeType} threw');
    }

    // Submit a fresh application and approve it from the moderation queue —
    // the real admin → seller handoff the "Sotuvchilar" tab exists for.
    final applied = container.read(sellerProfilesProvider.notifier).apply(
          ownerUserId: 'u2',
          companyName: 'Test Gaz MChJ',
          category: ServiceCategory.propanGaz,
          description: 'Test uchun qo‘shilgan firma',
          address: 'Toshkent',
          phone: '+998900000000',
          workingHours: '09:00 - 18:00',
          deliveryFee: 10000,
          offersDelivery: true,
          offersPickup: true,
        );
    expect(container.read(pendingSellersProvider).map((s) => s.id), contains(applied.id));

    container.read(sellerProfilesProvider.notifier).approve(applied.id);
    expect(container.read(pendingSellersProvider).map((s) => s.id), isNot(contains(applied.id)));
  });
}
