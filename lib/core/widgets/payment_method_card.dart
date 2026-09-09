import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/typography.dart';
import '../constants/app_constants.dart';
import 'app_surface.dart';

/// Selectable payment row. No card fields ever appear here — the app hands
/// off to the provider's tokenising SDK, so nothing sensitive is typed
/// into or stored by this screen.
class PaymentMethodCard extends StatelessWidget {
  const PaymentMethodCard({
    super.key,
    required this.method,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppCard(
      onTap: onTap,
      selected: selected,
      padding: const EdgeInsets.all(AppDimensions.space12),
      child: Row(
        children: [
          PaymentBrandMark(method: method),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.label,
                  style: AppTypography.callout.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle ?? method.hintUz,
                  style: AppTypography.caption.copyWith(color: c.textTertiary),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: AppMotion.fast,
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: selected ? c.primary : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? c.primary : c.borderStrong,
                width: 1.8,
              ),
            ),
            child: selected
                ? Icon(Icons.check_rounded, size: 14, color: c.onPrimary)
                : null,
          ),
        ],
      ),
    );
  }
}

/// Brand tile — drawn, not bitmapped, so it stays crisp in both themes.
class PaymentBrandMark extends StatelessWidget {
  const PaymentBrandMark({super.key, required this.method, this.width = 52, this.height = 36});

  final PaymentMethod method;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final (List<Color> bg, Widget mark) = switch (method) {
      PaymentMethod.visa => (
          const [Color(0xFF1A1F71), Color(0xFF2A3BA0)],
          _wordmark('VISA', italic: true, spacing: 0.6),
        ),
      PaymentMethod.mastercard => (
          const [Color(0xFF1B1B1F), Color(0xFF2E2E36)],
          const _MastercardMark(),
        ),
      PaymentMethod.uzcard => (
          const [Color(0xFF0EA5E9), Color(0xFF0369A1)],
          _wordmark('UZCARD', size: 8.5),
        ),
      PaymentMethod.humo => (
          const [Color(0xFFF97316), Color(0xFFDC2626)],
          _wordmark('HUMO', size: 10),
        ),
      PaymentMethod.payme => (
          const [Color(0xFF0B1F3A), Color(0xFF15304F)],
          _wordmark('payme', size: 11, color: const Color(0xFF33D9C0), upper: false),
        ),
      PaymentMethod.click => (
          const [Color(0xFF00A3E0), Color(0xFF0071BC)],
          _wordmark('click', size: 11, upper: false),
        ),
    };

    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bg,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: bg.last.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: mark,
    );
  }

  static Widget _wordmark(
    String text, {
    double size = 10,
    bool italic = false,
    bool upper = true,
    double spacing = 0.4,
    Color color = Colors.white,
  }) {
    return Text(
      upper ? text.toUpperCase() : text,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: spacing,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        height: 1,
      ),
    );
  }
}

class _MastercardMark extends StatelessWidget {
  const _MastercardMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 2,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFFEB001B),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFF79E1B).withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reassurance strip shown under the payment options.
class PaymentSecurityNote extends StatelessWidget {
  const PaymentSecurityNote({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space14),
      decoration: BoxDecoration(
        color: c.successSoft,
        borderRadius: AppDimensions.brMedium,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_rounded, size: 18, color: c.success),
          const SizedBox(width: AppDimensions.space10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To‘lov xavfsiz',
                  style: AppTypography.caption.copyWith(
                    color: c.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Karta ma’lumotlari ilovada saqlanmaydi — to‘lov provayderi '
                  'tomonidan shifrlangan holda amalga oshiriladi.',
                  style: AppTypography.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
