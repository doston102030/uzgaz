import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/app_tappable.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../../core/widgets/map_company_card.dart';
import '../../../../core/widgets/pulsing_marker.dart';
import '../../../../core/utils/dash_path.dart';
import '../../../checkout/presentation/providers/checkout_provider.dart';
import '../../../companies/domain/entities/company.dart';
import '../../../companies/presentation/providers/company_provider.dart';

/// Map screen.
///
/// The canvas below is a styled stand-in for `GoogleMap` — this project
/// has no Maps API key, and a grey box would misrepresent the design.
/// To go live: drop a `GoogleMap(...)` in place of [_MapCanvas], feed it
/// the same `companies` markers, and keep the overlay chrome as is.
class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final PageController _pageController =
      PageController(viewportFraction: 0.78);
  int _selected = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _select(int index) {
    setState(() => _selected = index);
    _pageController.animateToPage(
      index,
      duration: AppMotion.slow,
      curve: AppMotion.standard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final companies = ref.watch(sortedCompaniesProvider);
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _MapCanvas(
              companies: companies,
              selectedIndex: _selected,
              onSelect: _select,
            ),
          ),

          // Top chrome: search + filter, floating on glass.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                AppDimensions.gutter,
                topPad + AppDimensions.space8,
                AppDimensions.gutter,
                AppDimensions.space12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    c.background.withValues(alpha: 0.96),
                    c.background.withValues(alpha: 0),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppSearchField(
                      hint: 'Manzil yoki kompaniya qidirish',
                      readOnly: true,
                      onTap: () => AppToast.show(
                        context,
                        'Qidiruv Google Places bilan ulanadi',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  AppIconButton(
                    icon: Icons.tune_rounded,
                    size: 48,
                    iconSize: 20,
                    onTap: () => context.push('/companies'),
                  ),
                ],
              ),
            ),
          ),

          // Right-hand controls.
          Positioned(
            right: AppDimensions.gutter,
            bottom: 236 + MediaQuery.paddingOf(context).bottom,
            child: Column(
              children: [
                const _CompassBadge(),
                const SizedBox(height: AppDimensions.space10),
                AppIconButton(
                  icon: Icons.layers_outlined,
                  size: 44,
                  onTap: () => AppToast.show(context, 'Qatlamlar: transport, trafik'),
                ),
                const SizedBox(height: AppDimensions.space10),
                AppIconButton(
                  icon: Icons.my_location_rounded,
                  size: 44,
                  foreground: c.primary,
                  onTap: () => AppToast.show(
                    context,
                    'Joylashuv aniqlanmoqda…',
                    icon: Icons.gps_fixed_rounded,
                  ),
                ),
              ],
            ),
          ),

          // Scale indicator, bottom-left — the other half of the standard
          // map-chrome pair with the compass. Sits above the "nearby
          // branches" pill so the two floating layers never collide.
          Positioned(
            left: AppDimensions.gutter,
            bottom: 336 + MediaQuery.paddingOf(context).bottom,
            child: const _ScaleBar(),
          ),

          // Bottom: pickup hint + company carousel.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: AppDimensions.bottomBarClearance - 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.gutter,
                      ),
                      child: Row(
                        children: [
                          const Flexible(
                            child: AppPill(
                              label: 'Yaqin atrofda 6 ta filial',
                              tone: PillTone.primary,
                              icon: Icons.place_rounded,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space8),
                          const Spacer(),
                          AppTappable(
                            onTap: () => context.push('/companies'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.space10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: c.surface,
                                borderRadius: AppDimensions.brPill,
                                border: Border.all(color: c.border),
                                boxShadow: c.shadowSm,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.list_rounded,
                                      size: 14, color: c.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Ro‘yxat',
                                    style: AppTypography.caption.copyWith(
                                      color: c.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space10),
                    SizedBox(
                      height: 190,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: companies.length,
                        padEnds: false,
                        onPageChanged: (i) => setState(() => _selected = i),
                        itemBuilder: (context, i) {
                          final company = companies[i];
                          return Padding(
                            padding: EdgeInsets.only(
                              left: i == 0 ? AppDimensions.gutter : AppDimensions.space6,
                              right: AppDimensions.space6,
                              top: AppDimensions.space4,
                              bottom: AppDimensions.space8,
                            ),
                            child: MapCompanyCard(
                              company: company,
                              width: double.infinity,
                              selected: i == _selected,
                              onTap: () => _select(i),
                              onSelect: () {
                                ref.read(selectedCompanyProvider.notifier).state =
                                    company;
                                ref.read(deliveryMethodProvider.notifier).state =
                                    DeliveryMethod.selfPickup;
                                context.push('/delivery-method', extra: company);
                              },
                            ),
                          );
                        },
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

/// Painted map + interactive markers. Positions are the real company
/// coordinates, normalised into the viewport.
class _MapCanvas extends StatelessWidget {
  const _MapCanvas({
    required this.companies,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<Company> companies;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;

    // Companies load asynchronously now (Supabase), so this can briefly
    // be empty right after launch — fall back to centering on Tashkent
    // instead of `reduce`-ing an empty list.
    final lats = companies.isEmpty
        ? [AppConstants.defaultLat]
        : companies.map((e) => e.latitude).toList();
    final lngs = companies.isEmpty
        ? [AppConstants.defaultLng]
        : companies.map((e) => e.longitude).toList();
    final minLat = lats.reduce(math.min) - 0.012;
    final maxLat = lats.reduce(math.max) + 0.012;
    final minLng = lngs.reduce(math.min) - 0.012;
    final maxLng = lngs.reduce(math.max) + 0.012;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        Offset project(double lat, double lng) {
          final x = (lng - minLng) / (maxLng - minLng) * width;
          // Latitude grows northwards, screen Y grows downwards.
          final y = (1 - (lat - minLat) / (maxLat - minLat)) * height * 0.72 +
              height * 0.08;
          return Offset(x, y);
        }

        final userPoint = project(41.311081, 69.240562);

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _StreetPainter(
                  water: c.isDark ? const Color(0xFF10243A) : const Color(0xFFD9E8F5),
                  land: c.isDark ? const Color(0xFF0D141F) : const Color(0xFFEFF3F8),
                  block: c.isDark ? const Color(0xFF141D2B) : const Color(0xFFE4EAF2),
                  road: c.isDark ? const Color(0xFF1F2A3B) : Colors.white,
                  park: c.isDark ? const Color(0xFF15291F) : const Color(0xFFDDEEDF),
                  highway: c.isDark ? const Color(0xFF6B4A1F) : const Color(0xFFF6C567),
                  isDark: c.isDark,
                ),
              ),
            ),

            // Route hint from the user to the selected company.
            if (companies.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _RouteLinePainter(
                      from: userPoint,
                      to: project(
                        companies[selectedIndex].latitude,
                        companies[selectedIndex].longitude,
                      ),
                      color: c.primary,
                    ),
                  ),
                ),
              ),

            // User location.
            Positioned(
              left: userPoint.dx - 16,
              top: userPoint.dy - 16,
              child: PulsingMarker(
                color: c.primary,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: c.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: c.primary.withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            for (int i = 0; i < companies.length; i++)
              Builder(
                builder: (context) {
                  final point =
                      project(companies[i].latitude, companies[i].longitude);
                  final selected = i == selectedIndex;
                  return Positioned(
                    left: point.dx - (selected ? 30 : 22),
                    top: point.dy - (selected ? 66 : 52),
                    child: _MapMarker(
                      company: companies[i],
                      selected: selected,
                      onTap: () => onSelect(i),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.company,
    required this.selected,
    required this.onTap,
  });

  final Company company;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final tone = company.isAvailable ? c.primary : c.textTertiary;

    return AppTappable(
      onTap: onTap,
      pressedScale: 0.9,
      child: AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.spring,
        width: selected ? 60 : 44,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: AppDimensions.brPill,
                  boxShadow: c.shadowSm,
                  border: Border.all(color: c.border),
                ),
                child: Text(
                  '${(company.productPrice / 1000).round()}k',
                  style: AppTypography.caption2.copyWith(
                    color: c.textPrimary,
                    fontSize: 10,
                  ),
                ),
              ),
            Container(
              width: selected ? 44 : 36,
              height: selected ? 44 : 36,
              decoration: BoxDecoration(
                color: tone,
                shape: BoxShape.circle,
                border: Border.all(color: c.surface, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: tone.withValues(alpha: 0.4),
                    blurRadius: selected ? 18 : 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white,
                size: selected ? 21 : 17,
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -3),
              child: CustomPaint(
                size: const Size(12, 8),
                painter: _PinTailPainter(tone),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  _PinTailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PinTailPainter old) => old.color != color;
}

/// Floating "N" badge — the other half of standard map chrome, paired
/// with [_ScaleBar]. Purely decorative for now; wire to the compass
/// sensor once heading tracking lands.
class _CompassBadge extends StatelessWidget {
  const _CompassBadge();

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: c.surface,
        shape: BoxShape.circle,
        border: Border.all(color: c.border),
        boxShadow: c.shadowSm,
      ),
      child: CustomPaint(
        painter: _CompassNeedlePainter(north: c.danger, south: c.textTertiary),
      ),
    );
  }
}

class _CompassNeedlePainter extends CustomPainter {
  _CompassNeedlePainter({required this.north, required this.south});

  final Color north;
  final Color south;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width * 0.3;

    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r * 0.42, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r * 0.42, center.dy)
      ..close();

    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy - r)
        ..lineTo(center.dx + r * 0.42, center.dy)
        ..lineTo(center.dx, center.dy)
        ..close(),
      Paint()..color = north,
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + r * 0.42, center.dy)
        ..lineTo(center.dx, center.dy + r)
        ..lineTo(center.dx - r * 0.42, center.dy)
        ..close(),
      Paint()..color = south,
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black.withValues(alpha: 0.08),
    );
  }

  @override
  bool shouldRepaint(covariant _CompassNeedlePainter old) => false;
}

/// "500 m" ruler — grounds the illustrated canvas as a map rather than a
/// decorative pattern, the way every real map app anchors its chrome.
class _ScaleBar extends StatelessWidget {
  const _ScaleBar();

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.92),
        borderRadius: AppDimensions.brPill,
        border: Border.all(color: c.border),
        boxShadow: c.shadowSm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 2,
            color: c.textSecondary,
          ),
          const SizedBox(height: 3),
          Text(
            '500 m',
            style: AppTypography.caption2.copyWith(
              color: c.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteLinePainter extends CustomPainter {
  _RouteLinePainter({required this.from, required this.to, required this.color});

  final Offset from;
  final Offset to;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final control = Offset(
      (from.dx + to.dx) / 2 + (to.dy - from.dy) * 0.22,
      (from.dy + to.dy) / 2 - (to.dx - from.dx) * 0.22,
    );
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.18),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _RouteLinePainter old) =>
      old.from != from || old.to != to || old.color != color;
}

/// Draws a plausible city: shaded blocks, a highway, local streets, a
/// river and a park — readable at a glance, never competing with the
/// cards on top, but textured enough to read as a *map* rather than a
/// tiled pattern.
class _StreetPainter extends CustomPainter {
  _StreetPainter({
    required this.water,
    required this.land,
    required this.block,
    required this.road,
    required this.park,
    required this.highway,
    required this.isDark,
  });

  final Color water;
  final Color land;
  final Color block;
  final Color road;
  final Color park;
  final Color highway;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    // Land: a faint gradient reads as ambient light rather than a flat fill.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [land, Color.lerp(land, block, 0.25)!],
        ).createShader(Offset.zero & size),
    );

    final random = math.Random(7);
    final shadowColor = Colors.black.withValues(alpha: isDark ? 0.35 : 0.08);
    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final shades = [
      block,
      Color.lerp(block, land, 0.35)!,
      Color.lerp(block, road, 0.2)!,
    ];

    // City blocks: varied shade + soft drop shadow for a touch of depth.
    for (double y = -20; y < size.height + 40; y += 74) {
      for (double x = -20; x < size.width + 40; x += 88) {
        final w = 52 + random.nextDouble() * 26;
        final h = 40 + random.nextDouble() * 22;
        final rect = Rect.fromLTWH(
          x + random.nextDouble() * 8,
          y + random.nextDouble() * 8,
          w,
          h,
        );
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(5));
        canvas.drawRRect(rrect.shift(const Offset(0, 2)), shadowPaint);
        canvas.drawRRect(rrect, Paint()..color = shades[random.nextInt(shades.length)]);
      }
    }

    // Park, with a scatter of tree dots instead of a flat fill.
    final parkRect = Rect.fromLTWH(
      size.width * 0.06,
      size.height * 0.52,
      size.width * 0.3,
      size.height * 0.16,
    );
    final parkRRect = RRect.fromRectAndRadius(parkRect, const Radius.circular(20));
    canvas.drawRRect(parkRRect.shift(const Offset(0, 2)), shadowPaint);
    canvas.drawRRect(parkRRect, Paint()..color = park);
    canvas.save();
    canvas.clipRRect(parkRRect);
    final treeColor = Color.lerp(park, Colors.black, 0.18)!;
    for (double y = parkRect.top + 6; y < parkRect.bottom; y += 13) {
      for (double x = parkRect.left + 6; x < parkRect.right; x += 15) {
        canvas.drawCircle(
          Offset(x + random.nextDouble() * 4, y + random.nextDouble() * 4),
          2.2,
          Paint()..color = treeColor.withValues(alpha: 0.55),
        );
      }
    }
    canvas.restore();

    // River: two-tone gradient stroke plus a lighter shoreline highlight.
    final river = Path()
      ..moveTo(-20, size.height * 0.24)
      ..cubicTo(
        size.width * 0.3, size.height * 0.30,
        size.width * 0.42, size.height * 0.06,
        size.width * 0.72, size.height * 0.14,
      )
      ..cubicTo(
        size.width * 0.9, size.height * 0.18,
        size.width * 0.96, size.height * 0.32,
        size.width + 20, size.height * 0.30,
      );
    canvas.drawPath(
      river,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [water, Color.lerp(water, Colors.black, 0.15)!],
        ).createShader(river.getBounds()),
    );
    canvas.drawPath(
      river,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: isDark ? 0.08 : 0.35),
    );

    // Local streets.
    final roadPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = road;

    for (double y = 18; y < size.height; y += 74) {
      roadPaint.strokeWidth = y % 148 < 74 ? 8 : 4;
      canvas.drawLine(Offset(-20, y), Offset(size.width + 20, y), roadPaint);
    }
    for (double x = 26; x < size.width; x += 88) {
      roadPaint.strokeWidth = x % 176 < 88 ? 8 : 4;
      canvas.drawLine(Offset(x, -20), Offset(x, size.height + 20), roadPaint);
    }

    // Highway: a diagonal avenue in a distinct tone, with a dashed
    // centerline — the single strongest cue that this is a map, not a
    // pattern.
    final highwayPath = Path()
      ..moveTo(-20, size.height * 0.86)
      ..lineTo(size.width + 20, size.height * 0.34);
    canvas.drawPath(
      highwayPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round
        ..color = shadowColor,
    );
    canvas.drawPath(
      highwayPath.shift(const Offset(0, -3)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round
        ..color = highway,
    );
    canvas.drawPath(
      dashPath(highwayPath.shift(const Offset(0, -3)), dashLength: 14, gapLength: 10),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.8),
    );

    // Vignette: darkens the corners a touch so the cards on top feel
    // anchored to something with depth, not a flat sticker.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.1,
          colors: [Colors.transparent, Colors.black.withValues(alpha: isDark ? 0.28 : 0.06)],
          stops: const [0.6, 1.0],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _StreetPainter old) => old.land != land;
}
