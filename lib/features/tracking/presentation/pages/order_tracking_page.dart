import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/company_card.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/order_status_widget.dart';
import '../../../../core/widgets/price_row.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../core/widgets/product_illustration.dart';
import '../../../../core/widgets/pulsing_marker.dart';
import '../../../../core/utils/dash_path.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/presentation/providers/order_provider.dart';

class OrderTrackingPage extends ConsumerWidget {
  const OrderTrackingPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final order = ref.watch(orderByIdProvider(orderId));

    if (order == null) {
      return Scaffold(
        body: SafeArea(
          child: EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Buyurtma topilmadi',
            actionLabel: 'Buyurtmalarim',
            onAction: () => context.go('/orders'),
          ),
        ),
      );
    }

    final isDelivery = order.deliveryMethod == DeliveryMethod.delivery;
    final minutesLeft = order.eta.difference(DateTime.now()).inMinutes;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _TrackingMap(order: order),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -22),
              child: Container(
                decoration: BoxDecoration(
                  color: c.background,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppDimensions.radiusSheet),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.gutter,
                  AppDimensions.space20,
                  AppDimensions.gutter,
                  AppDimensions.space32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                order.status == OrderStatus.yetkazildi
                                    ? 'Buyurtma yetkazildi'
                                    : (minutesLeft > 0
                                        ? '$minutesLeft daqiqada yetadi'
                                        : 'Tez orada yetadi'),
                                style: AppTypography.title2
                                    .copyWith(color: c.textPrimary),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${order.orderNumber} · ${order.companyName}',
                                style: AppTypography.callout
                                    .copyWith(color: c.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        OrderStatusBadge(status: order.status),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space20),

                    // Timeline
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Buyurtma holati',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.headline
                                      .copyWith(color: c.textPrimary),
                                ),
                              ),
                              if (order.status.isActive)
                                Flexible(
                                  child: AppButton(
                                    label: 'Keyingi bosqich',
                                    variant: AppButtonVariant.text,
                                    size: AppButtonSize.small,
                                    expand: false,
                                    onPressed: () => ref
                                        .read(ordersProvider.notifier)
                                        .advance(order.id),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.space16),
                          OrderStatusSteps(
                            currentStatus: order.status,
                            placedAt: order.date,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space12),

                    if (isDelivery && order.driver != null) ...[
                      _DriverCard(driver: order.driver!),
                      const SizedBox(height: AppDimensions.space12),
                    ],

                    // Destination
                    AppCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: c.primarySoft,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              isDelivery
                                  ? Icons.place_rounded
                                  : Icons.storefront_rounded,
                              size: 20,
                              color: c.primary,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isDelivery
                                      ? 'Yetkazish manzili'
                                      : 'Olib ketish nuqtasi',
                                  style: AppTypography.caption2
                                      .copyWith(color: c.textTertiary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  order.address ?? order.companyName,
                                  style: AppTypography.callout.copyWith(
                                    color: c.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space12),

                    // Items + totals
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buyurtma tafsilotlari',
                            style: AppTypography.headline
                                .copyWith(color: c.textPrimary),
                          ),
                          const SizedBox(height: AppDimensions.space14),
                          for (int i = 0; i < order.items.length; i++) ...[
                            if (i != 0)
                              Divider(
                                height: AppDimensions.space20,
                                color: c.separator,
                              ),
                            ProductListTile(
                              title: order.items[i].productName,
                              price: order.items[i].price,
                              quantity: order.items[i].quantity,
                              visual: EnergyVisualX.fromCategory(
                                order.items[i].categoryId,
                                name: order.items[i].productName,
                              ),
                              trailing: Text(
                                AppFormatters.currency(order.items[i].subtotal),
                                style: AppTypography.priceSmall
                                    .copyWith(color: c.textPrimary),
                              ),
                            ),
                          ],
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppDimensions.space12,
                            ),
                            child: DashedDivider(),
                          ),
                          PriceRow(label: 'Mahsulotlar', amount: order.subtotal),
                          PriceRow(
                            label: 'Yetkazib berish',
                            amount: order.deliveryFee,
                            isFree: order.deliveryFee == 0,
                          ),
                          const SizedBox(height: AppDimensions.space4),
                          PriceRow(
                            label: 'Jami',
                            amount: order.total,
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space16),

                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Yordam',
                            icon: Icons.support_agent_rounded,
                            variant: AppButtonVariant.outline,
                            size: AppButtonSize.medium,
                            onPressed: () => CustomDialog.info(
                              context,
                              title: 'Qo‘llab-quvvatlash',
                              message:
                                  'Savollar bo‘lsa ${AppConstants.supportPhone} '
                                  'raqamiga qo‘ng‘iroq qiling — 24/7 ishlaymiz.',
                              icon: Icons.support_agent_rounded,
                            ),
                          ),
                        ),
                        if (order.status == OrderStatus.qabulQilindi) ...[
                          const SizedBox(width: AppDimensions.space10),
                          Expanded(
                            child: AppButton(
                              label: 'Bekor qilish',
                              variant: AppButtonVariant.outline,
                              size: AppButtonSize.medium,
                              onPressed: () async {
                                final confirmed = await CustomDialog.confirm(
                                  context,
                                  title: 'Buyurtmani bekor qilish',
                                  message:
                                      'Buyurtma bekor qilinadi va to‘lov 1–3 ish '
                                      'kunida qaytariladi.',
                                  confirmLabel: 'Ha, bekor qilish',
                                  destructive: true,
                                  icon: Icons.cancel_outlined,
                                );
                                if (confirmed && context.mounted) {
                                  AppToast.show(
                                    context,
                                    'So‘rov qabul qilindi',
                                    tone: ToastTone.warning,
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Live map strip. Swap [_TrackPainter] for a `GoogleMap` with a driver
/// marker once the Maps key and location stream are wired up.
class _TrackingMap extends StatelessWidget {
  const _TrackingMap({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final topPad = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _TrackPainter(
              line: c.primary,
              grid: c.isDark ? const Color(0xFF1B2434) : const Color(0xFFE3E9F2),
              bg: c.isDark ? const Color(0xFF0D141F) : const Color(0xFFEFF3F8),
              block: c.isDark ? const Color(0xFF141D2B) : const Color(0xFFE6ECF4),
              isDark: c.isDark,
            ),
          ),
          // Vehicle marker — pulses to read as a live, moving position.
          Align(
            alignment: const Alignment(0.05, 0.12),
            child: PulsingMarker(
              color: c.primary,
              ringSize: 46,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.surface, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: c.primary.withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.local_shipping_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
          // Destination marker
          Align(
            alignment: const Alignment(0.72, 0.62),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: c.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.primary, width: 2.5),
                    boxShadow: c.shadowSm,
                  ),
                  child: Icon(Icons.flag_rounded, size: 14, color: c.primary),
                ),
                CustomPaint(
                  size: const Size(8, 6),
                  painter: _PinTailPainter(c.primary),
                ),
              ],
            ),
          ),
          Positioned(
            left: AppDimensions.gutter,
            top: topPad + AppDimensions.space8,
            child: AppIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              iconSize: 16,
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/orders');
                }
              },
            ),
          ),
          Positioned(
            right: AppDimensions.gutter,
            top: topPad + AppDimensions.space8,
            child: AppPill(
              label: order.deliveryMethod.labelUz,
              tone: PillTone.primary,
              icon: order.deliveryMethod.icon,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      c.background.withValues(alpha: 0),
                      c.background,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.driver});

  final DriverInfo driver;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppCard(
      child: Row(
        children: [
          CompanyLogo(name: driver.name, size: 50, radius: 17),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.name,
                  style: AppTypography.callout.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 13, color: c.star),
                    const SizedBox(width: 2),
                    Text(
                      '${driver.rating}',
                      style: AppTypography.caption.copyWith(color: c.textSecondary),
                    ),
                    const SizedBox(width: AppDimensions.space6),
                    Flexible(
                      child: Text(
                        driver.vehicle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption
                            .copyWith(color: c.textTertiary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppIconButton(
            icon: Icons.chat_bubble_outline_rounded,
            iconSize: 17,
            onTap: () => AppToast.show(context, 'Chat tez orada ishga tushadi'),
          ),
          const SizedBox(width: AppDimensions.space8),
          AppIconButton(
            icon: Icons.call_rounded,
            iconSize: 18,
            background: c.success,
            foreground: Colors.white,
            bordered: false,
            onTap: () => launchUrl(Uri.parse('tel:${driver.phone}')),
          ),
        ],
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  _TrackPainter({
    required this.line,
    required this.grid,
    required this.bg,
    required this.block,
    required this.isDark,
  });

  final Color line;
  final Color grid;
  final Color bg;
  final Color block;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = bg);

    final random = math.Random(3);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final shades = [block, Color.lerp(block, bg, 0.4)!, Color.lerp(block, grid, 0.3)!];

    for (double y = -10; y < size.height; y += 66) {
      for (double x = -10; x < size.width; x += 82) {
        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 8, y + 8, 56, 38),
          const Radius.circular(6),
        );
        canvas.drawRRect(rrect.shift(const Offset(0, 2)), shadowPaint);
        canvas.drawRRect(rrect, Paint()..color = shades[random.nextInt(shades.length)]);
      }
    }

    final roadPaint = Paint()
      ..color = grid
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    for (double y = 20; y < size.height; y += 66) {
      canvas.drawLine(Offset(-10, y), Offset(size.width + 10, y), roadPaint);
    }
    for (double x = 26; x < size.width; x += 82) {
      canvas.drawLine(Offset(x, -10), Offset(x, size.height + 10), roadPaint);
    }

    // Route: solid where the driver has already been, dashed for what's
    // still ahead — the split alone communicates progress at a glance.
    final path = Path()
      ..moveTo(size.width * 0.52, size.height * 0.56)
      ..cubicTo(
        size.width * 0.62, size.height * 0.60,
        size.width * 0.66, size.height * 0.70,
        size.width * 0.72, size.height * 0.72,
      )
      ..cubicTo(
        size.width * 0.80, size.height * 0.75,
        size.width * 0.84, size.height * 0.80,
        size.width * 0.86, size.height * 0.81,
      );

    final metric = path.computeMetrics().first;
    final splitAt = metric.length * 0.32;
    final traveled = metric.extractPath(0, splitAt);
    final remaining = metric.extractPath(splitAt, metric.length);

    canvas.drawPath(
      traveled,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..color = line.withValues(alpha: 0.18),
    );
    canvas.drawPath(
      traveled,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = line,
    );
    canvas.drawPath(
      dashPath(remaining, dashLength: 9, gapLength: 7),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = line.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant _TrackPainter old) => old.line != line;
}

class _PinTailPainter extends CustomPainter {
  _PinTailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PinTailPainter old) => old.color != color;
}
