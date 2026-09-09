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
import '../../../../core/widgets/custom_dialog.dart';
import '../providers/auth_provider.dart';
import 'splash_page.dart' show AppLogoMark;

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController(text: '90 123 45 67');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final error = AppValidators.phone(_phoneController.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    await ref
        .read(authProvider.notifier)
        .signInWithPhone('+998${_phoneController.text.replaceAll(' ', '')}');

    if (!mounted) return;
    setState(() => _loading = false);
    AppToast.show(context, 'Xush kelibsiz!', tone: ToastTone.success);
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.space40),
              const FadeInUp(child: AppLogoMark(size: 62)),
              const SizedBox(height: AppDimensions.space28),
              FadeInUp(
                delay: const Duration(milliseconds: 60),
                child: Text(
                  'Xush kelibsiz 👋',
                  style: AppTypography.largeTitle.copyWith(color: c.textPrimary),
                ),
              ),
              const SizedBox(height: AppDimensions.space8),
              FadeInUp(
                delay: const Duration(milliseconds: 110),
                child: Text(
                  'Davom etish uchun telefon raqamingizni kiriting — '
                  'SMS orqali tasdiqlash kodi yuboramiz.',
                  style: AppTypography.callout.copyWith(
                    color: c.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space32),
              FadeInUp(
                delay: const Duration(milliseconds: 160),
                child: AppTextField(
                  controller: _phoneController,
                  label: 'Telefon raqam',
                  hint: '90 123 45 67',
                  prefixText: '+998',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [UzPhoneInputFormatter()],
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onSubmitted: (_) => _submit(),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppDimensions.space8, left: 4),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, size: 14, color: c.danger),
                      const SizedBox(width: 4),
                      Text(
                        _error!,
                        style: AppTypography.caption.copyWith(color: c.danger),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppDimensions.space24),
              FadeInUp(
                delay: const Duration(milliseconds: 210),
                child: AppButton(
                  label: 'Davom etish',
                  isLoading: _loading,
                  onPressed: _submit,
                ),
              ),
              const SizedBox(height: AppDimensions.space20),
              Row(
                children: [
                  Expanded(child: Divider(color: c.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space12),
                    child: Text(
                      'yoki',
                      style: AppTypography.caption.copyWith(color: c.textTertiary),
                    ),
                  ),
                  Expanded(child: Divider(color: c.border)),
                ],
              ),
              const SizedBox(height: AppDimensions.space20),
              AppButton(
                label: 'Mehmon sifatida ko‘rish',
                variant: AppButtonVariant.outline,
                icon: Icons.visibility_outlined,
                onPressed: () => context.go('/home'),
              ),
              const SizedBox(height: AppDimensions.space24),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Hisobingiz yo‘qmi?',
                      style: AppTypography.footnote.copyWith(color: c.textSecondary),
                    ),
                    AppButton(
                      label: 'Ro‘yxatdan o‘tish',
                      variant: AppButtonVariant.text,
                      size: AppButtonSize.small,
                      expand: false,
                      onPressed: () => context.push('/register'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space16),
              Center(
                child: Text(
                  'Davom etish orqali siz foydalanish shartlari va\n'
                  'maxfiylik siyosatiga rozilik bildirasiz.',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(color: c.textTertiary),
                ),
              ),
              const SizedBox(height: AppDimensions.space24),
            ],
          ),
        ),
      ),
    );
  }
}
