import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final sort in ProductSort.values)
            _SortRow(
              label: sort.label,
              selected: sort == current,
              onTap: () => Navigator.of(context).pop(sort),
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverNavBar(
            title: 'Katalog',
            subtitle: '${products.length} ta mahsulot topildi',
            showBack: false,
            actions: [
              AppIconButton(
                icon: Icons.swap_vert_rounded,
                onTap: _openSort,
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
            height: AppDimensions.chipHeight + 14,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: AppDimensions.chipHeight + 4,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: AppDimensions.pagePadding,
                  children: [
                    AppChip(
                      label: 'Barchasi',
                      selected: category == null,
                      onTap: () =>
                          ref.read(categoryFilterProvider.notifier).state = null,
                    ),
                    for (final item in ServiceCategory.values)
                      Padding(
                        padding: const EdgeInsets.only(left: AppDimensions.space8),
                        child: AppChip(
                          label: '${item.titleUz} · ${counts[item] ?? 0}',
                          icon: item.icon,
                          selected: category == item,
                          onTap: () => ref
                              .read(categoryFilterProvider.notifier)
                              .state = item,
                        ),
                      ),
                  ],
                ),
              ),
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
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      category == null
                          ? 'Barcha mahsulotlar'
                          : category.titleUz,
                      style: AppTypography.headline.copyWith(color: c.textPrimary),
                    ),
                  ),
                  AppTappable(
                    onTap: _openSort,
                    child: Row(
                      children: [
                        Icon(Icons.swap_vert_rounded, size: 16, color: c.primary),
                        const SizedBox(width: 4),
                        Text(
                          sort.label,
                          style: AppTypography.caption.copyWith(
                            color: c.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (products.isEmpty)
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
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppDimensions.space12,
                  crossAxisSpacing: AppDimensions.space12,
                  childAspectRatio: 0.60,
                ),
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

class _SortRow extends StatelessWidget {
  const _SortRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppTappable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.gutter,
          vertical: AppDimensions.space16,
        ),
        color: Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.body.copyWith(
                  color: c.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (selected) Icon(Icons.check_rounded, color: c.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
