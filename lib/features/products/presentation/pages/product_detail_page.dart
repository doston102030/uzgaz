import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_tappable.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/product_illustration.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/product_gallery.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  const ProductDetailPage({super.key, required this.productId});
  final String productId;

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  int _quantity = 1;
  bool _favourite = false;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final product = ref.watch(productByIdProvider(widget.productId));
    if (product == null) {
      return Scaffold(
        body: SafeArea(
          child: EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Mahsulot topilmadi',
            subtitle: 'Ehtimol u katalogdan olib tashlangan.',
            actionLabel: 'Orqaga',
            onAction: () => context.pop(),
          ),
        ),
      );
    }
    final surface = c.isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final gallerySurface =
        c.isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F5F7);
    final total = product.price * _quantity;
    final description = product.description?.trim() ?? '';

    return Scaffold(
      backgroundColor: surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight:
                (MediaQuery.sizeOf(context).height * 0.52).clamp(340.0, 500.0),
            backgroundColor: gallerySurface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leadingWidth: 64,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Center(
                child: _CircleAction(
                  label: 'Orqaga',
                  icon: CupertinoIcons.chevron_back,
                  onTap: () => context.pop(),
                ),
              ),
            ),
            actions: [
              _CircleAction(
                label: _favourite
                    ? 'Sevimlilardan olib tashlash'
                    : 'Sevimlilarga qo‘shish',
                icon: _favourite
                    ? CupertinoIcons.heart_fill
                    : CupertinoIcons.heart,
                foreground: _favourite ? c.danger : null,
                onTap: () => setState(() => _favourite = !_favourite),
              ),
              const SizedBox(width: 8),
              _CircleAction(
                label: 'Havolani nusxalash',
                icon: CupertinoIcons.square_arrow_up,
                onTap: () async {
                  await Clipboard.setData(ClipboardData(
                    text: Uri.base
                        .replace(fragment: '/product/${product.id}')
                        .toString(),
                  ));
                  if (context.mounted) {
                    AppToast.show(context, 'Havola nusxalandi');
                  }
                },
              ),
              const SizedBox(width: 16),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: ProductGallery(
                images: product.gallery,
                visual: EnergyVisualX.fromCategory(product.categoryId,
                    name: product.name),
                safeTop: MediaQuery.paddingOf(context).top,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.isAvailable
                        ? 'Sotuvda mavjud'
                        : 'Hozircha mavjud emas',
                    style: AppTypography.caption.copyWith(
                      color: product.isAvailable ? c.success : c.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(product.name,
                      style: AppTypography.title1.copyWith(
                        color: c.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.7,
                        height: 1.15,
                      )),
                  const SizedBox(height: 12),
                  if (product.reviewCount > 0)
                    Row(children: [
                      Icon(CupertinoIcons.star_fill, size: 13, color: c.star),
                      const SizedBox(width: 5),
                      Text(
                          '${product.rating.toStringAsFixed(1)}  ·  ${product.reviewCount} ta sharh',
                          style: AppTypography.caption
                              .copyWith(color: c.textSecondary)),
                    ])
                  else
                    Text('Hozircha sharhlar yo‘q',
                        style: AppTypography.caption
                            .copyWith(color: c.textTertiary)),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(AppFormatters.currency(product.price),
                          style: AppTypography.title1.copyWith(
                              color: c.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.8)),
                      if (product.hasDiscount)
                        Text(AppFormatters.currency(product.oldPrice!),
                            style: AppTypography.callout.copyWith(
                                color: c.textTertiary,
                                decoration: TextDecoration.lineThrough)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('1 ${product.unit} uchun',
                      style: AppTypography.caption
                          .copyWith(color: c.textTertiary)),
                  const SizedBox(height: 24),
                  Divider(height: 1, thickness: 0.5, color: c.separator),
                  AppTappable(
                    onTap: () => context.push('/companies'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(children: [
                        Icon(CupertinoIcons.building_2_fill,
                            size: 25, color: c.textSecondary),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('Sotuvchi',
                                  style: AppTypography.caption
                                      .copyWith(color: c.textTertiary)),
                              const SizedBox(height: 3),
                              Text(product.companyName,
                                  style: AppTypography.callout.copyWith(
                                      color: c.textPrimary,
                                      fontWeight: FontWeight.w600)),
                            ])),
                        Icon(CupertinoIcons.chevron_forward,
                            size: 16, color: c.textTertiary),
                      ]),
                    ),
                  ),
                  Divider(height: 1, thickness: 0.5, color: c.separator),
                  if (description.isNotEmpty &&
                      description != 'Tavsif kiritilmagan.') ...[
                    const SizedBox(height: 24),
                    Text('Mahsulot haqida',
                        style: AppTypography.headline
                            .copyWith(color: c.textPrimary)),
                    const SizedBox(height: 10),
                    Text(description,
                        style: AppTypography.body
                            .copyWith(color: c.textSecondary, height: 1.5)),
                  ],
                  if (product.specs.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Xususiyatlari',
                        style: AppTypography.headline
                            .copyWith(color: c.textPrimary)),
                    const SizedBox(height: 10),
                    for (final entry in product.specs.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  child: Text(entry.key,
                                      style: AppTypography.callout
                                          .copyWith(color: c.textSecondary))),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: Text(entry.value,
                                      textAlign: TextAlign.end,
                                      style: AppTypography.callout
                                          .copyWith(color: c.textPrimary))),
                            ]),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
            color: surface,
            border: Border(top: BorderSide(color: c.separator, width: 0.5))),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(children: [
              Container(
                decoration: BoxDecoration(
                    color: gallerySurface,
                    borderRadius: BorderRadius.circular(14)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _QuantityAction(
                      icon: CupertinoIcons.minus,
                      label: 'Kamaytirish',
                      onTap: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null),
                  Text('$_quantity',
                      style: AppTypography.callout.copyWith(
                          color: c.textPrimary, fontWeight: FontWeight.w600)),
                  _QuantityAction(
                      icon: CupertinoIcons.plus,
                      label: 'Ko‘paytirish',
                      onTap: _quantity < 99
                          ? () => setState(() => _quantity++)
                          : null),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  color: c.primary,
                  borderRadius: BorderRadius.circular(14),
                  onPressed: product.isAvailable
                      ? () {
                          for (var i = 0; i < _quantity; i++) {
                            ref.read(cartProvider.notifier).add(product);
                          }
                          AppToast.show(context, 'Savatga qo‘shildi',
                              tone: ToastTone.success);
                          context.push('/cart');
                        }
                      : null,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                        product.isAvailable
                            ? 'Savatga qo‘shish'
                            : 'Mavjud emas',
                        textAlign: TextAlign.center,
                        style: AppTypography.callout.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                    if (product.isAvailable)
                      Text(AppFormatters.currency(total),
                          style: AppTypography.caption2.copyWith(
                              color: Colors.white.withValues(alpha: 0.85))),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction(
      {required this.label,
      required this.icon,
      required this.onTap,
      this.foreground});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? foreground;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        button: true,
        child: AppTappable(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.palette.isDark
                    ? const Color(0xFF2C2C2E)
                    : Colors.white),
            child: Icon(icon,
                size: 20, color: foreground ?? context.palette.textPrimary),
          ),
        ),
      );
}

class _QuantityAction extends StatelessWidget {
  const _QuantityAction({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        button: true,
        enabled: onTap != null,
        child: AppTappable(
          onTap: onTap,
          child: SizedBox(
              width: 40,
              height: 52,
              child: Icon(icon,
                  size: 16,
                  color: onTap == null
                      ? context.palette.textTertiary
                      : context.palette.textPrimary)),
        ),
      );
}
