import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/typography.dart';
import 'app_tappable.dart';
import 'custom_dialog.dart';

/// A tap-to-pick field styled exactly like [AppTextField] — used for
/// category / working-hours / other choice inputs on the seller forms so
/// the whole form reads as one system instead of mixing widget styles.
class AppSelectField extends StatelessWidget {
  const AppSelectField({
    super.key,
    required this.label,
    required this.onTap,
    this.value,
    this.hint,
    this.prefixIcon,
    this.errorText,
  });

  final String label;
  final VoidCallback onTap;
  final String? value;
  final String? hint;
  final IconData? prefixIcon;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: AppDimensions.space8),
          child: Text(
            label,
            style: AppTypography.subhead.copyWith(
              color: c.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        AppTappable(
          onTap: onTap,
          pressedScale: 0.99,
          child: Container(
            height: AppDimensions.inputHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
            decoration: BoxDecoration(
              color: c.isDark ? c.surfaceMuted : c.surface,
              borderRadius: AppDimensions.brMedium,
              border: Border.all(color: hasError ? c.danger : c.border),
              boxShadow: c.shadowSm,
            ),
            child: Row(
              children: [
                if (prefixIcon != null) ...[
                  Icon(prefixIcon, size: 20, color: c.textTertiary),
                  const SizedBox(width: AppDimensions.space10),
                ],
                Expanded(
                  child: Text(
                    value ?? hint ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      color: value == null ? c.textTertiary : c.textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.expand_more_rounded, size: 20, color: c.textTertiary),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: AppDimensions.space6),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 14, color: c.danger),
                const SizedBox(width: 4),
                Text(errorText!, style: AppTypography.caption.copyWith(color: c.danger)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Option-list sheet shared by every "pick one of N" field in the app
/// (category, working hours, admin filters, …).
class AppPickerSheet<T> extends StatelessWidget {
  const AppPickerSheet({
    super.key,
    required this.options,
    required this.labelOf,
    required this.selected,
    this.iconOf,
  });

  final List<T> options;
  final String Function(T) labelOf;
  final T? selected;
  final IconData? Function(T)? iconOf;

  /// Opens through [AppSheet], so it gets the same title row, close
  /// button, option rows and root-navigator placement (above the tab bar)
  /// as every other picker.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required String Function(T) labelOf,
    T? selected,
    IconData? Function(T)? iconOf,
  }) {
    return AppSheet.show<T>(
      context,
      title: title,
      child: AppPickerSheet<T>(
        options: options,
        labelOf: labelOf,
        selected: selected,
        iconOf: iconOf,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // `context` sits inside the sheet route, so this pops the sheet.
    return AppSheetOptionList(
      children: [
        for (final option in options)
          AppSheetOption(
            label: labelOf(option),
            icon: iconOf?.call(option),
            selected: option == selected,
            onTap: () => Navigator.of(context).pop(option),
          ),
      ],
    );
  }
}
