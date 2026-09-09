import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/typography.dart';
import 'app_tappable.dart';

/// Stepper with a value that slides when it changes — small detail, but
/// it is what separates a premium cart row from a template one.
class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.minQuantity = 1,
    this.maxQuantity = 99,
    this.compact = false,
    this.onRemove,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final int minQuantity;
  final int maxQuantity;
  final bool compact;

  /// When provided, stepping below [minQuantity] removes the row instead
  /// of being a dead button.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final canDecrement = quantity > minQuantity || onRemove != null;
    final atMin = quantity <= minQuantity;

    return Container(
      height: compact ? 34 : 40,
      decoration: BoxDecoration(
        color: c.isDark ? c.surfaceMuted : c.backgroundSunken,
        borderRadius: AppDimensions.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: atMin && onRemove != null
                ? Icons.delete_outline_rounded
                : Icons.remove_rounded,
            danger: atMin && onRemove != null,
            compact: compact,
            onTap: canDecrement
                ? (atMin && onRemove != null ? onRemove : onDecrement)
                : null,
          ),
          SizedBox(
            width: compact ? 28 : 34,
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.4),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                '$quantity',
                key: ValueKey(quantity),
                textAlign: TextAlign.center,
                style: AppTypography.numeric.copyWith(
                  color: c.textPrimary,
                  fontSize: compact ? 14 : 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            compact: compact,
            onTap: quantity < maxQuantity ? onIncrement : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.compact,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final bool compact;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final side = compact ? 30.0 : 36.0;
    return AppTappable(
      onTap: onTap,
      pressedScale: 0.86,
      child: Container(
        width: side,
        height: side,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: onTap == null ? Colors.transparent : c.surface,
          shape: BoxShape.circle,
          boxShadow: onTap == null ? null : c.shadowSm,
        ),
        child: Icon(
          icon,
          size: compact ? 15 : 17,
          color: onTap == null
              ? c.textTertiary
              : (danger ? c.danger : c.primary),
        ),
      ),
    );
  }
}
