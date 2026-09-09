import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/typography.dart';
import '../constants/app_constants.dart';
import 'app_segmented_control.dart';

extension OrderStatusUi on OrderStatus {
  IconData get icon => switch (this) {
        OrderStatus.qabulQilindi => Icons.receipt_long_rounded,
        OrderStatus.tayyorlanmoqda => Icons.inventory_2_rounded,
        OrderStatus.yolda => Icons.local_shipping_rounded,
        OrderStatus.yetkazildi => Icons.check_circle_rounded,
      };

  String get hintUz => switch (this) {
        OrderStatus.qabulQilindi => 'Buyurtmangiz qabul qilindi',
        OrderStatus.tayyorlanmoqda => 'Kompaniya buyurtmani tayyorlamoqda',
        OrderStatus.yolda => 'Kuryer sizga yetib kelmoqda',
        OrderStatus.yetkazildi => 'Buyurtma yetkazib berildi',
      };

  PillTone get tone => switch (this) {
        OrderStatus.qabulQilindi => PillTone.info,
        OrderStatus.tayyorlanmoqda => PillTone.warning,
        OrderStatus.yolda => PillTone.primary,
        OrderStatus.yetkazildi => PillTone.success,
      };
}

/// Compact horizontal progress used on order cards and the tracking header.
class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({super.key, required this.currentStatus});

  final OrderStatus currentStatus;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    const steps = OrderStatus.values;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 26,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 2,
                              color: i == 0
                                  ? Colors.transparent
                                  : (steps[i].step <= currentStatus.step
                                      ? c.primary
                                      : c.border),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 2,
                              color: i == steps.length - 1
                                  ? Colors.transparent
                                  : (steps[i].step < currentStatus.step
                                      ? c.primary
                                      : c.border),
                            ),
                          ),
                        ],
                      ),
                      _StepDot(
                        done: steps[i].step < currentStatus.step,
                        active: steps[i].step == currentStatus.step,
                        icon: steps[i].icon,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space8),
                Text(
                  steps[i].labelUz,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppTypography.caption2.copyWith(
                    fontSize: 10,
                    height: 1.2,
                    color: steps[i].step <= currentStatus.step
                        ? c.textPrimary
                        : c.textTertiary,
                    fontWeight: steps[i].step == currentStatus.step
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.done, required this.active, required this.icon});

  final bool done;
  final bool active;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final filled = done || active;

    return AnimatedContainer(
      duration: AppMotion.base,
      curve: AppMotion.standard,
      width: active ? 26 : 20,
      height: active ? 26 : 20,
      decoration: BoxDecoration(
        color: filled ? c.primary : c.surface,
        shape: BoxShape.circle,
        border: Border.all(color: filled ? c.primary : c.borderStrong, width: 2),
        boxShadow: active
            ? [
                BoxShadow(
                  color: c.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: done
          ? Icon(Icons.check_rounded, size: 12, color: c.onPrimary)
          : (active ? Icon(icon, size: 13, color: c.onPrimary) : null),
    );
  }
}

/// Vertical timeline with timestamps — the detail view on the tracking page.
class OrderStatusSteps extends StatelessWidget {
  const OrderStatusSteps({
    super.key,
    required this.currentStatus,
    required this.placedAt,
  });

  final OrderStatus currentStatus;
  final DateTime placedAt;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    const steps = OrderStatus.values;

    return Column(
      children: [
        for (int i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    _StepDot(
                      done: steps[i].step < currentStatus.step,
                      active: steps[i].step == currentStatus.step,
                      icon: steps[i].icon,
                    ),
                    if (i != steps.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: steps[i].step < currentStatus.step ? c.primary : c.border,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppDimensions.space14),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i == steps.length - 1 ? 0 : AppDimensions.space20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].labelUz,
                          style: AppTypography.callout.copyWith(
                            color: steps[i].step <= currentStatus.step
                                ? c.textPrimary
                                : c.textTertiary,
                            fontWeight: steps[i].step == currentStatus.step
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          steps[i].hintUz,
                          style: AppTypography.caption.copyWith(color: c.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Small pill used inside order-history cards.
class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status, this.dense = false});

  final OrderStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return AppPill(
      label: status.labelUz,
      tone: status.tone,
      icon: status.icon,
      dense: dense,
    );
  }
}

/// Pulsing dot shown next to "Yo'lda" to signal a live order.
class LivePulse extends StatefulWidget {
  const LivePulse({super.key, this.color, this.size = 8});

  final Color? color;
  final double size;

  @override
  State<LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<LivePulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.palette.success;
    return SizedBox(
      width: widget.size * 2.6,
      height: widget.size * 2.6,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - _controller.value).clamp(0.0, 1.0) * 0.5,
                child: Container(
                  width: widget.size + (widget.size * 1.6 * _controller.value),
                  height: widget.size + (widget.size * 1.6 * _controller.value),
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          );
        },
      ),
    );
  }
}
