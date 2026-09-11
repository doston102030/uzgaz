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
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/seller_provider.dart';

/// "Firma ma'lumotlari" — the seller onboarding form. Submitting creates
/// a [SellerStatus.pending] company and routes to the waiting screen；an
/// admin approval (Admin → Sotuvchilar) is what unlocks the seller shell.
class SellerRegistrationPage extends ConsumerStatefulWidget {
  const SellerRegistrationPage({super.key});

  @override
  ConsumerState<SellerRegistrationPage> createState() => _SellerRegistrationPageState();
}

class _SellerRegistrationPageState extends ConsumerState<SellerRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _deliveryFeeController = TextEditingController(text: '15 000');

  ServiceCategory _category = ServiceCategory.gazBallon;
  String _workingHours = '09:00 - 21:00';
  String? _logoUrl;
  bool _offersDelivery = true;
  bool _offersPickup = true;
  bool _submitting = false;

  static const _hoursPresets = ['09:00 - 18:00', '09:00 - 21:00', '08:00 - 22:00', '24/7'];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _deliveryFeeController.dispose();
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

  Future<void> _pickHours() async {
    final picked = await AppPickerSheet.show<String>(
      context,
      title: 'Ish vaqti',
      options: _hoursPresets,
      labelOf: (h) => h,
      selected: _workingHours,
    );
    if (picked != null) setState(() => _workingHours = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_offersDelivery && !_offersPickup) {
      AppToast.show(
        context,
        'Kamida bitta usul: yetkazib berish yoki o‘zi olib ketish',
        tone: ToastTone.warning,
      );
      return;
    }

    final user = ref.read(authProvider);
    if (user == null) return;

    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final deliveryFee = int.tryParse(
          _deliveryFeeController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;

    final profile = ref.read(sellerProfilesProvider.notifier).apply(
          ownerUserId: user.id,
          companyName: _nameController.text.trim(),
          category: _category,
          description: _descriptionController.text.trim(),
          address: _addressController.text.trim(),
          phone: '+998${_phoneController.text.replaceAll(' ', '')}',
          workingHours: _workingHours,
          deliveryFee: _offersDelivery ? deliveryFee : 0,
          offersDelivery: _offersDelivery,
          offersPickup: _offersPickup,
          logoUrl: _logoUrl,
        );

    ref.read(authProvider.notifier).linkSeller(profile.id);

    if (!mounted) return;
    setState(() => _submitting = false);
    context.pushReplacement('/seller/pending');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final userId = ref.watch(authProvider)?.id;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const AppSliverNavBar(
            title: 'Firma ma’lumotlari',
            subtitle: 'Marketplace’da ko‘rinadigan profilingiz',
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
                        padding: const EdgeInsets.only(bottom: AppDimensions.space8),
                        child: AppImagePickerField(
                          bucket: 'company-logos',
                          fileNameHint: userId,
                          initialUrl: _logoUrl,
                          size: 96,
                          placeholderIcon: Icons.storefront_outlined,
                          onUploaded: (url) => setState(() => _logoUrl = url),
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppDimensions.space20),
                        child: Text(
                          'Firma logotipi (ixtiyoriy)',
                          style: AppTypography.caption.copyWith(color: c.textTertiary),
                        ),
                      ),
                    ),
                    AppTextField(
                      controller: _nameController,
                      label: 'Firma nomi',
                      hint: 'Masalan: UzGaz Servis',
                      prefixIcon: Icons.storefront_outlined,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => AppValidators.required(v, field: 'Firma nomi'),
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
                      hint: 'Firmangiz haqida qisqacha ma’lumot',
                      prefixIcon: Icons.notes_rounded,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) => AppValidators.required(v, field: 'Tavsif'),
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    AppTextField(
                      controller: _addressController,
                      label: 'Manzil',
                      hint: 'Tuman, ko‘cha, uy raqami',
                      prefixIcon: Icons.place_outlined,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) => AppValidators.required(v, field: 'Manzil'),
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    AppTextField(
                      controller: _phoneController,
                      label: 'Aloqa telefoni',
                      hint: '90 123 45 67',
                      prefixText: '+998',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [UzPhoneInputFormatter()],
                      validator: AppValidators.phone,
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    AppSelectField(
                      label: 'Ish vaqti',
                      value: _workingHours,
                      prefixIcon: Icons.access_time_rounded,
                      onTap: _pickHours,
                    ),
                    const SizedBox(height: AppDimensions.space20),

                    Text(
                      'Yetkazish shartlari',
                      style: AppTypography.subhead.copyWith(
                        color: c.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space10),
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space14,
                      ),
                      child: Column(
                        children: [
                          _ToggleRow(
                            icon: Icons.local_shipping_outlined,
                            title: 'Yetkazib berish',
                            value: _offersDelivery,
                            onChanged: (v) => setState(() => _offersDelivery = v),
                          ),
                          if (_offersDelivery) ...[
                            Divider(height: 1, color: c.separator),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppDimensions.space12,
                              ),
                              child: AppTextField(
                                controller: _deliveryFeeController,
                                label: 'Yetkazish narxi (so‘m)',
                                hint: '15 000',
                                keyboardType: TextInputType.number,
                                inputFormatters: [ThousandsInputFormatter()],
                                prefixIcon: Icons.payments_outlined,
                              ),
                            ),
                          ],
                          Divider(height: 1, color: c.separator),
                          _ToggleRow(
                            icon: Icons.storefront_outlined,
                            title: 'O‘zi olib ketish',
                            value: _offersPickup,
                            onChanged: (v) => setState(() => _offersPickup = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space24),
                    AppButton(
                      label: 'Ko‘rib chiqishga yuborish',
                      icon: Icons.send_rounded,
                      isLoading: _submitting,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    Text(
                      'Yuborilgan ariza odatda 24 soat ichida admin tomonidan '
                      'ko‘rib chiqiladi.',
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

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space10),
      child: Row(
        children: [
          Icon(icon, size: 19, color: c.textSecondary),
          const SizedBox(width: AppDimensions.space10),
          Expanded(
            child: Text(
              title,
              style: AppTypography.callout.copyWith(color: c.textPrimary),
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
