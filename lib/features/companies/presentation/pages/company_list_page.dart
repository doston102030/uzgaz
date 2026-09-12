import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/company_card.dart';
import '../../../checkout/presentation/providers/checkout_provider.dart';
import '../../domain/entities/company.dart';
import '../providers/company_provider.dart';

/// "5–6 kompaniyani solishtirish": price, distance, rating, availability
/// and delivery, sorted by the filter the buyer cares about.
class CompanyListPage extends ConsumerWidget {
  const CompanyListPage({super.key, this.productName});

  final String? productName;

  IconData _sortIcon(CompanySortOption option) => switch (option) {
        CompanySortOption.engYaqin => Icons.near_me_rounded,
        CompanySortOption.engArzon => Icons.savings_rounded,
        CompanySortOption.reyting => Icons.star_rounded,
        CompanySortOption.narx => Icons.payments_rounded,
        CompanySortOption.masofa => Icons.route_rounded,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final companies = ref.watch(sortedCompaniesProvider);
    final currentSort = ref.watch(companySortProvider);
    final highlights = ref.watch(companyHighlightsProvider);
    final selected = ref.watch(selectedCompanyProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverNavBar(
            title: 'Kompaniyalar',
            subtitle: productName == null
                ? '${companies.length} ta taklif solishtirilmoqda'
                : '$productName uchun ${companies.length} ta taklif',
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.gutter,
                AppDimensions.space8,
                AppDimensions.gutter,
                AppDimensions.space4,
              ),
              child: _CompaniesHeaderBanner(count: companies.length),
            ),
          ),
          SliverPinnedBar(
            height: AppDimensions.chipHeight + 14,
            child: Align(
              alignment: Alignment.topCenter,
              child: AppChoiceChips<CompanySortOption>(
                items: CompanySortOption.values,
                value: currentSort,
                labelOf: (option) => option.label,
                iconOf: _sortIcon,
                onChanged: (option) =>
                    ref.read(companySortProvider.notifier).state = option,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.gutter,
                AppDimensions.space12,
                AppDimensions.gutter,
                AppDimensions.space4,
              ),
              child: _ComparisonSummary(companies: companies),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.gutter,
              AppDimensions.space12,
              AppDimensions.gutter,
              AppDimensions.space32,
            ),
            sliver: SliverList.separated(
              itemCount: companies.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimensions.space12),
              itemBuilder: (context, i) {
                final company = companies[i];
                return CompanyCard(
                  company: company,
                  selected: selected?.id == company.id,
                  highlight: highlights.labelFor(company.id),
                  highlightTone: company.id == highlights.cheapestId
                      ? PillTone.success
                      : PillTone.primary,
                  onTap: () =>
                      ref.read(selectedCompanyProvider.notifier).state = company,
                  onSelect: () {
                    ref.read(selectedCompanyProvider.notifier).state = company;
                    context.push('/delivery-method', extra: company);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: selected == null
          ? null
          : Container(
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.separator)),
                boxShadow: c.shadowLg,
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.gutter),
                  child: Row(
                    children: [
                      CompanyLogo(name: selected.name, size: 42),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.callout.copyWith(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Jami ${AppFormatters.currency(selected.totalPrice)}',
                              style: AppTypography.caption
                                  .copyWith(color: c.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      AppButton(
                        label: 'Davom etish',
                        expand: false,
                        size: AppButtonSize.medium,
                        onPressed: () =>
                            context.push('/delivery-method', extra: selected),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

/// "🏢 gaz bilan ishlaydigan kompaniyalar" — a real-photo header so this
/// reads as a B2B directory of licensed energy enterprises, not a plain
/// list. Photo credit: `ASSETS_ATTRIBUTION.md`.
class _CompaniesHeaderBanner extends StatelessWidget {
  const _CompaniesHeaderBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return ClipRRect(
      borderRadius: AppDimensions.brXLarge,
      child: SizedBox(
        height: 112,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl:
                  'https://haurszcvivpqdyenfwbb.supabase.co/storage/v1/object/public/product-images/categories/companies-header.jpg',
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: c.surfaceMuted),
              errorWidget: (_, __, ___) => Container(color: c.surfaceMuted),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Andijon gaz va energiya korxonalari',
                    style: AppTypography.headline.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count ta sertifikatlangan hamkor · litsenziyalangan yetkazib beruvchilar',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The three numbers that decide the purchase, extracted above the list
/// so comparing does not require reading every card.
class _ComparisonSummary extends StatelessWidget {
  const _ComparisonSummary({required this.companies});

  final List<Company> companies;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final available = companies.where((company) => company.isAvailable).toList();
    if (available.isEmpty) return const SizedBox.shrink();

    final cheapest =
        available.reduce((a, b) => a.totalPrice <= b.totalPrice ? a : b);
    final nearest =
        available.reduce((a, b) => a.distanceKm <= b.distanceKm ? a : b);
    final fastest =
        available.reduce((a, b) => a.etaMinutes <= b.etaMinutes ? a : b);

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space12,
        vertical: AppDimensions.space14,
      ),
      color: c.isDark ? c.surfaceMuted : c.surface,
      child: Row(
        children: [
          _SummaryCell(
            icon: Icons.savings_rounded,
            tone: c.success,
            label: 'Eng arzon',
            value: AppFormatters.currencyShort(cheapest.totalPrice),
            caption: cheapest.name,
          ),
          _cellDivider(c.border),
          _SummaryCell(
            icon: Icons.near_me_rounded,
            tone: c.primary,
            label: 'Eng yaqin',
            value: AppFormatters.distance(nearest.distanceKm),
            caption: nearest.name,
          ),
          _cellDivider(c.border),
          _SummaryCell(
            icon: Icons.bolt_rounded,
            tone: AppColors.energyAmber,
            label: 'Eng tez',
            value: AppFormatters.eta(fastest.etaMinutes),
            caption: fastest.name,
          ),
        ],
      ),
    );
  }

  Widget _cellDivider(Color color) => Container(
        width: 1,
        height: 42,
        color: color,
        margin: const EdgeInsets.symmetric(horizontal: AppDimensions.space6),
      );
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.icon,
    required this.tone,
    required this.label,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final Color tone;
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: tone),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption2.copyWith(
                    color: c.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.priceSmall.copyWith(color: c.textPrimary, fontSize: 13),
          ),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption2.copyWith(color: c.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
