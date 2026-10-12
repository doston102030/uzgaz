import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/typography.dart';
import '../../features/companies/domain/entities/company.dart';
import '../utils/formatters.dart';
import 'app_button.dart';
import 'app_surface.dart';
import 'company_card.dart';
import 'price_row.dart';
import 'rating_widget.dart';

/// Card in the horizontal carousel that floats over the map. Keeps the
/// map readable: one company, the three numbers that decide a purchase,
/// and a single action.
///
/// The carousel hands it a fixed-height slot, so the three rows spread
/// evenly across whatever height it gets instead of bunching at the top;
/// with loose constraints it shrinks to its content.
class MapCompanyCard extends StatelessWidget {
  const MapCompanyCard({
    super.key,
    required this.company,
    required this.onTap,
    this.onSelect,
    this.selected = false,
    this.width = 268,
  });

  final Company company;
  final VoidCallback onTap;
  final VoidCallback? onSelect;
  final bool selected;
  final double width;

  /// Includes the carousel's 12 px vertical space around the card.
  static double slotHeightFor(BuildContext context) =>
      152 +
      (MediaQuery.textScalerOf(context).scale(14) - 14)
              .clamp(0, double.infinity) *
          7;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppCard(
      onTap: onTap,
      selected: selected,
      elevation: AppElevation.sm,
      width: width,
      padding: const EdgeInsets.all(AppDimensions.space10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CompanyLogo(name: company.name, size: 32),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headline.copyWith(
                        color: c.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RatingWidget(
                            rating: company.rating,
                            reviewCount: company.reviewCount,
                            size: 12,
                          ),
                          const SizedBox(width: AppDimensions.space8),
                          _OpenStatus(open: company.isAvailable),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space6),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: c.isDark ? c.surfaceMuted : c.background,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusXSmall + 2),
            ),
            // Evenly spread; the hours slot is wider because "08:00–22:00"
            // is the longest figure.
            child: Row(
              children: [
                _MiniStat(
                  icon: Icons.near_me_rounded,
                  label: AppFormatters.distance(company.distanceKm),
                  flex: 2,
                ),
                const _StatDivider(),
                _MiniStat(
                  icon: Icons.local_shipping_outlined,
                  label: AppFormatters.eta(company.etaMinutes),
                  flex: 2,
                ),
                const _StatDivider(),
                _MiniStat(
                  icon: Icons.access_time_rounded,
                  // "08:00 - 22:00" -> "08:00–22:00": same info, narrower.
                  label:
                      company.workingHours.replaceAll(RegExp(r'\s*-\s*'), '–'),
                  flex: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space6),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PriceText(company.productPrice),
                    const SizedBox(height: 1),
                    Text(
                      company.deliveryFee == 0
                          ? 'Yetkazish bepul'
                          : '+ ${AppFormatters.currencyShort(company.deliveryFee)} yetkazish',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: company.deliveryFee == 0
                            ? c.success
                            : c.textSecondary,
                        fontWeight: company.deliveryFee == 0
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AppButton(
                    label: 'Tanlash',
                    size: AppButtonSize.small,
                    expand: false,
                    onPressed: company.isAvailable ? (onSelect ?? onTap) : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "● Ochiq" / "● Yopiq" — sits beside the rating so the company name
/// gets the card's full width.
class _OpenStatus extends StatelessWidget {
  const _OpenStatus({required this.open});

  final bool open;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final color = open ? c.success : c.textTertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          open ? 'Ochiq' : 'Yopiq',
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// One figure in the stats strip, centred in its [flex] share of the row.
/// Scales down rather than cutting off — working hours must stay readable
/// in full.
class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label, this.flex = 1});

  final IconData icon;
  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Expanded(
      flex: flex,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: c.primary),
            const SizedBox(width: 4),
            Text(
              label,
              maxLines: 1,
              style: AppTypography.caption.copyWith(
                color: c.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.space6),
      color: context.palette.borderStrong,
    );
  }
}
