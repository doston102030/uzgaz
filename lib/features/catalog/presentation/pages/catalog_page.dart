import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/app_tappable.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../core/widgets/category_filter_bar.dart';
import '../../../../core/widgets/responsive_product_grid.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../products/presentation/providers/product_provider.dart';

class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({super.key});

  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  late final TextEditingController _searchController =
      TextEditingController(text: ref.read(searchQueryProvider));

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openSort() async {
    final current = ref.read(productSortProvider);
    final selected = await AppSheet.show<ProductSort>(
      context,
      title: 'Saralash',
      subtitle: 'Mahsulotlar qaysi tartibda ko‘rinsin?',
      child: AppSheetOptionList(
        children: [
          for (final sort in ProductSort.values)
            AppSheetOption(
              label: sort.label,
              subtitle: sort.hint,
              icon: sort.icon,
              iconColor: sort.color,
              selected: sort == current,
              onTap: () => Navigator.of(context, rootNavigator: true).pop(sort),
            ),
        ],
      ),
    );
    if (selected != null) {
      ref.read(productSortProvider.notifier).state = selected;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final products = ref.watch(filteredProductsProvider);
    final category = ref.watch(categoryFilterProvider);
    final counts = ref.watch(categoryCountsProvider);
    final sort = ref.watch(productSortProvider);
    final cartCount = ref.watch(cartCountProvider);
    // Products load from Supabase now — an empty list right after launch
    // means "still loading", not "no results", so don't show the
    // no-matches empty state (with its "clear filters" action) for that.
    final catalogueLoading = ref.watch(productsFutureProvider).isLoading;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverNavBar(
            title: 'Katalog',
            subtitle: '${products.length} ta mahsulot topildi',
            actions: [
              AppIconButton(
                icon: Icons.shopping_bag_outlined,
                badgeCount: cartCount,
                onTap: () => context.push('/cart'),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.gutter,
                AppDimensions.space8,
                AppDimensions.gutter,
                AppDimensions.space12,
              ),
              child: AppSearchField(
                hint: 'Gaz ballon, benzin, kompaniya…',
                controller: _searchController,
                onChanged: (value) =>
                    ref.read(searchQueryProvider.notifier).state = value,
                trailing: _searchController.text.isEmpty
                    ? null
                    : AppTappable(
                        onTap: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                          setState(() {});
                        },
                        child: Icon(Icons.close_rounded,
                            size: 18, color: c.textTertiary),
                      ),
              ),
            ),
          ),
          SliverPinnedBar(
            height: CategoryFilterBar.heightFor(context),
            child: CategoryFilterBar(
              selected: category,
              counts: counts,
              onSelected: (value) =>
                  ref.read(categoryFilterProvider.notifier).state = value,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.gutter,
                AppDimensions.space12,
                AppDimensions.gutter,
                AppDimensions.space12,
              ),
              child: LayoutBuilder(
                builder: (context, box) => Row(
                  children: [
                    Expanded(
                      child: Text(
                        category == null
                            ? 'Barcha mahsulotlar'
                            : category.titleUz,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headline
                            .copyWith(color: c.textPrimary),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    // Natural width, capped so a narrow screen with big
                    // text shortens the label instead of overflowing.
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: box.maxWidth * .6),
                      child: _SortButton(sort: sort, onTap: _openSort),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (products.isEmpty && catalogueLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (products.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Hech narsa topilmadi',
                subtitle:
                    'Boshqa kalit so‘z bilan qidiring yoki filtrlarni tozalang.',
                actionLabel: 'Filtrlarni tozalash',
                onAction: () {
                  _searchController.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                  ref.read(categoryFilterProvider.notifier).state = null;
                  setState(() {});
                },
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.gutter,
                0,
                AppDimensions.gutter,
                AppDimensions.bottomBarClearance,
              ),
              sliver: ResponsiveProductGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final product = products[i];
                    return ProductCard(
                      product: product,
                      badge: product.hasDiscount
                          ? '-${product.discountPercent}%'
                          : null,
                      badgeTone: PillTone.danger,
                      onTap: () => context.push('/product/${product.id}'),
                      onAdd: () {
                        ref.read(cartProvider.notifier).add(product);
                        AppToast.show(
                          context,
                          '${product.name} savatga qo‘shildi',
                          tone: ToastTone.success,
                          actionLabel: 'Savat',
                          onAction: () => context.push('/cart'),
                        );
                      },
                    );
                  },
                  childCount: products.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// How each sort order presents itself in the picker sheet.
extension _ProductSortPresentation on ProductSort {
  String get hint => switch (this) {
        ProductSort.tavsiya => 'Eng mos takliflar birinchi',
        ProductSort.arzon => 'Narx o‘sish tartibida',
        ProductSort.qimmat => 'Narx kamayish tartibida',
        ProductSort.reyting => 'Eng yuqori baholanganlar birinchi',
      };

  IconData get icon => switch (this) {
        ProductSort.tavsiya => Icons.auto_awesome_rounded,
        ProductSort.arzon => Icons.trending_down_rounded,
        ProductSort.qimmat => Icons.trending_up_rounded,
        ProductSort.reyting => Icons.star_rounded,
      };

  Color get color => switch (this) {
        ProductSort.tavsiya => AppColors.primary,
        ProductSort.arzon => AppColors.success,
        ProductSort.qimmat => AppColors.energyFlame,
        ProductSort.reyting => AppColors.energyAmber,
      };
}

/// The catalogue's single sort control: a pill showing the active order.
/// Turns primary-tinted once the user leaves the default, so a non-default
/// ordering is never invisible.
class _SortButton extends StatelessWidget {
  const _SortButton({required this.sort, required this.onTap});

  final ProductSort sort;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final active = sort != ProductSort.tavsiya;
    final fg = active ? c.primary : c.textPrimary;

    return Semantics(
      button: true,
      label: 'Saralash: ${sort.label}',
      excludeSemantics: true,
      child: AppTappable(
        onTap: onTap,
        pressedScale: 0.95,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          height: 34,
          padding: const EdgeInsets.only(
            left: AppDimensions.space10,
            right: AppDimensions.space8,
          ),
          decoration: BoxDecoration(
            color: active ? c.primarySoft : c.surface,
            borderRadius: AppDimensions.brPill,
            border: Border.all(
              color: active ? c.primary.withValues(alpha: 0.35) : c.border,
            ),
            boxShadow: active ? null : c.shadowSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swap_vert_rounded, size: 16, color: c.primary),
              const SizedBox(width: AppDimensions.space4),
              Flexible(
                child: Text(
                  sort.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
