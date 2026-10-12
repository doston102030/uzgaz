import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../utils/haptics.dart';

class AppTabItem {
  const AppTabItem(this.icon, this.activeIcon, this.label, {this.accent});
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color? accent;
}

/// A quiet floating tab bar shared by the buyer, seller and admin shells.
class AppTabBar extends StatelessWidget {
  const AppTabBar(
      {super.key,
      required this.items,
      required this.currentIndex,
      required this.onTap,
      this.badges = const {}});
  final List<AppTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Map<int, int> badges;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        height: AppDimensions.bottomNavHeight,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: c.border),
          boxShadow: c.shadowSm,
        ),
        child: Row(children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
                child: Semantics(
              button: true,
              selected: i == currentIndex,
              label: items[i].label,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  AppHaptics.selection();
                  onTap(i);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(clipBehavior: Clip.none, children: [
                          Icon(
                              i == currentIndex
                                  ? items[i].activeIcon
                                  : items[i].icon,
                              color: i == currentIndex
                                  ? c.primary
                                  : c.textSecondary,
                              size: 24),
                          if ((badges[i] ?? 0) > 0)
                            Positioned(
                                right: -10,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                      color: c.danger,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                      '${badges[i]! > 99 ? '99+' : badges[i]}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600)),
                                )),
                        ]),
                        const SizedBox(height: 4),
                        Flexible(
                            child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(items[i].label,
                                    maxLines: 1,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: i == currentIndex
                                            ? c.primary
                                            : c.textSecondary,
                                        fontWeight: i == currentIndex
                                            ? FontWeight.w600
                                            : FontWeight.w400)))),
                      ]),
                ),
              ),
            )),
        ]),
      ),
    );
  }
}

/// Buyer shell: Bosh sahifa / Katalog / Buyurtmalar / Xarita / Profil.
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.badges = const {},
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final Map<int, int> badges;

  static const List<AppTabItem> _items = [
    AppTabItem(Icons.home_outlined, Icons.home_rounded, 'Bosh sahifa'),
    AppTabItem(Icons.grid_view_outlined, Icons.grid_view_rounded, 'Katalog',
        accent: AppColors.energyFlame),
    AppTabItem(
        Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Buyurtmalar',
        accent: AppColors.energyElectric),
    AppTabItem(Icons.map_outlined, Icons.map_rounded, 'Xarita',
        accent: AppColors.energyMint),
    AppTabItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profil',
        accent: AppColors.energyRose),
  ];

  @override
  Widget build(BuildContext context) => AppTabBar(
        items: _items,
        currentIndex: currentIndex,
        onTap: onTap,
        badges: badges,
      );
}

/// Seller shell: Kabinet / Mahsulotlar / Buyurtmalar / Hisobot / Profil.
class SellerBottomNavigation extends StatelessWidget {
  const SellerBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.badges = const {},
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final Map<int, int> badges;

  static const List<AppTabItem> _items = [
    AppTabItem(Icons.space_dashboard_outlined, Icons.space_dashboard_rounded,
        'Kabinet'),
    AppTabItem(
        Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Mahsulotlar',
        accent: AppColors.energyFlame),
    AppTabItem(
        Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Buyurtmalar',
        accent: AppColors.energyElectric),
    AppTabItem(Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Hisobot',
        accent: AppColors.energyMint),
    AppTabItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profil',
        accent: AppColors.energyRose),
  ];

  @override
  Widget build(BuildContext context) => AppTabBar(
        items: _items,
        currentIndex: currentIndex,
        onTap: onTap,
        badges: badges,
      );
}

/// Admin shell: Bosh sahifa / Sotuvchilar / Mahsulotlar / Buyurtmalar / Sozlamalar.
class AdminBottomNavigation extends StatelessWidget {
  const AdminBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.badges = const {},
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final Map<int, int> badges;

  static const List<AppTabItem> _items = [
    AppTabItem(
        Icons.dashboard_outlined, Icons.dashboard_rounded, 'Bosh sahifa'),
    AppTabItem(
        Icons.storefront_outlined, Icons.storefront_rounded, 'Sotuvchilar',
        accent: AppColors.energyMint),
    AppTabItem(
        Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Mahsulotlar',
        accent: AppColors.energyFlame),
    AppTabItem(
        Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Buyurtmalar',
        accent: AppColors.energyElectric),
    AppTabItem(Icons.settings_outlined, Icons.settings_rounded, 'Sozlamalar',
        accent: AppColors.energyRose),
  ];

  @override
  Widget build(BuildContext context) => AppTabBar(
        items: _items,
        currentIndex: currentIndex,
        onTap: onTap,
        badges: badges,
      );
}
