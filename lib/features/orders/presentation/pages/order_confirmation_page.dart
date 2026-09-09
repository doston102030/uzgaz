import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../checkout/presentation/providers/checkout_provider.dart';

class OrderConfirmationPage extends ConsumerStatefulWidget {
  const OrderConfirmationPage({super.key});

  @override
  ConsumerState<OrderConfirmationPage> createState() =>
      _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends ConsumerState<OrderConfirmationPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final order = ref.watch(lastOrderProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              _SuccessMark(controller: _controller),
              const SizedBox(height: AppDimensions.space28),
              Text(
                'Buyurtma qabul qilindi!',
                textAlign: TextAlign.center,
                style: AppTypography.title1.copyWith(color: c.textPrimary),
              ),
              const SizedBox(height: AppDimensions.space8),
              Text(
                order == null
                    ? 'Buyurtmangiz muvaffaqiyatli joylashtirildi.'
                    : '${order.companyName} buyurtmangizni tayyorlashni boshladi. '
                        'Holatini real vaqtda kuzatishingiz mumkin.',
                textAlign: TextAlign.center,
                style: AppTypography.callout.copyWith(
                  color: c.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppDimensions.space28),
              if (order != null)
                AppCard(
                  child: Column(
                    children: [
                      _SummaryLine(
                        label: 'Buyurtma raqami',
                        value: order.orderNumber,
                        emphasise: true,
                      ),
                      Divider(height: AppDimensions.space20, color: c.separator),
                      _SummaryLine(
                        label: 'Yetkazib berish',
                        value: order.deliveryMethod.labelUz,
                      ),
                      const SizedBox(height: AppDimensions.space10),
                      _SummaryLine(
                        label: order.deliveryMethod == DeliveryMethod.delivery
                            ? 'Taxminiy vaqt'
                            : 'Olib ketish',
                        value: order.deliveryMethod == DeliveryMethod.delivery
                            ? '${AppFormatters.time(order.eta)} gacha'
                            : order.companyName,
                      ),
                      Divider(height: AppDimensions.space20, color: c.separator),
                      _SummaryLine(
                        label: 'To‘langan summa',
                        value: AppFormatters.currency(order.total),
                        emphasise: true,
                      ),
                    ],
                  ),
                ),
              const Spacer(flex: 3),
              AppButton(
                label: 'Buyurtmani kuzatish',
                icon: Icons.location_searching_rounded,
                onPressed: () => context.go(
                  '/orders/${order?.id ?? 'o1'}/tracking',
                ),
              ),
              const SizedBox(height: AppDimensions.space10),
              AppButton(
                label: 'Bosh sahifaga qaytish',
                variant: AppButtonVariant.outline,
                onPressed: () => context.go('/home'),
              ),
              const SizedBox(height: AppDimensions.space20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Expanding rings behind a tick that draws itself in.
class _SuccessMark extends StatelessWidget {
  const _SuccessMark({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return SizedBox(
      width: 140,
      height: 140,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = controller.value;
          final pop = Curves.easeOutBack.transform((t * 1.6).clamp(0.0, 1.0));
          return Stack(
            alignment: Alignment.center,
            children: [
              for (int i = 0; i < 2; i++)
                Opacity(
                  opacity: ((t - i * 0.18) * 1.4).clamp(0.0, 1.0) *
                      (1 - t).clamp(0.0, 1.0),
                  child: Container(
                    width: 90 + 50 * ((t - i * 0.18).clamp(0.0, 1.0)),
                    height: 90 + 50 * ((t - i * 0.18).clamp(0.0, 1.0)),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: c.success.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              Transform.scale(
                scale: pop,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: c.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: c.success.withValues(alpha: 0.4),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 48),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.emphasise = false,
  });

  final String label;
  final String value;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.callout.copyWith(color: c.textSecondary),
          ),
        ),
        Text(
          value,
          style: emphasise
              ? AppTypography.priceSmall.copyWith(color: c.textPrimary, fontSize: 15)
              : AppTypography.callout.copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
        ),
      ],
    );
  }
}
