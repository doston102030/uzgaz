import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/typography.dart';
import '../../features/addresses/domain/entities/address.dart';
import 'app_segmented_control.dart';
import 'app_surface.dart';
import 'app_tappable.dart';

class AddressCard extends StatelessWidget {
  const AddressCard({
    super.key,
    required this.address,
    required this.selected,
    required this.onTap,
    this.onEdit,
  });

  final Address address;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  IconData get _icon {
    final title = address.title.toLowerCase();
    if (title.contains('uy') || title.contains('home')) return Icons.home_rounded;
    if (title.contains('ish') || title.contains('work')) return Icons.work_rounded;
    return Icons.place_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;

    final details = [
      if (address.apartment != null) 'Kvartira ${address.apartment}',
      if (address.entrance != null) '${address.entrance}-podyezd',
      if (address.floor != null) '${address.floor}-qavat',
    ].join(' · ');

    return AppCard(
      onTap: onTap,
      selected: selected,
      padding: const EdgeInsets.all(AppDimensions.space14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: selected ? c.primarySoft : c.surfaceMuted,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(_icon, size: 20, color: selected ? c.primary : c.textSecondary),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      address.title,
                      style: AppTypography.callout.copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(width: AppDimensions.space6),
                      const AppPill(label: 'Asosiy', tone: PillTone.primary, dense: true),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  address.fullAddress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: c.textSecondary),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    details,
                    style: AppTypography.caption2.copyWith(color: c.textTertiary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.space8),
          Column(
            children: [
              AnimatedContainer(
                duration: AppMotion.fast,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? c.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? c.primary : c.borderStrong,
                    width: 1.8,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check_rounded, size: 14, color: c.onPrimary)
                    : null,
              ),
              if (onEdit != null) ...[
                const SizedBox(height: AppDimensions.space10),
                AppTappable(
                  onTap: onEdit,
                  child: Icon(Icons.edit_outlined, size: 17, color: c.textTertiary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
