import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_image_picker_field.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/app_select_field.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../providers/seller_provider.dart';

/// Add / edit form. Editing an approved product resets it back to
/// [ProductModerationStatus.pending] — a changed price or description is
/// reviewed again before it goes live, same rule a real marketplace uses.
class AddEditProductPage extends ConsumerStatefulWidget {
  const AddEditProductPage({super.key, this.productId});

  final String? productId;

  bool get isEditing => productId != null;

  @override
  ConsumerState<AddEditProductPage> createState() => _AddEditProductPageState();
}

class _AddEditProductPageState extends ConsumerState<AddEditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _oldPriceController = TextEditingController();
  final _stockController = TextEditingController(text: '10');

  ServiceCategory _category = ServiceCategory.gazBallon;
  String _unit = 'dona';
  String? _imageUrl;
  bool _loaded = false;
  bool _submitting = false;

  static const _units = ['dona', 'litr', 'kg', 'm³', 'kVt·s'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded || !widget.isEditing) {
      _loaded = true;
      return;
    }
    final product = ref
        .read(sellerProductsProvider)
        .where((p) => p.id == widget.productId)
        .firstOrNull;
    if (product != null) {
      _nameController.text = product.name;
      _descriptionController.text = product.description;
      _priceController.text = product.price.toString();
      if (product.oldPrice != null) _oldPriceController.text = product.oldPrice.toString();
      _stockController.text = product.stockQty.toString();
      _category = product.category;
      _unit = product.unit;
      _imageUrl = product.imageUrl;
    }
    _loaded = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _oldPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    final picked = await AppPickerSheet.show<ServiceCategory>(
      context,
      title: 'Kategoriya',
      options: ServiceCategory.values,
      labelOf: (c) => c.titleUz,
      iconOf: (c) => c.icon,
      selected: _category,
    );
    if (picked != null) setState(() => _category = picked);
  }

  Future<void> _pickUnit() async {
    final picked = await AppPickerSheet.show<String>(
      context,
      title: 'O‘lchov birligi',
      options: _units,
      labelOf: (u) => u,
      selected: _unit,
    );
    if (picked != null) setState(() => _unit = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final seller = ref.read(currentSellerProvider);
    if (seller == null) return;

    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final price = int.parse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    final oldPriceText = _oldPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final stock = int.tryParse(_stockController.text) ?? 0;

    if (widget.isEditing) {
      final existing =
          ref.read(sellerProductsProvider).where((p) => p.id == widget.productId).firstOrNull;
      if (existing != null) {
        ref.read(sellerProductsProvider.notifier).update(
              existing.copyWith(
                name: _nameController.text.trim(),
                category: _category,
                description: _descriptionController.text.trim(),
                price: price,
                oldPrice: oldPriceText.isEmpty ? null : int.parse(oldPriceText),
                stockQty: stock,
                unit: _unit,
                imageUrl: _imageUrl,
              ),
            );
      }
    } else {
      ref.read(sellerProductsProvider.notifier).add(
            sellerId: seller.id,
            name: _nameController.text.trim(),
            category: _category,
            description: _descriptionController.text.trim(),
            price: price,
            oldPrice: oldPriceText.isEmpty ? null : int.parse(oldPriceText),
            stockQty: stock,
            unit: _unit,
            imageUrl: _imageUrl,
          );
    }

    if (!mounted) return;
    setState(() => _submitting = false);
    AppToast.show(
      context,
      widget.isEditing
          ? 'O‘zgarishlar saqlandi — qayta moderatsiyaga yuborildi'
          : 'Mahsulot qo‘shildi — moderatsiyada',
      tone: ToastTone.success,
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final sellerId = ref.watch(currentSellerProvider)?.id;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverNavBar(
            title: widget.isEditing ? 'Mahsulotni tahrirlash' : 'Yangi mahsulot',
            largeTitle: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.gutter,
              AppDimensions.space8,
              AppDimensions.gutter,
              AppDimensions.space40,
            ),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppDimensions.space20),
                        child: AppImagePickerField(
                          bucket: 'product-images',
                          folder: sellerId,
                          fileNameHint: widget.productId,
                          initialUrl: _imageUrl,
                          size: 120,
                          placeholderIcon: Icons.add_photo_alternate_outlined,
                          onUploaded: (url) => setState(() => _imageUrl = url),
                        ),
                      ),
                    ),
                    AppTextField(
                      controller: _nameController,
                      label: 'Mahsulot nomi',
                      hint: 'Masalan: Gaz ballon 50L',
                      prefixIcon: Icons.label_outline_rounded,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => setState(() {}),
                      validator: (v) => AppValidators.required(v, field: 'Nomi'),
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    AppSelectField(
                      label: 'Kategoriya',
                      value: _category.titleUz,
                      prefixIcon: _category.icon,
                      onTap: _pickCategory,
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    AppTextField(
                      controller: _descriptionController,
                      label: 'Tavsif',
                      hint: 'Mahsulot haqida qisqacha ma’lumot',
                      prefixIcon: Icons.notes_rounded,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) => AppValidators.required(v, field: 'Tavsif'),
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _priceController,
                            label: 'Narxi (so‘m)',
                            hint: '120 000',
                            keyboardType: TextInputType.number,
                            inputFormatters: [ThousandsInputFormatter()],
                            validator: (v) =>
                                AppValidators.required(v, field: 'Narx'),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space12),
                        Expanded(
                          child: AppTextField(
                            controller: _oldPriceController,
                            label: 'Eski narx (ixtiyoriy)',
                            hint: '135 000',
                            keyboardType: TextInputType.number,
                            inputFormatters: [ThousandsInputFormatter()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _stockController,
                            label: 'Ombordagi soni',
                            hint: '10',
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                AppValidators.required(v, field: 'Ombor soni'),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space12),
                        Expanded(
                          child: AppSelectField(
                            label: 'O‘lchov birligi',
                            value: _unit,
                            onTap: _pickUnit,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space24),
                    AppButton(
                      label: widget.isEditing ? 'Saqlash' : 'Mahsulot qo‘shish',
                      icon: Icons.check_rounded,
                      isLoading: _submitting,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    Text(
                      'Har bir yangi yoki tahrirlangan mahsulot marketda '
                      'ko‘rinishidan oldin admin tomonidan tekshiriladi.',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(color: c.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
