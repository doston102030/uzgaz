import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/typography.dart';
import 'app_button.dart';
import 'app_surface.dart';
import 'app_tappable.dart';

/// iOS large-title navigation bar as a sliver: the big title sits in the
/// scroll content, collapses into a compact centred title, and the bar
/// turns to frosted glass only once content passes underneath it.
class AppSliverNavBar extends StatelessWidget {
  const AppSliverNavBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.onBack,
    this.actions = const [],
    this.largeTitle = true,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final bool largeTitle;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final largeExtent = largeTitle ? (subtitle != null ? 62.0 : 46.0) : 0.0;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _NavBarDelegate(
        topPadding: topPad,
        largeExtent: largeExtent,
        title: title,
        subtitle: subtitle,
        showBack: showBack,
        onBack: onBack,
        actions: actions,
      ),
    );
  }
}

class _NavBarDelegate extends SliverPersistentHeaderDelegate {
  _NavBarDelegate({
    required this.topPadding,
    required this.largeExtent,
    required this.title,
    required this.subtitle,
    required this.showBack,
    required this.onBack,
    required this.actions,
  });

  final double topPadding;
  final double largeExtent;
  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  double get minExtent => topPadding + AppDimensions.navBarHeight;

  @override
  double get maxExtent => topPadding + AppDimensions.navBarHeight + largeExtent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final c = context.palette;
    final t = largeExtent == 0
        ? 1.0
        : (shrinkOffset / largeExtent).clamp(0.0, 1.0);
    final glass = (shrinkOffset / 12).clamp(0.0, 1.0);

    final bar = SizedBox(
      height: AppDimensions.navBarHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Compact centred title — fades in as the large title leaves.
          Opacity(
            opacity: largeExtent == 0 ? 1 : Curves.easeIn.transform(t),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 64),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.headline.copyWith(color: c.textPrimary),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              if (showBack)
                Padding(
                  padding: const EdgeInsets.only(left: AppDimensions.space12),
                  child: AppIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    iconSize: 16,
                    onTap: onBack ?? () => _pop(context),
                  ),
                )
              else
                const SizedBox(width: AppDimensions.gutter),
              const Spacer(),
              for (final action in actions) ...[
                action,
                const SizedBox(width: AppDimensions.space8),
              ],
              const SizedBox(width: AppDimensions.space12),
            ],
          ),
        ],
      ),
    );

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Frosted glass only once something scrolls under the bar.
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: glass,
                child: GlassPanel(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(height: 1, color: c.separator),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 1 - glass,
                child: ColoredBox(color: c.background),
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(height: topPadding),
              bar,
              if (largeExtent > 0)
                Expanded(
                  child: ClipRect(
                    child: Opacity(
                      opacity: (1 - t * 1.4).clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, -8 * t),
                        // The collapse animation can briefly hand this Column
                        // less height than the title+subtitle need (e.g. the
                        // very first laid-out frame). OverflowBox lets it
                        // measure itself at its natural size instead of
                        // throwing a RenderFlex overflow — the ClipRect
                        // above still trims anything that doesn't fit.
                        child: OverflowBox(
                          alignment: Alignment.topLeft,
                          minHeight: 0,
                          maxHeight: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.gutter),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.title1
                                      .copyWith(color: c.textPrimary),
                                ),
                                if (subtitle != null)
                                  Text(
                                    subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.subhead
                                        .copyWith(color: c.textSecondary),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static void _pop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  bool shouldRebuild(covariant _NavBarDelegate old) =>
      old.title != title ||
      old.subtitle != subtitle ||
      old.topPadding != topPadding ||
      old.largeExtent != largeExtent ||
      old.showBack != showBack ||
      old.actions.length != actions.length;
}

/// A row (filter chips, segmented control) that sticks under the nav bar
/// on frosted glass while the list scrolls beneath it.
class SliverPinnedBar extends StatelessWidget {
  const SliverPinnedBar({
    super.key,
    required this.child,
    required this.height,
  });

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _PinnedBarDelegate(child: child, height: height),
    );
  }
}

class _PinnedBarDelegate extends SliverPersistentHeaderDelegate {
  _PinnedBarDelegate({required this.child, required this.height});

  final Widget child;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final c = context.palette;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (overlapsContent)
            GlassPanel(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(height: 1, color: c.separator),
              ),
            )
          else
            ColoredBox(color: c.background),
          child,
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedBarDelegate old) =>
      old.height != height || old.child != child;
}

/// Section title with an optional trailing action — the rhythm marker
/// between blocks on the home and detail screens.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(
      AppDimensions.gutter,
      AppDimensions.space24,
      AppDimensions.gutter,
      AppDimensions.space12,
    ),
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.title3.copyWith(color: c.textPrimary),
            ),
          ),
          if (actionLabel != null && onAction != null)
            AppTappable(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space4, vertical: AppDimensions.space4),
                child: Row(
                  children: [
                    Text(
                      actionLabel!,
                      style: AppTypography.callout.copyWith(
                        color: c.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 18, color: c.primary),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Fades + lifts its child in once, used to stagger a screen's first paint.
class FadeInUp extends StatelessWidget {
  const FadeInUp({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.slow + delay,
      curve: Interval(
        delay.inMilliseconds / (AppMotion.slow.inMilliseconds + delay.inMilliseconds + 1),
        1,
        curve: AppMotion.enter,
      ),
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 16 * (1 - value)), child: child),
      ),
      child: child,
    );
  }
}
