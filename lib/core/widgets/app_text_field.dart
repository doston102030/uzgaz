import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/typography.dart';
import 'app_tappable.dart';

/// Text input with an outside label, a soft filled body and an animated
/// focus ring. Validation errors animate in rather than jumping the layout.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helper,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.prefixText,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helper;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
  final String? prefixText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool autofocus;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  bool _focused = false;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!mounted) return;
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: AppDimensions.space8),
            child: Text(
              widget.label!,
              style: AppTypography.subhead.copyWith(
                color: _focused ? c.primary : c.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        FormField<String>(
          initialValue: widget.controller?.text ?? '',
          validator: widget.validator,
          builder: (state) {
            final hasError = state.errorText != null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.standard,
                  decoration: BoxDecoration(
                    color: widget.enabled
                        ? (c.isDark ? c.surfaceMuted : c.surface)
                        : c.surfaceMuted,
                    borderRadius: AppDimensions.brMedium,
                    border: Border.all(
                      color: hasError
                          ? c.danger
                          : (_focused ? c.primary : c.border),
                      width: _focused || hasError ? 1.6 : 1,
                    ),
                    boxShadow: _focused
                        ? [
                            BoxShadow(
                              color: (hasError ? c.danger : c.primary)
                                  .withValues(alpha: 0.14),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : c.shadowSm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (widget.prefixIcon != null)
                        Padding(
                          padding: const EdgeInsets.only(left: AppDimensions.space14),
                          child: Icon(
                            widget.prefixIcon,
                            size: 20,
                            color: _focused ? c.primary : c.textTertiary,
                          ),
                        ),
                      if (widget.prefixText != null)
                        Padding(
                          padding: const EdgeInsets.only(left: AppDimensions.space16),
                          child: Text(
                            widget.prefixText!,
                            style: AppTypography.body.copyWith(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          enabled: widget.enabled,
                          autofocus: widget.autofocus,
                          obscureText: widget.obscureText && _obscured,
                          keyboardType: widget.keyboardType,
                          textInputAction: widget.textInputAction,
                          maxLines: widget.obscureText ? 1 : widget.maxLines,
                          maxLength: widget.maxLength,
                          inputFormatters: widget.inputFormatters,
                          textCapitalization: widget.textCapitalization,
                          cursorColor: c.primary,
                          cursorRadius: const Radius.circular(2),
                          style: AppTypography.body.copyWith(color: c.textPrimary),
                          onChanged: (value) {
                            state.didChange(value);
                            widget.onChanged?.call(value);
                          },
                          onSubmitted: widget.onSubmitted,
                          decoration: InputDecoration(
                            hintText: widget.hint,
                            hintStyle:
                                AppTypography.body.copyWith(color: c.textTertiary),
                            counterText: '',
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: widget.prefixIcon == null &&
                                      widget.prefixText == null
                                  ? AppDimensions.space16
                                  : AppDimensions.space10,
                              vertical: AppDimensions.space16,
                            ),
                          ),
                        ),
                      ),
                      if (widget.obscureText)
                        AppTappable(
                          onTap: () => setState(() => _obscured = !_obscured),
                          child: Padding(
                            padding: const EdgeInsets.only(right: AppDimensions.space14),
                            child: Icon(
                              _obscured
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 20,
                              color: c.textTertiary,
                            ),
                          ),
                        )
                      else if (widget.suffixIcon != null)
                        Padding(
                          padding: const EdgeInsets.only(right: AppDimensions.space12),
                          child: widget.suffixIcon,
                        ),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: AppMotion.fast,
                  curve: AppMotion.standard,
                  alignment: Alignment.topLeft,
                  child: (hasError || widget.helper != null)
                      ? Padding(
                          padding: const EdgeInsets.only(
                              left: 4, top: AppDimensions.space6),
                          child: Row(
                            children: [
                              if (hasError)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Icon(Icons.error_outline_rounded,
                                      size: 14, color: c.danger),
                                ),
                              Expanded(
                                child: Text(
                                  state.errorText ?? widget.helper!,
                                  style: AppTypography.caption.copyWith(
                                    color: hasError ? c.danger : c.textTertiary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Read-only search bar used as a tap target on Home, and as a live field
/// in the catalogue.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
    this.trailing,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;

    final field = Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space14),
      decoration: BoxDecoration(
        color: c.isDark ? c.surfaceMuted : c.surface,
        borderRadius: AppDimensions.brMedium,
        border: Border.all(color: c.border),
        boxShadow: c.shadowSm,
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: c.textTertiary),
          const SizedBox(width: AppDimensions.space8),
          Expanded(
            child: readOnly
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(color: c.textTertiary),
                    ),
                  )
                : TextField(
                    controller: controller,
                    onChanged: onChanged,
                    autofocus: autofocus,
                    cursorColor: c.primary,
                    textInputAction: TextInputAction.search,
                    style: AppTypography.body.copyWith(color: c.textPrimary),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: hint,
                      hintStyle: AppTypography.body.copyWith(color: c.textTertiary),
                    ),
                  ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );

    if (!readOnly && onTap == null) return field;
    return AppTappable(onTap: onTap, pressedScale: 0.99, child: field);
  }
}
