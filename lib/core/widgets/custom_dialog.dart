import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/typography.dart';
import 'app_button.dart';

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
    HapticFeedback.mediumImpact();
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

/// Modal bottom sheet with the app's rounded top, drag handle and title.
class AppSheet {
  const AppSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
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
                      AppDimensions.space4,
                      AppDimensions.gutter,
                      AppDimensions.space16,
                    ),
                    child: Text(
                      title,
                      style: AppTypography.title3.copyWith(color: c.textPrimary),
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

    HapticFeedback.lightImpact();
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
