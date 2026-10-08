import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/typography.dart';
import '../utils/haptics.dart';
import 'app_button.dart';
import 'app_tappable.dart';

/// Confirmation dialog — required before an order is placed (UX rule:
/// "use confirmation before placing an order").
class CustomDialog {
  const CustomDialog._();

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Ha, davom etish',
    String cancelLabel = 'Bekor qilish',
    IconData icon = Icons.help_outline_rounded,
    bool destructive = false,
    String? highlight,
  }) async {
    AppHaptics.emphasis();
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: cancelLabel,
      barrierColor: context.palette.scrim,
      transitionDuration: AppMotion.base,
      pageBuilder: (context, _, __) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, __) {
        final curved = CurvedAnimation(parent: animation, curve: AppMotion.spring);
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.92 + 0.08 * curved.value,
            child: _DialogBody(
              title: title,
              message: message,
              confirmLabel: confirmLabel,
              cancelLabel: cancelLabel,
              icon: icon,
              destructive: destructive,
              highlight: highlight,
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  /// Single-action informational dialog.
  static Future<void> info(
    BuildContext context, {
    required String title,
    required String message,
    String actionLabel = 'Tushunarli',
    IconData icon = Icons.info_outline_rounded,
  }) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: actionLabel,
      barrierColor: context.palette.scrim,
      transitionDuration: AppMotion.base,
      pageBuilder: (context, _, __) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, __) {
        final curved = CurvedAnimation(parent: animation, curve: AppMotion.spring);
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.92 + 0.08 * curved.value,
            child: _DialogBody(
              title: title,
              message: message,
              confirmLabel: actionLabel,
              cancelLabel: null,
              icon: icon,
              destructive: false,
              highlight: null,
            ),
          ),
        );
      },
    );
  }
}

class _DialogBody extends StatelessWidget {
  const _DialogBody({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.icon,
    required this.destructive,
    required this.highlight,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String? cancelLabel;
  final IconData icon;
  final bool destructive;
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final accent = destructive ? c.danger : c.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space32),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.space24),
            decoration: BoxDecoration(
              color: c.surfaceElevated,
              borderRadius: AppDimensions.brXLarge,
              border: Border.all(color: c.border),
              boxShadow: c.shadowLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: c.tint(accent, 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accent, size: 27),
                ),
                const SizedBox(height: AppDimensions.space16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.title3.copyWith(color: c.textPrimary),
                ),
                const SizedBox(height: AppDimensions.space8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.callout.copyWith(color: c.textSecondary),
                ),
                if (highlight != null) ...[
                  const SizedBox(height: AppDimensions.space16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space14,
                      vertical: AppDimensions.space12,
                    ),
                    decoration: BoxDecoration(
                      color: c.tint(accent, 0.08),
                      borderRadius: AppDimensions.brSmall,
                    ),
                    child: Text(
                      highlight!,
                      textAlign: TextAlign.center,
                      style: AppTypography.headline.copyWith(color: accent),
                    ),
                  ),
                ],
                const SizedBox(height: AppDimensions.space20),
                AppButton(
                  label: confirmLabel,
                  variant: destructive ? AppButtonVariant.danger : AppButtonVariant.primary,
                  size: AppButtonSize.medium,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                if (cancelLabel != null) ...[
                  const SizedBox(height: AppDimensions.space8),
                  AppButton(
                    label: cancelLabel!,
                    variant: AppButtonVariant.text,
                    size: AppButtonSize.medium,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal bottom sheet with the app's rounded top, drag handle, title row
/// (optional subtitle + round close button) and keyboard-aware padding.
///
/// Opens on the **root** navigator so it covers the floating tab bar
/// instead of sliding in underneath it. Callers that close it with a page
/// `context` must therefore pop the root navigator:
/// `Navigator.of(context, rootNavigator: true).pop(value)`.
class AppSheet {
  const AppSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    String? subtitle,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: isScrollControlled,
      backgroundColor: context.palette.surface,
      barrierColor: context.palette.scrim,
      builder: (context) {
        final c = context.palette;
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.gutter,
                      0,
                      AppDimensions.space16,
                      AppDimensions.space16,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: AppTypography.title2
                                    .copyWith(color: c.textPrimary),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: AppTypography.subhead
                                      .copyWith(color: c.textSecondary),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space12),
                        _SheetCloseButton(
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                      ],
                    ),
                  ),
                Flexible(child: child),
                const SizedBox(height: AppDimensions.space16),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SheetCloseButton extends StatelessWidget {
  const _SheetCloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Semantics(
      button: true,
      label: 'Yopish',
      child: AppTappable(
        onTap: onTap,
        pressedScale: 0.88,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: c.isDark ? c.surfaceMuted : c.backgroundSunken,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.close_rounded, size: 18, color: c.textSecondary),
        ),
      ),
    );
  }
}

/// One choice inside an [AppSheet] picker (sort order, language, …): a
/// rounded row with a tinted leading tile, label + hint, and a radio tick.
/// The selected row lifts onto a primary tint so the current choice reads
/// at a glance.
class AppSheetOption extends StatelessWidget {
  const AppSheetOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.leading,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  /// Icon drawn in a tinted rounded tile; ignored when [leading] is set.
  final IconData? icon;
  final Color? iconColor;

  /// Custom content for the leading tile (e.g. a flag emoji).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final accent = iconColor ?? c.primary;
    final hasLeading = leading != null || icon != null;

    return Semantics(
      button: true,
      selected: selected,
      child: AppTappable(
        onTap: onTap,
        pressedScale: 0.98,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space14,
            vertical: AppDimensions.space12,
          ),
          decoration: BoxDecoration(
            color: selected
                ? c.tint(c.primary, 0.08)
                : (c.isDark ? c.surfaceMuted : c.background),
            borderRadius: AppDimensions.brMedium,
            border: Border.all(
              color: selected
                  ? c.primary.withValues(alpha: 0.45)
                  : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              if (hasLeading) ...[
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: leading != null ? c.surface : c.tint(accent, 0.14),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXSmall + 2),
                  ),
                  child: leading ?? Icon(icon, size: 20, color: accent),
                ),
                const SizedBox(width: AppDimensions.space12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.callout.copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption
                            .copyWith(color: c.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              _RadioTick(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioTick extends StatelessWidget {
  const _RadioTick({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? c.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? c.primary : c.borderStrong,
          width: 1.8,
        ),
      ),
      child: AnimatedScale(
        duration: AppMotion.base,
        curve: AppMotion.spring,
        scale: selected ? 1 : 0,
        child: Icon(Icons.check_rounded, size: 15, color: c.onPrimary),
      ),
    );
  }
}

/// Stack of [AppSheetOption]s with the sheet's side gutter and even gaps.
class AppSheetOptionList extends StatelessWidget {
  const AppSheetOptionList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppDimensions.pagePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: AppDimensions.space8),
            children[i],
          ],
        ],
      ),
    );
  }
}

enum ToastTone { neutral, success, warning, danger }

/// Floating toast used for "Savatga qo'shildi" and similar confirmations.
class AppToast {
  const AppToast._();

  static void show(
    BuildContext context,
    String message, {
    ToastTone tone = ToastTone.neutral,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final c = context.palette;
    final accent = switch (tone) {
      ToastTone.neutral => c.primary,
      ToastTone.success => c.success,
      ToastTone.warning => c.warning,
      ToastTone.danger => c.danger,
    };
    final resolvedIcon = icon ??
        switch (tone) {
          ToastTone.neutral => Icons.info_rounded,
          ToastTone.success => Icons.check_circle_rounded,
          ToastTone.warning => Icons.warning_amber_rounded,
          ToastTone.danger => Icons.error_rounded,
        };

    AppHaptics.tap();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 2200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space14,
            vertical: AppDimensions.space12,
          ),
          content: Row(
            children: [
              Icon(resolvedIcon, color: accent, size: 20),
              const SizedBox(width: AppDimensions.space10),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.callout.copyWith(color: Colors.white),
                ),
              ),
              if (actionLabel != null && onAction != null)
                AppButton(
                  label: actionLabel,
                  variant: AppButtonVariant.text,
                  size: AppButtonSize.small,
                  expand: false,
                  onPressed: onAction,
                ),
            ],
          ),
        ),
      );
  }
}
