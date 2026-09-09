import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/theme_provider.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/app_tappable.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../addresses/presentation/providers/address_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/presentation/providers/order_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final current = ref.read(languageProvider);
    final picked = await AppSheet.show<AppLanguage>(
      context,
      title: 'Tilni tanlang',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final language in AppLanguage.values)
            _LanguageRow(
              language: language,
              selected: language == current,
              onTap: () => Navigator.of(context).pop(language),
            ),
          const SizedBox(height: AppDimensions.space8),
        ],
      ),
    );
    if (picked != null) {
      ref.read(languageProvider.notifier).set(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final user = ref.watch(authProvider);
    final orders = ref.watch(ordersProvider);
    final addresses = ref.watch(addressesProvider);
    final language = ref.watch(languageProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const AppSliverNavBar(title: 'Profil', showBack: false),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.gutter,
              AppDimensions.space8,
              AppDimensions.gutter,
              AppDimensions.bottomBarClearance,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHeader(
                    name: user?.fullName ?? 'Mehmon foydalanuvchi',
                    phone: AppFormatters.phone(user?.phone ?? '+998901234567'),
                    onEdit: () => AppToast.show(
                      context,
                      'Profilni tahrirlash tez orada',
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  _StatsRow(
                    orders: orders.length,
                    addresses: addresses.length,
                  ),
                  const SizedBox(height: AppDimensions.space24),

                  AppGroupedList(
                    header: 'Hisob',
                    children: [
                      _SettingsRow(
                        icon: Icons.person_outline_rounded,
                        tone: AppColors.primary,
                        title: 'Shaxsiy ma’lumotlar',
                        onTap: () => AppToast.show(context, 'Tez orada'),
                      ),
                      _SettingsRow(
                        icon: Icons.location_on_outlined,
                        tone: AppColors.energyRose,
                        title: 'Manzillar',
                        value: '${addresses.length} ta',
                        onTap: () => context.push('/addresses'),
                      ),
                      _SettingsRow(
                        icon: Icons.credit_card_outlined,
                        tone: AppColors.energyElectric,
                        title: 'To‘lov usullari',
                        onTap: () => context.push('/payment'),
                      ),
                      _SettingsRow(
                        icon: Icons.receipt_long_outlined,
                        tone: AppColors.energyAmber,
                        title: 'Buyurtmalarim',
                        value: '${orders.length} ta',
                        onTap: () => context.go('/orders'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  AppGroupedList(
                    header: 'Biznes',
                    children: [
                      _SettingsRow(
                        icon: Icons.storefront_rounded,
                        tone: AppColors.energyFlame,
                        title: user?.sellerId == null ? 'Sotuvchi bo‘lish' : 'Sotuvchi kabineti',
                        onTap: () => context.push('/seller/start'),
                      ),
                      _SettingsRow(
                        icon: Icons.shield_outlined,
                        tone: AppColors.darkNavy,
                        title: 'Administrator paneli',
                        value: 'demo',
                        onTap: () {
                          ref.read(authProvider.notifier).signInAsAdmin();
                          context.go('/admin/dashboard');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  AppGroupedList(
                    header: 'Sozlamalar',
                    footer: themeMode == ThemeMode.system
                        ? 'Hozir tizim sozlamasiga moslashilgan.'
                        : null,
                    children: [
                      _SettingsRow(
                        icon: Icons.notifications_none_rounded,
                        tone: AppColors.info,
                        title: 'Bildirishnomalar',
                        trailing: Switch.adaptive(
                          value: true,
                          onChanged: (_) => AppToast.show(
                            context,
                            'Bildirishnomalar sozlamasi saqlanadi',
                          ),
                        ),
                      ),
                      _SettingsRow(
                        icon: Icons.dark_mode_outlined,
                        tone: AppColors.energySlate,
                        title: 'Tungi rejim',
                        trailing: Switch.adaptive(
                          value: isDark,
                          onChanged: (value) =>
                              ref.read(themeModeProvider.notifier).setDark(value),
                        ),
                      ),
                      _SettingsRow(
                        icon: Icons.language_rounded,
                        tone: AppColors.energyMint,
                        title: 'Til',
                        value: '${language.flag}  ${language.label}',
                        onTap: () => _pickLanguage(context, ref),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  AppGroupedList(
                    header: 'Yordam',
                    children: [
                      _SettingsRow(
                        icon: Icons.help_outline_rounded,
                        tone: AppColors.primary,
                        title: 'Yordam markazi',
                        onTap: () => CustomDialog.info(
                          context,
                          title: 'Yordam markazi',
                          message:
                              '${AppConstants.supportPhone} — 24/7 qo‘llab-quvvatlash. '
                              'Savollaringizga darhol javob beramiz.',
                          icon: Icons.support_agent_rounded,
                        ),
                      ),
                      _SettingsRow(
                        icon: Icons.info_outline_rounded,
                        tone: AppColors.energySlate,
                        title: 'Ilova haqida',
                        value: 'v1.0.0',
                        onTap: () => CustomDialog.info(
                          context,
                          title: AppConstants.appName,
                          message:
                              'O‘zbekiston uchun energiya marketpleysi. '
                              'Versiya 1.0.0 (mock ma’lumotlar bilan).',
                          icon: Icons.local_fire_department_rounded,
                        ),
                      ),
                      _SettingsRow(
                        icon: Icons.logout_rounded,
                        tone: AppColors.error,
                        title: 'Chiqish',
                        danger: true,
                        onTap: () async {
                          final confirmed = await CustomDialog.confirm(
                            context,
                            title: 'Hisobdan chiqish',
                            message: 'Qayta kirish uchun telefon raqam kerak bo‘ladi.',
                            confirmLabel: 'Chiqish',
                            destructive: true,
                            icon: Icons.logout_rounded,
                          );
                          if (confirmed && context.mounted) {
                            ref.read(authProvider.notifier).signOut();
                            context.go('/login');
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space24),
                  Center(
                    child: Text(
                      '${AppConstants.appName} · v1.0.0',
                      style: AppTypography.caption.copyWith(color: c.textTertiary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.phone,
    required this.onEdit,
  });

  final String name;
  final String phone;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.characters.first.toUpperCase())
        .join();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        gradient: c.brandGradient,
        borderRadius: AppDimensions.brXLarge,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.26),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: AppDimensions.avatarSizeLarge,
            height: AppDimensions.avatarSizeLarge,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
            ),
            child: Text(
              initials,
              style: AppTypography.title2.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: AppDimensions.space14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title3.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: AppTypography.callout.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          AppTappable(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_outlined, color: Colors.white, size: 17),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.orders, required this.addresses});

  final int orders;
  final int addresses;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space14),
      child: Row(
        children: [
          _Stat(value: '$orders', label: 'Buyurtma', icon: Icons.receipt_long_rounded),
          Container(width: 1, height: 34, color: c.border),
          _Stat(value: '$addresses', label: 'Manzil', icon: Icons.place_rounded),
          Container(width: 1, height: 34, color: c.border),
          const _Stat(value: '4.9', label: 'Reyting', icon: Icons.star_rounded),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.icon});

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 17, color: c.primary),
          const SizedBox(height: 5),
          Text(
            value,
            style: AppTypography.headline.copyWith(color: c.textPrimary),
          ),
          Text(
            label,
            style: AppTypography.caption2.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.tone,
    this.value,
    this.onTap,
    this.trailing,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final Color tone;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppTappable(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space14,
          vertical: AppDimensions.space10,
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: c.tint(tone, 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: tone),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Text(
                title,
                style: AppTypography.callout.copyWith(
                  color: danger ? c.danger : c.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(right: AppDimensions.space6),
                child: Text(
                  value!,
                  style: AppTypography.callout.copyWith(color: c.textTertiary),
                ),
              ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(Icons.chevron_right_rounded, size: 20, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppTappable(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.gutter,
          vertical: AppDimensions.space14,
        ),
        child: Row(
          children: [
            Text(language.flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Text(
                language.label,
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
