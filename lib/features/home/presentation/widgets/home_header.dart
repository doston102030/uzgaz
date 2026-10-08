import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_tappable.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../cart/presentation/providers/cart_provider.dart';

/// Storefront-style home header: support call on the left, the Alanga
/// logo in the middle, notifications and the cart on the right, and a
/// plain filled search field underneath. Bare icons and no borders, so
/// the logo is the one thing that draws the eye.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.space8,
        topPad + AppDimensions.space8,
        AppDimensions.space8,
        AppDimensions.space12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 56,
            child: Row(
              children: [
                // As wide as the pair on the right, so the logo stays
                // centred on the screen rather than in the leftover space.
                SizedBox(
                  width: _BareIconButton.width * 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _BareIconButton(
                      icon: Icons.phone_outlined,
                      label:
                          'Qo‘llab-quvvatlash: ${AppConstants.supportPhone}',
                      onTap: () => launchUrl(Uri.parse(
                        'tel:${AppConstants.supportPhone.replaceAll(' ', '')}',
                      )),
                    ),
                  ),
                ),
                const Expanded(child: Center(child: _AlangaLogo())),
                _BareIconButton(
                  icon: Icons.notifications_none_rounded,
                  label: 'Bildirishnomalar',
                  onTap: () => CustomDialog.info(
                    context,
                    title: 'Bildirishnomalar',
                    message: 'Yangi bildirishnomalar bu yerda ko‘rinadi. '
                        'Buyurtma holati o‘zgarganda sizga darhol xabar '
                        'beramiz.',
                    icon: Icons.notifications_active_rounded,
                  ),
                ),
                const _CartButton(),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space12),
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.gutter - AppDimensions.space8,
            ),
            child: _SearchField(),
          ),
        ],
      ),
    );
  }
}

/// Horizontal lockup cut from `alanga_logo.png`: the flame emblem next to
/// the wordmark. Dark mode swaps in silver versions of the navy parts.
class _AlangaLogo extends StatelessWidget {
  const _AlangaLogo();

  // Pixel sizes of the asset files, for the aspect ratios.
  static const _markAspect = 191 / 168;
  static const _wordmarkAspect = 414 / 132;

  static const _markHeight = 46.0;
  static const _wordmarkHeight = 33.0;

  @override
  Widget build(BuildContext context) {
    final suffix = context.palette.isDark ? '_dark' : '';
    return Semantics(
      label: 'Alanga',
      image: true,
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/alanga_mark$suffix.png',
              height: _markHeight,
              width: _markHeight * _markAspect,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
            ),
            const SizedBox(width: 5),
            Padding(
              // The wordmark sits on the ring's baseline, not mid-flame.
              padding: const EdgeInsets.only(top: 10),
              child: Image.asset(
                'assets/images/alanga_wordmark$suffix.png',
                height: _wordmarkHeight,
                width: _wordmarkHeight * _wordmarkAspect,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BareIconButton extends StatelessWidget {
  const _BareIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
  });

  static const double width = 46;

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final animate = !MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: AppTappable(
        onTap: onTap,
        pressedScale: 0.88,
        child: SizedBox(
          width: width,
          height: 48,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 27, color: c.textPrimary),
              // Anchored by its left edge on the glyph's shoulder, so a
              // wider "9+" grows outwards instead of over the icon.
              Positioned(
                left: width / 2 + 2,
                top: 5,
                child: AnimatedSwitcher(
                  duration: animate ? AppMotion.slow : Duration.zero,
                  reverseDuration: animate ? AppMotion.fast : Duration.zero,
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: AppMotion.spring,
                      reverseCurve: AppMotion.exit,
                    ),
                    child: child,
                  ),
                  child: badgeCount > 0
                      ? _CountBadge(
                          key: ValueKey(badgeCount),
                          count: badgeCount,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the cart; the badge shows how many items are in it and pops
/// each time one is added.
class _CartButton extends ConsumerWidget {
  const _CartButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider);
    return _BareIconButton(
      icon: Icons.shopping_bag_outlined,
      label: count > 0 ? 'Savat, $count ta mahsulot' : 'Savat',
      badgeCount: count,
      onTap: () => context.push('/cart'),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      height: 19,
      constraints: const BoxConstraints(minWidth: 19),
      padding: const EdgeInsets.symmetric(horizontal: 4.5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.danger,
        borderRadius: AppDimensions.brPill,
        // Page-coloured ring, so the badge reads as cut into the glyph.
        border: Border.all(color: c.background, width: 2),
      ),
      child: Text(
        // Same cap as the dock's badges; keeps it inside the screen edge.
        count > 9 ? '9+' : '$count',
        style: AppTypography.caption2.copyWith(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

/// Filled, borderless search field — opens the catalog.
class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Semantics(
      button: true,
      label: 'Mahsulotlarni qidirish',
      excludeSemantics: true,
      child: AppTappable(
        onTap: () => context.go('/catalog'),
        pressedScale: 0.985,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: c.isDark ? c.surfaceMuted : const Color(0xFFECEFF4),
            borderRadius: AppDimensions.brSmall,
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 25, color: c.textTertiary),
              const SizedBox(width: AppDimensions.space10),
              Expanded(
                child: Text(
                  'Mahsulotlarni qidirish',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(color: c.textTertiary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
