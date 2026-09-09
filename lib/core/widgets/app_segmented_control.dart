import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/typography.dart';
import 'app_tappable.dart';

/// iOS segmented control: a sliding thumb inside a sunken track. Used for
/// the order tabs (Barchasi / Faol / Yakunlangan) and delivery mode.
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.padding = const EdgeInsets.all(4),
  });

  final Map<T, String> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final keys = segments.keys.toList();
    final index = keys.indexOf(value).clamp(0, keys.length - 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth - padding.horizontal;
        final thumbWidth = trackWidth / keys.length;

        return Container(
          height: 44,
          padding: padding,
          decoration: BoxDecoration(
            color: c.isDark ? c.surfaceMuted : c.backgroundSunken,
            borderRadius: AppDimensions.brSmall,
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: AppMotion.base,
                curve: AppMotion.standard,
                left: thumbWidth * index,
                top: 0,
                bottom: 0,
                width: thumbWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXSmall),
                    boxShadow: c.shadowSm,
                  ),
                ),
              ),
              Row(
                children: [
                  for (final key in keys)
                    Expanded(
                      child: AppTappable(
                        haptic: true,
                        onTap: () => onChanged(key),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: AppMotion.fast,
                            style: AppTypography.callout.copyWith(
                              color: key == value ? c.textPrimary : c.textSecondary,
                              fontWeight:
                                  key == value ? FontWeight.w600 : FontWeight.w500,
                            ),
                            child: Text(
                              segments[key]!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
      },
    );
  }
}

/// Horizontally scrolling filter pills (Masofa / Reyting / Narx / …).
class AppChoiceChips<T> extends StatelessWidget {
  const AppChoiceChips({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.labelOf,
    this.iconOf,
    this.padding = const EdgeInsets.symmetric(horizontal: AppDimensions.gutter),
  });

  final List<T> items;
  final T value;
  final ValueChanged<T> onChanged;
  final String Function(T)? labelOf;
  final IconData? Function(T)? iconOf;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.chipHeight + 4,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppDimensions.space8),
        itemBuilder: (context, i) {
          final item = items[i];
          return AppChip(
            label: labelOf?.call(item) ?? '$item',
            icon: iconOf?.call(item),
            selected: item == value,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(item);
            },
          );
        },
      ),
    );
  }
}

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppTappable(
      onTap: onTap,
      pressedScale: 0.95,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        height: AppDimensions.chipHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? c.primary : c.surface,
          borderRadius: AppDimensions.brPill,
          border: Border.all(color: selected ? c.primary : c.border),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: c.primary.withValues(alpha: 0.24),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : c.shadowSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: selected ? c.onPrimary : c.textSecondary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTypography.subhead.copyWith(
                color: selected ? c.onPrimary : c.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum PillTone { neutral, primary, success, warning, danger, info, flame }

/// Small status pill: "Mavjud", "Aktiv", "Eng arzon", "Yo'lda" …
class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.label,
    this.tone = PillTone.neutral,
    this.icon,
    this.filled = false,
    this.dense = false,
  });

  final String label;
  final PillTone tone;
  final IconData? icon;
  final bool filled;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final (Color fg, Color bg) = switch (tone) {
      PillTone.neutral => (c.textSecondary, c.surfaceMuted),
      PillTone.primary => (c.primary, c.primarySoft),
      PillTone.success => (c.success, c.successSoft),
      PillTone.warning => (c.warning, c.warningSoft),
      PillTone.danger => (c.danger, c.dangerSoft),
      PillTone.info => (c.info, c.infoSoft),
      PillTone.flame => (AppColors.energyFlame, c.tint(AppColors.energyFlame)),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 9,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: filled ? fg : bg,
        borderRadius: AppDimensions.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 13, color: filled ? Colors.white : fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (dense ? AppTypography.caption2 : AppTypography.caption).copyWith(
                color: filled ? Colors.white : fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
