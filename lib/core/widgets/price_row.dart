import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/typography.dart';
import '../utils/formatters.dart';

/// One line of an order summary. Delivery is always shown as its own row
/// (a product rule), and the total is visually separated.
class PriceRow extends StatelessWidget {
  const PriceRow({
    super.key,
    required this.label,
    required this.amount,
    this.isTotal = false,
    this.isFree = false,
    this.hint,
    this.valueColor,
  });

  final String label;
  final int amount;
  final bool isTotal;
  final bool isFree;
  final String? hint;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;

    final labelStyle = isTotal
        ? AppTypography.headline.copyWith(color: c.textPrimary)
        : AppTypography.callout.copyWith(color: c.textSecondary);

    final valueStyle = isTotal
        ? AppTypography.priceLarge.copyWith(fontSize: 22, color: c.textPrimary)
        : AppTypography.priceSmall.copyWith(
            color: valueColor ?? (isFree ? c.success : c.textPrimary),
          );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTotal ? AppDimensions.space6 : AppDimensions.space6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle),
                if (hint != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      hint!,
                      style: AppTypography.caption.copyWith(color: c.textTertiary),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          Text(
            isFree ? 'Bepul' : AppFormatters.currency(amount),
            style: valueStyle,
          ),
        ],
      ),
    );
  }
}

/// Dashed rule between the line items and the total.
class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key, this.height = 1, this.dash = 5, this.gap = 4});

  final double height;
  final double dash;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / (dash + gap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => SizedBox(
              width: dash,
              height: height,
              child: DecoratedBox(decoration: BoxDecoration(color: c.borderStrong)),
            ),
          ),
        );
      },
    );
  }
}
