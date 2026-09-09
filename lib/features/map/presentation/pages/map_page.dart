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

    final lats = companies.map((e) => e.latitude).toList();
    final lngs = companies.map((e) => e.longitude).toList();
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
              child: _UserDot(color: c.primary),
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

class _UserDot extends StatefulWidget {
  const _UserDot({required this.color});

  final Color color;

  @override
  State<_UserDot> createState() => _UserDotState();
}

class _UserDotState extends State<_UserDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 10 + 22 * _controller.value,
              height: 10 + 22 * _controller.value,
              decoration: BoxDecoration(
                color: widget.color
                    .withValues(alpha: 0.22 * (1 - _controller.value)),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.5),
                    blurRadius: 10,
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

/// Draws a plausible city: blocks, arterial roads, a river and a park —
/// readable at a glance, never competing with the cards on top.
class _StreetPainter extends CustomPainter {
  _StreetPainter({
    required this.water,
    required this.land,
    required this.block,
    required this.road,
    required this.park,
  });

  final Color water;
  final Color land;
  final Color block;
  final Color road;
  final Color park;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = land);

    final random = math.Random(7);
    final blockPaint = Paint()..color = block;

    // City blocks on a loose grid.
    for (double y = -20; y < size.height + 40; y += 74) {
      for (double x = -20; x < size.width + 40; x += 88) {
        final w = 52 + random.nextDouble() * 26;
        final h = 40 + random.nextDouble() * 22;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + random.nextDouble() * 8, y + random.nextDouble() * 8, w, h),
            const Radius.circular(5),
          ),
          blockPaint,
        );
      }
    }

    // Park.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.06, size.height * 0.52, size.width * 0.3,
            size.height * 0.16),
        const Radius.circular(20),
      ),
      Paint()..color = park,
    );

    // River.
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
        ..color = water,
    );

    // Roads.
    final roadPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = road;

    for (double y = 18; y < size.height; y += 74) {
      roadPaint.strokeWidth = y % 148 < 74 ? 9 : 5;
      canvas.drawLine(Offset(-20, y), Offset(size.width + 20, y), roadPaint);
    }
    for (double x = 26; x < size.width; x += 88) {
      roadPaint.strokeWidth = x % 176 < 88 ? 9 : 5;
      canvas.drawLine(Offset(x, -20), Offset(x, size.height + 20), roadPaint);
    }

    // A diagonal avenue to break the grid.
    roadPaint.strokeWidth = 11;
    canvas.drawLine(
      Offset(-20, size.height * 0.86),
      Offset(size.width + 20, size.height * 0.34),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _StreetPainter old) => old.land != land;
}
