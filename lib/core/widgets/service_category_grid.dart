import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../constants/app_constants.dart';
import 'app_tappable.dart';

/// A quiet, single-row category picker. The entire icon and label are
/// tappable; large text gets wider tiles instead of smaller lettering.
class ServiceCategoryGrid extends StatelessWidget {
  const ServiceCategoryGrid({
    super.key,
    required this.onSelected,
    this.padding = EdgeInsets.zero,
  });

  final ValueChanged<ServiceCategory> onSelected;
  final EdgeInsetsGeometry padding;

  static bool isAvailable(ServiceCategory category) =>
      category == ServiceCategory.gazBallon ||
      category == ServiceCategory.suyultirilganGaz;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final scale = (scaler.scale(12) / 12).clamp(1.0, double.infinity);
    final iconSide = 64 + (scale.clamp(1.0, 1.5) - 1) * 16;
    final labelHeight = scaler.scale(12) * 1.3 * 2;

    return SizedBox(
      height: iconSide + 10 + labelHeight + 4,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: ServiceCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = ServiceCategory.values[index];
          return SizedBox(
            width: 94 * scale,
            child: _ServiceTile(
              category: category,
              iconSide: iconSide,
              labelHeight: labelHeight,
              onTap: () => onSelected(category),
            ),
          );
        },
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.category,
    required this.iconSide,
    required this.labelHeight,
    required this.onTap,
  });

  final ServiceCategory category;
  final double iconSide;
  final double labelHeight;
  final VoidCallback onTap;

  IconData get _icon => switch (category) {
        ServiceCategory.gazBallon => Icons.propane_tank_outlined,
        ServiceCategory.suyultirilganGaz =>
          Icons.local_fire_department_outlined,
        ServiceCategory.metanGaz => Icons.air_rounded,
        ServiceCategory.propanGaz => Icons.gas_meter_outlined,
        ServiceCategory.elektrQuvvatlash => Icons.bolt_rounded,
        ServiceCategory.benzin => Icons.local_gas_station_outlined,
        ServiceCategory.dizel => Icons.local_shipping_outlined,
        ServiceCategory.market => Icons.storefront_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final available = ServiceCategoryGrid.isAvailable(category);
    return Semantics(
      button: true,
      label: '${category.titleUz}${available ? '' : ', tez orada'}',
      excludeSemantics: true,
      child: AppTappable(
        onTap: onTap,
        pressedScale: 0.96,
        child: Column(
          children: [
            Container(
              width: iconSide,
              height: iconSide,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.separator, width: 0.5),
              ),
              child: Icon(_icon,
                  size: 28, color: available ? c.textPrimary : c.textSecondary),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: labelHeight,
              width: double.infinity,
              child: Text(
                category.titleUz,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                  color: available ? c.textPrimary : c.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
