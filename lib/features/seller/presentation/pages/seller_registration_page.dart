import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_image_picker_field.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/app_select_field.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/app_switch.dart';
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
  // Prefilled for a signed-in user; a guest types it and becomes the
  // account the company belongs to.
  late final _ownerController =
      TextEditingController(text: ref.read(authProvider)?.fullName ?? '');
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _deliveryFeeController = TextEditingController(text: '15 000');

  ServiceCategory _category = ServiceCategory.gazBallon;
  AndijonDistrict _district = AndijonDistrict.andijonShahri;
  String _workingHours = '09:00 - 21:00';
  String? _logoUrl;
  bool _offersDelivery = true;
  bool _offersPickup = true;
  bool _submitting = false;

  static const _hoursPresets = ['09:00 - 18:00', '09:00 - 21:00', '08:00 - 22:00', '24/7'];

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
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

  Future<void> _pickDistrict() async {
    final picked = await AppPickerSheet.show<AndijonDistrict>(
      context,
      title: 'Tuman',
      options: AndijonDistrict.values,
      labelOf: (d) => d.titleUz,
      selected: _district,
    );
    if (picked != null) setState(() => _district = picked);
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
    // A missing field may sit far above the button — say so and scroll to
    // it, instead of a tap that seems to do nothing.
    final invalid = _formKey.currentState?.validateGranularly() ?? const {};
    if (invalid.isNotEmpty) {
      AppToast.show(
        context,
        'Qizil bilan belgilangan maydonni to‘ldiring',
        tone: ToastTone.warning,
      );
      Scrollable.ensureVisible(
        invalid.first.context,
        duration: AppMotion.base,
        curve: AppMotion.standard,
        alignment: .2,
      );
      return;
    }
    if (!_offersDelivery && !_offersPickup) {
      AppToast.show(
        context,
        'Kamida bitta usul: yetkazib berish yoki o‘zi olib ketish',
        tone: ToastTone.warning,
      );
      return;
    }

    final ownerName = _ownerController.text.trim();
    final phone = '+998${_phoneController.text.replaceAll(' ', '')}';

    setState(() => _submitting = true);

    // Browsing as a guest ("Mehmon sifatida ko‘rish") — sign them up with
    // the name and phone from this form, so the application has an owner.
    var user = ref.read(authProvider);
    if (user == null) {
      await ref
          .read(authProvider.notifier)
          .register(fullName: ownerName, phone: phone);
      user = ref.read(authProvider);
    }
    if (user == null) {
      if (mounted) setState(() => _submitting = false);
      return;
    }

    final deliveryFee = int.tryParse(
          _deliveryFeeController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;

    // Sent to Supabase, where the admin panel's "Yangi arizalar" picks it
    // up; only a stored application moves on to the waiting screen.
    try {
      final profile =
          await ref.read(sellerProfilesProvider.notifier).submitApplication(
                ownerUserId: user.id,
                ownerName: ownerName,
                companyName: _nameController.text.trim(),
                category: _category,
                district: _district.titleUz,
                description: _descriptionController.text.trim(),
                address: _addressController.text.trim(),
                phone: phone,
                workingHours: _workingHours,
                deliveryFee: _offersDelivery ? deliveryFee : 0,
                offersDelivery: _offersDelivery,
                offersPickup: _offersPickup,
                logoUrl: _logoUrl,
              );
      ref.read(authProvider.notifier).linkSeller(profile.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppToast.show(
        context,
        'Arizani yuborib bo‘lmadi. Internetni tekshirib, qayta urinib ko‘ring.',
        tone: ToastTone.danger,
      );
      return;
    }

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
                    AppTextField(
                      controller: _ownerController,
                      label: 'Ism-familiyangiz',
                      hint: 'Firma egasi yoki mas’ul shaxs',
                      prefixIcon: Icons.person_outline_rounded,
                      textCapitalization: TextCapitalization.words,
                      validator: AppValidators.fullName,
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
                    AppSelectField(
                      label: 'Tuman',
                      value: _district.titleUz,
                      prefixIcon: Icons.map_outlined,
                      onTap: _pickDistrict,
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    AppTextField(
                      controller: _addressController,
                      label: 'Manzil',
                      hint: 'Ko‘cha, uy raqami',
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
          AppSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
