import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_tappable.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _accepted = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_accepted) {
      AppToast.show(
        context,
        'Shartlarni qabul qiling',
        tone: ToastTone.warning,
      );
      return;
    }

    setState(() => _loading = true);
    await ref.read(authProvider.notifier).register(
          fullName: _nameController.text.trim(),
          phone: '+998${_phoneController.text.replaceAll(' ', '')}',
        );

    if (!mounted) return;
    setState(() => _loading = false);
    AppToast.show(context, 'Hisob yaratildi', tone: ToastTone.success);
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const AppSliverNavBar(
            title: 'Ro‘yxatdan o‘tish',
            subtitle: 'Bir daqiqada hisob yarating',
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.gutter,
              AppDimensions.space16,
              AppDimensions.gutter,
              AppDimensions.space32,
            ),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      controller: _nameController,
                      label: 'To‘liq ism',
                      hint: 'Ism Familiya',
                      prefixIcon: Icons.person_outline_rounded,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: AppValidators.fullName,
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    AppTextField(
                      controller: _phoneController,
                      label: 'Telefon raqam',
                      hint: '90 123 45 67',
                      prefixText: '+998',
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [UzPhoneInputFormatter()],
                      validator: AppValidators.phone,
                    ),
                    const SizedBox(height: AppDimensions.space20),
                    AppTappable(
                      onTap: () => setState(() => _accepted = !_accepted),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(
                              color: _accepted ? c.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: _accepted ? c.primary : c.borderStrong,
                                width: 1.8,
                              ),
                            ),
                            child: _accepted
                                ? Icon(Icons.check_rounded,
                                    size: 15, color: c.onPrimary)
                                : null,
                          ),
                          const SizedBox(width: AppDimensions.space10),
                          Expanded(
                            child: Text(
                              'Foydalanish shartlari va maxfiylik siyosatiga roziman',
                              style: AppTypography.footnote
                                  .copyWith(color: c.textSecondary, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space24),
                    AppButton(
                      label: 'Ro‘yxatdan o‘tish',
                      isLoading: _loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Hisobingiz bormi?',
                            style: AppTypography.footnote
                                .copyWith(color: c.textSecondary),
                          ),
                          AppButton(
                            label: 'Kirish',
                            variant: AppButtonVariant.text,
                            size: AppButtonSize.small,
                            expand: false,
                            onPressed: () => context.go('/login'),
                          ),
                        ],
                      ),
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
