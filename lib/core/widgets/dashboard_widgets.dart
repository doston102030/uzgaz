import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/typography.dart';
import '../utils/formatters.dart';
import 'app_button.dart';
import 'app_surface.dart';

/// KPI tile for the seller & admin dashboards — value, label, optional
/// trend, tinted icon chip. Four of these in a row is the standard
/// "overview" row on both shells.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.tone,
    this.trend,
    this.trendUp = true,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? tone;
  final String? trend;
  final bool trendUp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final accent = tone ?? c.primary;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space14,
        vertical: AppDimensions.space12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: c.tint(accent, 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: accent),
              ),
              const Spacer(),
              if (trend != null)
                Row(
                  children: [
                    Icon(
                      trendUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 13,
                      color: trendUp ? c.success : c.danger,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trend!,
                      style: AppTypography.caption2.copyWith(
                        color: trendUp ? c.success : c.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.headline.copyWith(
              color: c.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// One labelled bar in a [SimpleBarChart].
class ChartPoint {
  const ChartPoint(this.label, this.value);
  final String label;
  final int value;
}

/// A minimal, dependency-free bar chart for "last 7 days" style reports.
/// Bars animate in on first build; the tallest bar is always highlighted.
class SimpleBarChart extends StatefulWidget {
  const SimpleBarChart({super.key, required this.points, this.height = 140});

  final List<ChartPoint> points;
  final double height;

  @override
  State<SimpleBarChart> createState() => _SimpleBarChartState();
}

class _SimpleBarChartState extends State<SimpleBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final maxValue = widget.points.fold<int>(
      1,
      (max, p) => p.value > max ? p.value : max,
    );

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeOutCubic.transform(_controller.value);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final point in widget.points)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          point.value == 0 ? '' : AppFormatters.currencyCompact(point.value),
                          maxLines: 1,
                          style: AppTypography.caption2.copyWith(
                            color: c.textTertiary,
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: ((widget.height - 46) * (point.value / maxValue) * t)
                              .clamp(3.0, widget.height - 46),
                          decoration: BoxDecoration(
                            gradient: point.value == maxValue && maxValue > 1
                                ? c.brandGradient
                                : LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      c.primary.withValues(alpha: 0.35),
                                      c.primary.withValues(alpha: 0.18),
                                    ],
                                  ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          point.label,
                          style: AppTypography.caption2.copyWith(
                            color: c.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Row used in every approval queue (pending seller / pending product):
/// subject on the left, Tasdiqlash / Rad etish on the right.
class ApprovalRow extends StatelessWidget {
  const ApprovalRow({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onApprove,
    required this.onReject,
    this.onTap,
    this.meta,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final String? meta;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.space14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              leading,
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.callout.copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(color: c.textSecondary),
                    ),
                    if (meta != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        meta!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption2.copyWith(color: c.textTertiary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Rad etish',
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.small,
                  onPressed: onReject,
                ),
              ),
              const SizedBox(width: AppDimensions.space10),
              Expanded(
                child: AppButton(
                  label: 'Tasdiqlash',
                  size: AppButtonSize.small,
                  icon: Icons.check_rounded,
                  onPressed: onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
