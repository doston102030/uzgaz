import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/company_card.dart';
import '../../../../core/widgets/service_card.dart';
import '../../../companies/presentation/providers/company_provider.dart';
import '../../../products/presentation/providers/product_provider.dart';

/// "Elektr quvvatlash" — the service screen defined in the spec: title,
/// subtitle, "Xizmat turini tanlang" with six cards, and the highlighted
/// "Aholi uchun · SUYULTIRILGAN GAZ" promo with its "Aktiv" badge.
class ElectricChargingPage extends ConsumerWidget {
  const ElectricChargingPage({super.key});

  static const _services = [
    (
      title: 'Elektr',
      subtitle: 'Tezkor quvvatlash',
      icon: Icons.bolt_rounded,
      color: AppColors.energyElectric,
      category: ServiceCategory.elektrQuvvatlash,
      badge: 'Yangi',
    ),
    (
      title: 'Benzin',
      subtitle: 'AI-92, AI-95, AI-98',
      icon: Icons.local_gas_station_rounded,
      color: AppColors.energyAmber,
      category: ServiceCategory.benzin,
      badge: null,
    ),
    (
      title: 'Metan gaz',
      subtitle: 'Siqilgan gaz',
      icon: Icons.air_rounded,
      color: AppColors.energyMint,
      category: ServiceCategory.metanGaz,
      badge: null,
    ),
    (
      title: 'Propan gaz',
      subtitle: 'Suyultirilgan gaz',
      icon: Icons.whatshot_rounded,
      color: AppColors.energyFlame,
      category: ServiceCategory.propanGaz,
      badge: null,
    ),
    (
      title: 'Dizel',
      subtitle: 'Yevro-5 dizel',
      icon: Icons.local_shipping_rounded,
      color: AppColors.energySlate,
      category: ServiceCategory.dizel,
      badge: null,
    ),
    (
      title: 'Market',
      subtitle: 'Yo‘l do‘konlari',
      icon: Icons.storefront_rounded,
      color: AppColors.info,
      category: ServiceCategory.market,
      badge: null,
    ),
  ];

  void _openCategory(BuildContext context, WidgetRef ref, ServiceCategory category) {
    ref.read(categoryFilterProvider.notifier).state = category;
    context.go('/catalog');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final stations = ref.watch(sortedCompaniesProvider).take(3).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const AppSliverNavBar(
            title: 'Elektr quvvatlash',
            subtitle: 'Shahardagi barcha stansiyalar',
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppDimensions.gutter,
              AppDimensions.space12,
              AppDimensions.gutter,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.ev_station_rounded,
                      value: '24',
                      label: 'Stansiya',
                      tone: AppColors.energyElectric,
                    ),
                  ),
                  SizedBox(width: AppDimensions.space10),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.bolt_rounded,
                      value: '60 kVt',
                      label: 'Maks. quvvat',
                      tone: AppColors.energyAmber,
                    ),
                  ),
                  SizedBox(width: AppDimensions.space10),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.schedule_rounded,
                      value: '30 daq',
                      label: '0→80%',
                      tone: AppColors.energyMint,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SectionHeader(title: 'Xizmat turini tanlang'),
          ),
          SliverPadding(
            padding: AppDimensions.pagePadding,
            sliver: SliverList.separated(
              itemCount: _services.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimensions.space10),
              itemBuilder: (context, i) {
                final service = _services[i];
                return ServiceCard(
                  title: service.title,
                  subtitle: service.subtitle,
                  icon: service.icon,
                  color: service.color,
                  badge: service.badge,
                  onTap: () => _openCategory(context, ref, service.category),
                );
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.gutter,
              AppDimensions.space24,
              AppDimensions.gutter,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: HighlightServiceCard(
                onTap: () => _openCategory(
                  context,
                  ref,
                  ServiceCategory.suyultirilganGaz,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Yaqin stansiyalar',
              actionLabel: 'Xaritada',
              onAction: () => context.go('/map'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.gutter,
              0,
              AppDimensions.gutter,
              AppDimensions.space40,
            ),
            sliver: SliverList.separated(
              itemCount: stations.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimensions.space10),
              itemBuilder: (context, i) {
                final station = stations[i];
                return AppCard(
                  onTap: () => context.push('/companies'),
                  padding: const EdgeInsets.all(AppDimensions.space12),
                  child: Row(
                    children: [
                      CompanyLogo(name: station.name, size: 42),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              station.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.callout.copyWith(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${AppFormatters.distance(station.distanceKm)} · ${station.workingHours}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption
                                  .copyWith(color: c.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      AppPill(
                        label: station.isAvailable ? 'Bo‘sh' : 'Band',
                        tone: station.isAvailable
                            ? PillTone.success
                            : PillTone.warning,
                        dense: true,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space10,
        vertical: AppDimensions.space14,
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: c.tint(tone, 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: tone),
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.headline.copyWith(color: c.textPrimary),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption2.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    );
  }
}
