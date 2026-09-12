import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/typography.dart';
import 'app_segmented_control.dart';
import 'app_surface.dart';
import 'app_tappable.dart';

/// Row card on "Elektr quvvatlash" → "Xizmat turini tanlang".
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.color = AppColors.primary,
    this.badge,
    this.trailingText,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final String? badge;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.space14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: c.isDark ? 0.34 : 0.16),
                  color.withValues(alpha: c.isDark ? 0.18 : 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppDimensions.space14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headline.copyWith(color: c.textPrimary),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: AppDimensions.space6),
                      AppPill(label: badge!, tone: PillTone.success, dense: true),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.footnote.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          if (trailingText != null) ...[
            Text(
              trailingText!,
              style: AppTypography.caption.copyWith(color: c.textTertiary),
            ),
            const SizedBox(width: AppDimensions.space6),
          ],
          Icon(Icons.chevron_right_rounded, color: c.textTertiary, size: 20),
        ],
      ),
    );
  }
}

/// Square category tile for the horizontal rail on Home.
class ServiceTile extends StatelessWidget {
  const ServiceTile({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.photoUrl,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  /// Real photo shown inside the circle instead of the plain icon glyph
  /// (see [ServiceCategoryX.photoUrl]) — falls back to the icon tile below
  /// while it loads, and again if it fails, same resilient pattern
  /// [ProductCard] uses for product photos.
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final iconTile = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: c.isDark ? 0.36 : 0.18),
            color.withValues(alpha: c.isDark ? 0.20 : 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 21),
    );

    return AppTappable(
      onTap: onTap,
      pressedScale: 0.94,
      child: SizedBox(
        width: 74,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.border),
                boxShadow: c.shadowSm,
              ),
              child: Center(
                child: photoUrl == null
                    ? iconTile
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: CachedNetworkImage(
                          imageUrl: photoUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => iconTile,
                          errorWidget: (_, __, ___) => iconTile,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: c.textSecondary,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The highlighted "Aholi uchun — SUYULTIRILGAN GAZ" promo with the
/// "Aktiv" badge, required by the service screen spec.
class HighlightServiceCard extends StatelessWidget {
  const HighlightServiceCard({
    super.key,
    required this.onTap,
    this.overline = 'Aholi uchun',
    this.title = 'SUYULTIRILGAN GAZ',
    this.caption = 'Subsidiya narxida · cheklangan miqdorda',
    this.badge = 'Aktiv',
    this.icon = Icons.local_fire_department_rounded,
    this.photoUrl,
    this.gradient,
    this.glowColor,
  });

  final VoidCallback onTap;
  final String overline;
  final String title;
  final String caption;
  final String badge;

  /// Shown in the trailing circle when [photoUrl] isn't given (or hasn't
  /// loaded yet) — every existing call site keeps its plain flame glyph.
  final IconData icon;

  /// Real photo for the trailing circle — used by [PromoCarousel]'s
  /// slides. `null` keeps the original translucent icon-only look.
  final String? photoUrl;

  /// Slide background — defaults to the brand gradient (unchanged for
  /// existing call sites); [PromoCarousel] varies this per slide.
  final Gradient? gradient;

  /// Tints the drop shadow under the card; defaults to brand primary.
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppTappable(
      onTap: onTap,
      pressedScale: 0.985,
      child: Container(
        constraints: const BoxConstraints(minHeight: 132),
        decoration: BoxDecoration(
          gradient: gradient ?? c.brandGradient,
          borderRadius: AppDimensions.brXLarge,
          boxShadow: [
            BoxShadow(
              color: (glowColor ?? AppColors.primary)
                  .withValues(alpha: c.isDark ? 0.36 : 0.30),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: AppDimensions.brXLarge,
                child: CustomPaint(painter: _PromoGlowPainter()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.space20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              overline.toUpperCase(),
                              style: AppTypography.overline.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.space8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E),
                                borderRadius: AppDimensions.brPill,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF22C55E).withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    badge,
                                    style: AppTypography.caption2.copyWith(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.space8),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.title2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space6),
                        Text(
                          caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                    ),
                    child: photoUrl == null
                        ? Icon(icon, color: Colors.white, size: 28)
                        : CachedNetworkImage(
                            imageUrl: photoUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Icon(icon, color: Colors.white, size: 28),
                            errorWidget: (_, __, ___) =>
                                Icon(icon, color: Colors.white, size: 28),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()..color = Colors.white.withValues(alpha: 0.10);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.18), size.height * 0.55, glow);
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 1.05),
      size.height * 0.45,
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 1.1),
      size.height * 0.5,
      Paint()..color = Colors.black.withValues(alpha: 0.06),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
