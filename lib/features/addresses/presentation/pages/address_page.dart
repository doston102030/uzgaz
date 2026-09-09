import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../core/widgets/address_card.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/app_tappable.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/address_provider.dart';

class AddressPage extends ConsumerWidget {
  const AddressPage({super.key, this.continueTo});

  /// Where "Davom etish" should go — defaults back to the cart.
  final String? continueTo;

  Future<void> _addAddress(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController(text: 'Uy');
    final addressController = TextEditingController();
    final apartmentController = TextEditingController();

    final saved = await AppSheet.show<bool>(
      context,
      title: 'Yangi manzil',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: titleController,
              label: 'Nomi',
              hint: 'Uy, Ish, Dala hovli…',
              prefixIcon: Icons.label_outline_rounded,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppDimensions.space14),
            AppTextField(
              controller: addressController,
              label: 'To‘liq manzil',
              hint: 'Tuman, ko‘cha, uy raqami',
              prefixIcon: Icons.place_outlined,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppDimensions.space14),
            AppTextField(
              controller: apartmentController,
              label: 'Kvartira (ixtiyoriy)',
              hint: '13',
              prefixIcon: Icons.meeting_room_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppDimensions.space20),
            AppButton(
              label: 'Saqlash',
              onPressed: () {
                if (AppValidators.required(addressController.text) != null) return;
                Navigator.of(context).pop(true);
              },
            ),
          ],
        ),
      ),
    );

    if (saved == true && context.mounted) {
      final address = ref.read(addressesProvider.notifier).add(
            title: titleController.text.trim().isEmpty
                ? 'Manzil'
                : titleController.text.trim(),
            fullAddress: addressController.text.trim(),
            apartment: apartmentController.text.trim().isEmpty
                ? null
                : apartmentController.text.trim(),
          );
      ref.read(selectedAddressNotifierProvider.notifier).select(address);
      if (context.mounted) {
        AppToast.show(context, 'Manzil saqlandi', tone: ToastTone.success);
      }
    }

    titleController.dispose();
    addressController.dispose();
    apartmentController.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final addresses = ref.watch(addressesProvider);
    final selected = ref.watch(selectedAddressProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverNavBar(
            title: 'Manzillar',
            subtitle: 'Yetkazib berish manzilini tanlang',
            actions: [
              AppIconButton(
                icon: Icons.add_rounded,
                onTap: () => _addAddress(context, ref),
              ),
            ],
          ),
          if (addresses.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.location_off_outlined,
                title: 'Saqlangan manzil yo‘q',
                subtitle: 'Yetkazib berish uchun birinchi manzilingizni qo‘shing.',
                actionLabel: 'Manzil qo‘shish',
                onAction: () => _addAddress(context, ref),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.gutter,
                AppDimensions.space12,
                AppDimensions.gutter,
                AppDimensions.space20,
              ),
              sliver: SliverList.separated(
                itemCount: addresses.length + 2,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppDimensions.space12),
                itemBuilder: (context, i) {
                  if (i == addresses.length) {
                    return _AddOptionRow(
                      icon: Icons.my_location_rounded,
                      title: 'Joriy joylashuvdan foydalanish',
                      subtitle: 'GPS orqali manzilni aniqlash',
                      onTap: () => AppToast.show(
                        context,
                        'Joylashuv ruxsati so‘raladi',
                        icon: Icons.gps_fixed_rounded,
                      ),
                    );
                  }
                  if (i == addresses.length + 1) {
                    return _AddOptionRow(
                      icon: Icons.map_outlined,
                      title: 'Xaritadan belgilash',
                      subtitle: 'Nuqtani qo‘lda tanlash',
                      onTap: () => context.go('/map'),
                    );
                  }
                  final address = addresses[i];
                  return AddressCard(
                    address: address,
                    selected: selected?.id == address.id,
                    onTap: () => ref
                        .read(selectedAddressNotifierProvider.notifier)
                        .select(address),
                  );
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.separator)),
          boxShadow: c.shadowLg,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.gutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.space12),
                    child: Row(
                      children: [
                        Icon(Icons.place_rounded, size: 16, color: c.primary),
                        const SizedBox(width: AppDimensions.space6),
                        Expanded(
                          child: Text(
                            selected.fullAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption
                                .copyWith(color: c.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                AppButton(
                  label: 'Davom etish',
                  onPressed: selected == null
                      ? null
                      : () => context.push(continueTo ?? '/cart'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddOptionRow extends StatelessWidget {
  const _AddOptionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppTappable(
      onTap: onTap,
      child: DottedBorderBox(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.primarySoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 19, color: c.primary),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.callout.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(color: c.textTertiary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// Dashed container that reads as "add something here".
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: c.borderStrong,
        radius: AppDimensions.radiusLarge,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space14),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + 6;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + 5;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) => old.color != color;
}
