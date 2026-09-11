import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/typography.dart';
import '../../features/companies/domain/entities/company.dart';
import '../utils/formatters.dart';
import 'app_button.dart';
import 'app_segmented_control.dart';
import 'app_surface.dart';
import 'rating_widget.dart';

/// Comparison card for the "5–6 kompaniya" screen. Every number a buyer
/// compares on — price, delivery fee, distance, ETA, hours, rating,
/// availability — is on one card, in a fixed order, so scanning down the
/// list compares like with like.
class CompanyCard extends StatelessWidget {
  const CompanyCard({
    super.key,
    required this.company,
    required this.onSelect,
    this.onTap,
    this.highlight,
    this.highlightTone = PillTone.success,
    this.selected = false,
  });

  final Company company;
  final VoidCallback onSelect;
  final VoidCallback? onTap;

  /// "Eng arzon" / "Eng yaqin" / "Eng yuqori reyting" ribbon.
  final String? highlight;
  final PillTone highlightTone;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final total = company.productPrice + company.deliveryFee;

    return AppCard(
      onTap: onTap,
      selected: selected,
      padding: const EdgeInsets.all(AppDimensions.space14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompanyLogo(name: company.name, size: 46),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            company.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headline.copyWith(color: c.textPrimary),
                          ),
                        ),
                        if (highlight != null) ...[
                          const SizedBox(width: AppDimensions.space6),
                          AppPill(label: highlight!, tone: highlightTone, dense: true),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: RatingWidget(
                            rating: company.rating,
                            reviewCount: company.reviewCount,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space8),
                        Container(width: 3, height: 3, decoration: BoxDecoration(color: c.textTertiary, shape: BoxShape.circle)),
                        const SizedBox(width: AppDimensions.space8),
                        Flexible(
                          child: Text(
                            AppFormatters.distance(company.distanceKm),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(color: c.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppPill(
                label: company.isAvailable ? 'Mavjud' : 'Band',
                tone: company.isAvailable ? PillTone.success : PillTone.neutral,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space12,
              vertical: AppDimensions.space10,
            ),
            decoration: BoxDecoration(
              color: c.isDark ? c.surfaceMuted : c.backgroundSunken,
              borderRadius: AppDimensions.brSmall,
            ),
            child: Row(
              children: [
                _Metric(
                  icon: Icons.route_rounded,
                  label: AppFormatters.distance(company.distanceKm),
                  caption: 'masofa',
                ),
                _MetricDivider(),
                _Metric(
                  icon: Icons.schedule_rounded,
                  label: AppFormatters.eta(company.etaMinutes),
                  caption: 'yetkazish',
                ),
                _MetricDivider(),
                _Metric(
                  icon: Icons.access_time_rounded,
                  label: company.workingHours,
                  caption: 'ish vaqti',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppFormatters.currency(company.productPrice),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.price.copyWith(color: c.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.local_shipping_rounded,
                          size: 13,
                          color: company.deliveryFee == 0 ? c.success : c.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            company.deliveryFee == 0
                                ? 'Yetkazish bepul'
                                : '+ ${AppFormatters.currency(company.deliveryFee)} yetkazish',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: company.deliveryFee == 0 ? c.success : c.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Jami: ${AppFormatters.currency(total)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption2.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              AppButton(
                label: selected ? 'Tanlandi' : 'Tanlash',
                icon: selected ? Icons.check_rounded : null,
                size: AppButtonSize.small,
                expand: false,
                variant: selected ? AppButtonVariant.ghost : AppButtonVariant.primary,
                onPressed: company.isAvailable ? onSelect : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.caption});

  final IconData icon;
  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 15, color: c.primary),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: c.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            caption,
            style: AppTypography.caption2.copyWith(color: c.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      width: 1,
      height: 30,
      color: c.border,
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.space8),
    );
  }
}

/// Monogram logo tile — a stable stand-in until real company logos exist,
/// tinted deterministically from the name so each brand keeps its colour.
class CompanyLogo extends StatelessWidget {
  const CompanyLogo({super.key, required this.name, this.size = 44, this.radius, this.logoUrl});

  final String name;
  final double size;
  final double? radius;

  /// Real logo (Supabase Storage `company-logos` bucket) — falls back to
  /// the gradient-initials avatar below when null or still loading.
  final String? logoUrl;

  static const List<List<Color>> _ramps = [
    [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    [Color(0xFFF97316), Color(0xFFEA580C)],
    [Color(0xFF10B981), Color(0xFF047857)],
    [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    [Color(0xFFE11D48), Color(0xFFBE123C)],
    [Color(0xFF0EA5E9), Color(0xFF0369A1)],
  ];

  @override
  Widget build(BuildContext context) {
    final ramp = _ramps[name.hashCode.abs() % _ramps.length];
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.characters.first.toUpperCase())
        .join();

    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: ramp,
        ),
        borderRadius: BorderRadius.circular(radius ?? size * 0.32),
        boxShadow: [
          BoxShadow(
            color: ramp.last.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        initials,
        style: AppTypography.headline.copyWith(
          color: Colors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    if (logoUrl == null) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? size * 0.32),
      child: CachedNetworkImage(
        imageUrl: logoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}
