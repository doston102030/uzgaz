import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/typography.dart';
import '../../features/companies/domain/entities/company.dart';
import '../utils/formatters.dart';
import 'app_button.dart';
import 'app_segmented_control.dart';
import 'app_surface.dart';
import 'company_card.dart';
import 'rating_widget.dart';

/// Card in the horizontal carousel that floats over the map. Keeps the
/// map readable: one company, the three numbers that decide a purchase,
/// and a single action.
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

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppCard(
      onTap: onTap,
      selected: selected,
      elevation: AppElevation.md,
      width: width,
      padding: const EdgeInsets.all(AppDimensions.space12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CompanyLogo(name: company.name, size: 40),
              const SizedBox(width: AppDimensions.space10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.callout.copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    RatingWidget(
                      rating: company.rating,
                      reviewCount: company.reviewCount,
                      size: 11,
                    ),
                  ],
                ),
              ),
              AppPill(
                label: company.isAvailable ? 'Ochiq' : 'Yopiq',
                tone: company.isAvailable ? PillTone.success : PillTone.neutral,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space10),
          Row(
            children: [
              _MiniStat(
                icon: Icons.route_rounded,
                label: AppFormatters.distance(company.distanceKm),
              ),
              const SizedBox(width: AppDimensions.space12),
              _MiniStat(
                icon: Icons.schedule_rounded,
                label: AppFormatters.eta(company.etaMinutes),
              ),
              const SizedBox(width: AppDimensions.space12),
              _MiniStat(
                icon: Icons.access_time_rounded,
                label: company.workingHours,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppFormatters.currency(company.productPrice),
                      style: AppTypography.priceSmall.copyWith(color: c.textPrimary),
                    ),
                    Text(
                      company.deliveryFee == 0
                          ? 'Yetkazish bepul'
                          : '+ ${AppFormatters.currencyShort(company.deliveryFee)} yetkazish',
                      style: AppTypography.caption2.copyWith(color: c.textTertiary),
                    ),
                  ],
                ),
              ),
              AppButton(
                label: 'Tanlash',
                size: AppButtonSize.small,
                expand: false,
                onPressed: company.isAvailable ? (onSelect ?? onTap) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c.textTertiary),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption2.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
