import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/bottom_navigation.dart';
import '../../core/widgets/empty_state.dart';
import '../../features/addresses/presentation/pages/address_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/admin_orders_page.dart';
import '../../features/admin/presentation/pages/admin_products_page.dart';
import '../../features/admin/presentation/pages/admin_sellers_page.dart';
import '../../features/admin/presentation/pages/admin_settings_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/catalog/presentation/pages/catalog_page.dart';
import '../../features/checkout/presentation/pages/checkout_page.dart';
import '../../features/checkout/presentation/pages/delivery_method_page.dart';
import '../../features/companies/domain/entities/company.dart';
import '../../features/companies/presentation/pages/company_list_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/map/presentation/pages/map_page.dart';
import '../../features/orders/presentation/pages/order_confirmation_page.dart';
import '../../features/orders/presentation/pages/order_history_page.dart';
import '../../features/orders/presentation/providers/order_provider.dart';
import '../../features/payment/presentation/pages/payment_page.dart';
import '../../features/products/presentation/pages/product_detail_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/seller/presentation/pages/add_edit_product_page.dart';
import '../../features/seller/presentation/pages/become_seller_page.dart';
import '../../features/seller/presentation/pages/seller_dashboard_page.dart';
import '../../features/seller/presentation/pages/seller_orders_page.dart';
import '../../features/seller/presentation/pages/seller_pending_page.dart';
import '../../features/seller/presentation/pages/seller_products_page.dart';
import '../../features/seller/presentation/pages/seller_profile_tab_page.dart';
import '../../features/seller/presentation/pages/seller_registration_page.dart';
import '../../features/seller/presentation/pages/seller_reports_page.dart';
import '../../features/seller/presentation/providers/seller_provider.dart';
import '../../features/services/presentation/pages/electric_charging_page.dart';
import '../../features/tracking/presentation/pages/order_tracking_page.dart';
import '../theme/motion.dart';

/// Root navigator key so pushed screens (product detail, checkout, …)
/// cover the whole screen instead of just the tab body.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Fade-through page used for the auth flow, where a horizontal push
/// would imply a hierarchy that is not there.
CustomTransitionPage<T> _fadePage<T>(Widget child, GoRouterState state) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.slow,
    reverseTransitionDuration: AppMotion.base,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: AppMotion.enter);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => _fadePage(const SplashPage(), state),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => _fadePage(const OnboardingPage(), state),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _fadePage(const LoginPage(), state),
    ),
    GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),

    // ── Buyer shell: Bosh sahifa / Katalog / Buyurtmalar / Xarita / Profil ──
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _RootShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomePage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/catalog', builder: (context, state) => const CatalogPage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/orders', builder: (context, state) => const OrderHistoryPage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/map', builder: (context, state) => const MapPage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
        ]),
      ],
    ),

    // ── Seller shell: Kabinet / Mahsulotlar / Buyurtmalar / Hisobot / Profil ──
    // Gated by [_SellerShell]: shows the registration pitch, the pending/
    // rejected notice, or the real dashboard — same routes, reactive state.
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _SellerShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/seller/dashboard', builder: (context, state) => const SellerDashboardPage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/seller/products', builder: (context, state) => const SellerProductsPage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/seller/orders', builder: (context, state) => const SellerOrdersPage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/seller/reports', builder: (context, state) => const SellerReportsPage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/seller/profile', builder: (context, state) => const SellerProfileTabPage()),
        ]),
      ],
    ),

    // ── Admin shell: Bosh sahifa / Sotuvchilar / Mahsulotlar / Buyurtmalar / Sozlamalar ──
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _AdminShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/admin/dashboard', builder: (context, state) => const AdminDashboardPage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/admin/sellers', builder: (context, state) => const AdminSellersPage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/admin/products', builder: (context, state) => const AdminProductsPage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/admin/orders', builder: (context, state) => const AdminOrdersPage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/admin/settings', builder: (context, state) => const AdminSettingsPage()),
        ]),
      ],
    ),

    // Seller onboarding — pushed full-screen on the root navigator so it
    // sits above whichever shell (buyer or seller) the user came from.
    GoRoute(
      path: '/seller/start',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BecomeSellerPage(),
    ),
    GoRoute(
      path: '/seller/register',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SellerRegistrationPage(),
    ),
    GoRoute(
      path: '/seller/pending',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SellerPendingPage(),
    ),
    GoRoute(
      path: '/seller/products/add',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddEditProductPage(),
    ),
    GoRoute(
      path: '/seller/products/:id/edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          AddEditProductPage(productId: state.pathParameters['id']),
    ),

    // Full-screen pushed routes (outside the bottom-nav shell)
    GoRoute(
      path: '/services',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ElectricChargingPage(),
    ),
    GoRoute(
      path: '/product/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          ProductDetailPage(productId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/companies',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => CompanyListPage(
        productName: state.uri.queryParameters['product'],
      ),
    ),
    GoRoute(
      path: '/delivery-method',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => DeliveryMethodPage(company: state.extra as Company?),
    ),
    GoRoute(
      path: '/addresses',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => AddressPage(
        continueTo: state.uri.queryParameters['next'],
      ),
    ),
    GoRoute(
      path: '/cart',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CartPage(),
    ),
    GoRoute(
      path: '/checkout',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CheckoutPage(),
    ),
    GoRoute(
      path: '/payment',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PaymentPage(),
    ),
    GoRoute(
      path: '/order-confirmation',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _fadePage(const OrderConfirmationPage(), state),
    ),
    GoRoute(
      path: '/orders/:id/tracking',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          OrderTrackingPage(orderId: state.pathParameters['id']!),
    ),
  ],
);

class _RootShell extends ConsumerWidget {
  const _RootShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrders = ref.watch(activeOrdersProvider).length;

    return Scaffold(
      // Content scrolls under the frosted tab bar.
      extendBody: true,
      body: shell,
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: shell.currentIndex,
        badges: {if (activeOrders > 0) 2: activeOrders},
        onTap: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
      ),
    );
  }
}

/// Gate in front of the seller tab bar: renders the real dashboard only
/// once the signed-in user owns an [SellerStatus.approved] company —
/// otherwise it shows the matching notice, full-screen, no tabs.
class _SellerShell extends ConsumerWidget {
  const _SellerShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seller = ref.watch(currentSellerProvider);

    if (seller == null) {
      return Scaffold(
        body: SafeArea(
          child: EmptyState(
            icon: Icons.storefront_outlined,
            title: 'Sotuvchi profili topilmadi',
            subtitle: 'Davom etish uchun firmangizni ro‘yxatdan o‘tkazing.',
            actionLabel: 'Sotuvchi bo‘lish',
            onAction: () => context.go('/seller/start'),
          ),
        ),
      );
    }

    if (seller.status != SellerStatus.approved) {
      return const SellerPendingPage();
    }

    final newOrders = ref.watch(newSellerOrdersProvider).length;

    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: SellerBottomNavigation(
        currentIndex: shell.currentIndex,
        badges: {if (newOrders > 0) 2: newOrders},
        onTap: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
      ),
    );
  }
}

/// Gate in front of the admin tab bar — only [UserRole.admin] gets past it.
class _AdminShell extends ConsumerWidget {
  const _AdminShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);

    if (role != UserRole.admin) {
      return Scaffold(
        body: SafeArea(
          child: EmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Kirish taqiqlangan',
            subtitle: 'Bu bo‘lim faqat administratorlar uchun.',
            actionLabel: 'Bosh sahifaga qaytish',
            onAction: () => context.go('/home'),
          ),
        ),
      );
    }

    final pendingSellers = ref.watch(pendingSellersProvider).length;
    final pendingProducts = ref.watch(pendingProductsProvider).length;

    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: AdminBottomNavigation(
        currentIndex: shell.currentIndex,
        badges: {
          if (pendingSellers > 0) 1: pendingSellers,
          if (pendingProducts > 0) 2: pendingProducts,
        },
        onTap: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
      ),
    );
  }
}
