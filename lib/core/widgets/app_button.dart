import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/typography.dart';
import 'app_tappable.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, danger, text }

enum AppButtonSize { large, medium, small }

/// The app's one button. Gradient-filled primary with a coloured glow,
/// iOS press scale, built-in loading and disabled states.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.expand = true,
    this.trailingLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool expand;

  /// Optional right-aligned value, e.g. the order total inside the
  /// checkout CTA: "To'lovga o'tish · 135 000 so'm".
  final String? trailingLabel;

  bool get _disabled => onPressed == null || isLoading;

  double get _height => switch (size) {
        AppButtonSize.large => AppDimensions.buttonHeight,
        AppButtonSize.medium => 48,
        AppButtonSize.small => AppDimensions.buttonHeightSmall,
      };

  double get _radius => switch (size) {
        AppButtonSize.large => AppDimensions.radiusMedium,
        AppButtonSize.medium => AppDimensions.radiusSmall,
        AppButtonSize.small => AppDimensions.radiusPill,
      };

  TextStyle get _textStyle => switch (size) {
        AppButtonSize.large => AppTypography.button,
        AppButtonSize.medium => AppTypography.button.copyWith(fontSize: 16),
        AppButtonSize.small => AppTypography.buttonSmall,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.palette;

    final (Color fg, Color? bg, Gradient? gradient, Color? border) = switch (variant) {
      AppButtonVariant.primary => (c.onPrimary, null, c.brandGradient, null),
      AppButtonVariant.secondary => (
          c.textPrimary,
          c.isDark ? c.surfaceElevated : const Color(0xFF12203A),
          null,
          null,
        ),
      AppButtonVariant.outline => (c.primary, Colors.transparent, null, c.borderStrong),
      AppButtonVariant.ghost => (c.primary, c.primarySoft, null, null),
      AppButtonVariant.danger => (Colors.white, c.danger, null, null),
      AppButtonVariant.text => (c.primary, Colors.transparent, null, null),
    };

    final foreground = variant == AppButtonVariant.secondary && !c.isDark
        ? Colors.white
        : fg;

    Widget content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment:
          trailingLabel != null ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
      children: [
        if (trailingLabel != null) const SizedBox(width: AppDimensions.space4),
        Flexible(
          child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: size == AppButtonSize.small ? 16 : 19, color: foreground),
              const SizedBox(width: AppDimensions.space8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _textStyle.copyWith(color: foreground),
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: AppDimensions.space8),
              Icon(trailingIcon, size: size == AppButtonSize.small ? 16 : 19, color: foreground),
            ],
          ],
          ),
        ),
        if (trailingLabel != null)
          Flexible(
            child: Text(
              trailingLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.price.copyWith(color: foreground, fontSize: 16),
            ),
          ),
      ],
    );

    if (isLoading) {
      content = SizedBox(
        height: size == AppButtonSize.small ? 18 : 22,
        width: size == AppButtonSize.small ? 18 : 22,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: foreground),
      );
      content = Center(child: content);
    }

    final button = AnimatedOpacity(
      duration: AppMotion.fast,
      opacity: _disabled && !isLoading ? 0.45 : 1,
      child: AppTappable(
        onTap: _disabled ? null : onPressed,
        pressedScale: 0.975,
        child: Container(
          height: _height,
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            horizontal: switch (size) {
              AppButtonSize.large => AppDimensions.space20,
              AppButtonSize.medium => AppDimensions.space16,
              AppButtonSize.small => AppDimensions.space14,
            },
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _disabled && variant == AppButtonVariant.primary ? c.surfaceMuted : bg,
            gradient: _disabled && variant == AppButtonVariant.primary ? null : gradient,
            borderRadius: BorderRadius.circular(_radius),
            border: border != null ? Border.all(color: border) : null,
            boxShadow: variant == AppButtonVariant.primary && !_disabled
                ? [
                    BoxShadow(
                      color: c.primary.withValues(alpha: c.isDark ? 0.32 : 0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: DefaultTextStyle.merge(
            style: _textStyle.copyWith(color: foreground),
            child: content,
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Circular icon button used in headers and over imagery.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 40,
    this.iconSize = 19,
    this.background,
    this.foreground,
    this.bordered = true,
    this.badgeCount,
    this.showDot = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? background;
  final Color? foreground;
  final bool bordered;
  final int? badgeCount;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppTappable(
      onTap: onTap,
      pressedScale: 0.9,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: background ?? c.surface,
              shape: BoxShape.circle,
              border: bordered ? Border.all(color: c.border) : null,
              boxShadow: c.shadowSm,
            ),
            child: Icon(icon, size: iconSize, color: foreground ?? c.textPrimary),
          ),
          if (showDot || (badgeCount != null && badgeCount! > 0))
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: badgeCount != null ? 5 : 0,
                  vertical: 0,
                ),
                constraints: BoxConstraints(minWidth: badgeCount != null ? 18 : 10),
                height: badgeCount != null ? 18 : 10,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.danger,
                  borderRadius: AppDimensions.brPill,
                  border: Border.all(color: c.surface, width: 2),
                ),
                child: badgeCount != null
                    ? Text(
                        badgeCount! > 99 ? '99+' : '$badgeCount',
                        style: AppTypography.caption2.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          height: 1,
                        ),
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
