import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/typography.dart';
import 'app_surface.dart';

class AppTabItem {
  const AppTabItem(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Frosted tab bar: content scrolls *under* it, the active icon lifts and
/// tints, and every switch fires a light haptic — iOS to the millimetre.
///
/// Generic so the buyer, seller and admin shells all render the exact
/// same bar with their own item list (see [AppBottomNavigation],
/// [SellerBottomNavigation], [AdminBottomNavigation] below).
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.badges = const {},
  });

  final List<AppTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// index -> count, e.g. `{2: 1}` to flag one active order.
  final Map<int, int> badges;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return GlassPanel(
      opacity: 0.86,
      blur: 28,
      border: Border(top: BorderSide(color: c.separator)),
      child: SizedBox(
        height: AppDimensions.bottomNavHeight + bottomInset,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: i == currentIndex,
                    badge: badges[i],
                    onTap: () {
                      if (i != currentIndex) HapticFeedback.selectionClick();
                      onTap(i);
                    },
                  ),
                ),
            ],
          ),
        ),
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
    AppTabItem(Icons.grid_view_outlined, Icons.grid_view_rounded, 'Katalog'),
    AppTabItem(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Buyurtmalar'),
    AppTabItem(Icons.map_outlined, Icons.map_rounded, 'Xarita'),
    AppTabItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
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
    AppTabItem(Icons.space_dashboard_outlined, Icons.space_dashboard_rounded, 'Kabinet'),
    AppTabItem(Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Mahsulotlar'),
    AppTabItem(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Buyurtmalar'),
    AppTabItem(Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Hisobot'),
    AppTabItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
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
    AppTabItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Bosh sahifa'),
    AppTabItem(Icons.storefront_outlined, Icons.storefront_rounded, 'Sotuvchilar'),
    AppTabItem(Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Mahsulotlar'),
    AppTabItem(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Buyurtmalar'),
    AppTabItem(Icons.settings_outlined, Icons.settings_rounded, 'Sozlamalar'),
  ];

  @override
  Widget build(BuildContext context) => AppTabBar(
        items: _items,
        currentIndex: currentIndex,
        onTap: onTap,
        badges: badges,
      );
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final AppTabItem item;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final color = selected ? c.primary : c.textTertiary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSlide(
            duration: AppMotion.base,
            curve: AppMotion.spring,
            offset: Offset(0, selected ? -0.06 : 0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  duration: AppMotion.base,
                  curve: AppMotion.spring,
                  scale: selected ? 1.06 : 1,
                  child: Icon(
                    selected ? item.activeIcon : item.icon,
                    size: 24,
                    color: color,
                  ),
                ),
                if (badge != null && badge! > 0)
                  Positioned(
                    right: -6,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      constraints: const BoxConstraints(minWidth: 16),
                      height: 16,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.danger,
                        borderRadius: AppDimensions.brPill,
                      ),
                      child: Text(
                        badge! > 9 ? '9+' : '$badge',
                        style: AppTypography.caption2.copyWith(
                          color: Colors.white,
                          fontSize: 9.5,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: AppMotion.fast,
            style: AppTypography.caption2.copyWith(
              color: color,
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
