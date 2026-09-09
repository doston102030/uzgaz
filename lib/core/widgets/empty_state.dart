import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/typography.dart';
import 'app_button.dart';

/// Friendly empty state: soft halo, one clear sentence, one clear action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.tone,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final Color? tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final accent = tone ?? c.primary;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.space32,
          vertical: compact ? AppDimensions.space24 : AppDimensions.space40,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 76 : 96,
              height: compact ? 76 : 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.withValues(alpha: c.isDark ? 0.26 : 0.14),
                    accent.withValues(alpha: 0),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: compact ? 52 : 64,
                  height: compact ? 52 : 64,
                  decoration: BoxDecoration(
                    color: c.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.border),
                    boxShadow: c.shadowSm,
                  ),
                  child: Icon(icon, size: compact ? 24 : 30, color: accent),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.title3.copyWith(color: c.textPrimary),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppDimensions.space8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTypography.callout.copyWith(color: c.textSecondary),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppDimensions.space24),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
                size: AppButtonSize.medium,
              ),
            ],
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: AppDimensions.space8),
              AppButton(
                label: secondaryLabel!,
                onPressed: onSecondary,
                expand: false,
                variant: AppButtonVariant.text,
                size: AppButtonSize.small,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
