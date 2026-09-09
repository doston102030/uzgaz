import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/motion.dart';
import 'app_tappable.dart';

enum AppElevation { none, sm, md, lg }

/// The single card primitive every surface in the app is built from —
/// consistent radius, hairline border, soft layered shadow, and iOS press
/// feedback when it is tappable.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppDimensions.space16),
    this.margin,
    this.radius = AppDimensions.radiusLarge,
    this.elevation = AppElevation.sm,
    this.color,
    this.gradient,
    this.borderColor,
    this.borderWidth,
    this.selected = false,
    this.width,
    this.height,
    this.clip = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final AppElevation elevation;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final double? borderWidth;
  final bool selected;
  final double? width;
  final double? height;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;

    final shadows = switch (elevation) {
      AppElevation.none => const <BoxShadow>[],
      AppElevation.sm => c.shadowSm,
      AppElevation.md => c.shadowMd,
      AppElevation.lg => c.shadowLg,
    };

    final resolvedBorder = borderColor ?? (selected ? c.primary : c.border);
    final resolvedWidth = borderWidth ?? (selected ? 1.6 : 1);

    Widget content = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? c.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: resolvedBorder, width: resolvedWidth),
        boxShadow: selected
            ? [
                ...shadows,
                BoxShadow(
                  color: c.primary.withValues(alpha: 0.16),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ]
            : shadows,
      ),
      child: child,
    );

    if (onTap == null) return content;
    return AppTappable(onTap: onTap, child: content);
  }
}

/// Translucent blurred bar — used for the tab bar, sticky headers and
/// floating action bars so content scrolls *under* frosted glass.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.blur = 24,
    this.opacity = 0.78,
    this.borderRadius,
    this.border,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: c.isDark ? opacity + 0.1 : opacity),
            borderRadius: borderRadius,
            border: border,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Grouped iOS-style settings list: one rounded container, hairline
/// separators between rows, no separator after the last row.
class AppGroupedList extends StatelessWidget {
  const AppGroupedList({
    super.key,
    required this.children,
    this.header,
    this.footer,
  });

  final List<Widget> children;
  final String? header;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDimensions.space4, 0, AppDimensions.space4, AppDimensions.space8),
            child: Text(
              header!.toUpperCase(),
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: c.textTertiary, letterSpacing: 0.8),
            ),
          ),
        ],
        AppCard(
          padding: EdgeInsets.zero,
          clip: true,
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 56),
                    child: Divider(height: 1, thickness: 1, color: c.separator),
                  ),
              ],
            ],
          ),
        ),
        if (footer != null) ...[
          const SizedBox(height: AppDimensions.space8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space4),
            child: Text(
              footer!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: c.textTertiary),
            ),
          ),
        ],
      ],
    );
  }
}
