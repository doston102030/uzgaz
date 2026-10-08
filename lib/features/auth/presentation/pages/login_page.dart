import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/app_tappable.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../providers/auth_provider.dart';
import '../widgets/login_brand_header.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  bool _loading = false;
  String? _error;

  /// One-shot shake the phone field plays when validation fails.
  late final AnimationController _shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void dispose() {
    _phoneController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final error = AppValidators.phone(_phoneController.text);
    if (error != null) {
      setState(() => _error = error);
      AppHaptics.emphasis();
      _shakeController.forward(from: 0);
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
    // Short windows get tighter gaps so the form still fits. Window size,
    // not the viewport: it doesn't change when the keyboard opens, so the
    // spacing never jumps while typing.
    final tight = MediaQuery.sizeOf(context).height < 720;
    double gap(double normal, double compact) => tight ? compact : normal;

    // One screen, no scrolling: the header takes whatever height the form
    // leaves. It only scrolls when even the header's minimum doesn't fit
    // (a very short window, or the on-screen keyboard is up).
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewport.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Expanded(child: LoginBrandHeader()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              height: gap(AppDimensions.space20,
                                  AppDimensions.space12)),
                          FadeInUp(
                            delay: const Duration(milliseconds: 60),
                            child: Text(
                              'Xush kelibsiz',
                              style: AppTypography.largeTitle.copyWith(
                                color: c.isDark
                                    ? c.textPrimary
                                    : AppColors.primaryDeep,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          SizedBox(
                              height: gap(
                                  AppDimensions.space8, AppDimensions.space6)),
                          FadeInUp(
                            delay: const Duration(milliseconds: 110),
                            child: Text(
                              'Telefon raqamingizni kiriting. Tasdiqlash kodi SMS '
                              'orqali yuboriladi.',
                              style: AppTypography.callout.copyWith(
                                color: c.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                          SizedBox(
                              height: gap(AppDimensions.space24,
                                  AppDimensions.space16)),
                          AnimatedBuilder(
                            animation: _shakeController,
                            builder: (context, child) {
                              final t = _shakeController.value;
                              final dx =
                                  math.sin(t * math.pi * 3) * 10 * (1 - t);
                              return Transform.translate(
                                offset: Offset(dx, 0),
                                child: child,
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FadeInUp(
                                  delay: const Duration(milliseconds: 160),
                                  child: AppTextField(
                                    controller: _phoneController,
                                    label: 'Telefon raqami',
                                    hint: '90 123 45 67',
                                    prefixText: '+998',
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.done,
                                    inputFormatters: [UzPhoneInputFormatter()],
                                    onChanged: (_) {
                                      if (_error != null) {
                                        setState(() => _error = null);
                                      }
                                    },
                                    onSubmitted: (_) => _submit(),
                                  ),
                                ),
                                // Fixed slot: the error appearing never shifts the
                                // layout (which would also resize the header).
                                SizedBox(
                                  height: gap(28, 26),
                                  child: AnimatedSwitcher(
                                    duration: AppMotion.fast,
                                    layoutBuilder: (current, previous) => Stack(
                                      alignment: Alignment.topLeft,
                                      children: [
                                        ...previous,
                                        if (current != null) current,
                                      ],
                                    ),
                                    child: _error == null
                                        ? const SizedBox.shrink()
                                        : Padding(
                                            key: ValueKey(_error),
                                            padding: const EdgeInsets.only(
                                                top: AppDimensions.space6,
                                                left: 4),
                                            child: Row(
                                              children: [
                                                Icon(
                                                    Icons.error_outline_rounded,
                                                    size: 14,
                                                    color: c.danger),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    _error!,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: AppTypography.caption
                                                        .copyWith(
                                                            color: c.danger),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FadeInUp(
                            delay: const Duration(milliseconds: 210),
                            child: AppButton(
                              label: 'Davom etish',
                              trailingIcon: Icons.arrow_forward_rounded,
                              isLoading: _loading,
                              onPressed: _submit,
                            ),
                          ),
                          SizedBox(
                              height: gap(AppDimensions.space16,
                                  AppDimensions.space10)),
                          Row(
                            children: [
                              Expanded(child: Divider(color: c.border)),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppDimensions.space12),
                                child: Text(
                                  'yoki',
                                  style: AppTypography.caption
                                      .copyWith(color: c.textTertiary),
                                ),
                              ),
                              Expanded(child: Divider(color: c.border)),
                            ],
                          ),
                          SizedBox(
                              height: gap(AppDimensions.space16,
                                  AppDimensions.space10)),
                          _GuestButton(onPressed: () => context.go('/home')),
                          SizedBox(
                              height: gap(
                                  AppDimensions.space16, AppDimensions.space8)),
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Hisobingiz yo‘qmi?',
                                  style: AppTypography.footnote
                                      .copyWith(color: c.textSecondary),
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
                          SizedBox(
                              height: gap(
                                  AppDimensions.space8, AppDimensions.space4)),
                          Center(
                            child: Text(
                              'Davom etish orqali foydalanish shartlari va\n'
                              'maxfiylik siyosatiga rozilik bildirasiz.',
                              textAlign: TextAlign.center,
                              style: AppTypography.caption
                                  .copyWith(color: c.textTertiary),
                            ),
                          ),
                          SizedBox(
                              height: gap(AppDimensions.space16,
                                  AppDimensions.space10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Light-mint secondary action. AppButton has no mint variant and this is
/// its only use, so it lives here rather than growing the shared button.
class _GuestButton extends StatelessWidget {
  const _GuestButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    // Teal-700 on the mint fill is ~4.9:1; the brand green would be ~2.9:1.
    final fg = c.isDark ? c.success : const Color(0xFF0F766E);

    return AppTappable(
      onTap: onPressed,
      pressedScale: 0.975,
      child: Container(
        height: AppDimensions.buttonHeight,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.successSoft,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: fg.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility_outlined, size: 19, color: fg),
            const SizedBox(width: AppDimensions.space8),
            Flexible(
              child: Text(
                'Mehmon sifatida ko‘rish',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.button.copyWith(color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
