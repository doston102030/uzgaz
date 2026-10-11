import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/typography.dart';
import '../utils/haptics.dart';
import 'app_surface.dart';

class AppTabItem {
  const AppTabItem(this.icon, this.activeIcon, this.label, {this.accent});
  final IconData icon;
  final IconData activeIcon;
  final String label;

  /// Colour of the bead (and its glow) while this tab is active. Falls
  /// back to the palette's primary.
  final Color? accent;
}

/// Geometry of the liquid dock. All values are in logical pixels.
class _Dock {
  _Dock._();

  static const double barHeight = AppDimensions.bottomNavHeight;
  static const double cornerRadius = 22;

  /// The active tab's floating circle.
  static const double beadRadius = 24;

  /// Ring of bar skin between the bead and the outline.
  static const double gap = 5;
  static const double bumpRadius = beadRadius + gap;

  /// The bead's centre sits this far *below* the bar's top edge.
  static const double sink = 4;

  /// How far the bump stands above the bar.
  static const double rise = bumpRadius - sink;
  static const double height = rise + barHeight;

  /// Radius of the concave shoulders joining the bump to the top edge.
  static const double fillet = 10;

  /// Tighter shoulder allowed at the first and last tab, so the tabs need
  /// less inset from the bar's ends and keep more width for their labels.
  static const double edgeFillet = 6;

  // Tab content, measured from the bar's top edge: iOS-style icon over a
  // small label, every label on one baseline (the active one sits under
  // the bead on that same line).
  static const double iconSize = 24;
  static const double iconTop = 11;
  static const double labelTop = 38;
  static const double labelSize = 10.5;

  /// Minimum space between two neighbouring labels.
  static const double labelGap = 6;

  /// Horizontal distance from the bead's centre to where a shoulder of
  /// radius [f] meets the top edge. The shoulder circle touches both the
  /// edge and the bump, so the outline never creases.
  static double reach(double f) => math.sqrt(
        (bumpRadius + f) * (bumpRadius + f) - (sink + f) * (sink + f),
      );

  /// Largest shoulder whose [reach] still fits in [room] — keeps the bump
  /// off the rounded corners at the first and last tab.
  static double fit(double f, double room) {
    final max = (room * room - (bumpRadius * bumpRadius - sink * sink)) /
        (2 * (bumpRadius - sink));
    return f.clamp(0.0, math.max(0.0, max));
  }
}

/// Floating "liquid dock" tab bar: the active tab rises out of the bar as
/// a glowing bead in its own accent colour, the bar's skin melts around it
/// with tangent shoulders, and the bead springs between tabs — the trailing
/// shoulder stretches with its speed. Content scrolls *under* it (the shells
/// use `extendBody: true`).
///
/// Generic so the buyer, seller and admin shells all render the exact
/// same bar with their own item list (see [AppBottomNavigation],
/// [SellerBottomNavigation], [AdminBottomNavigation] below).
class AppTabBar extends StatefulWidget {
  const AppTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.badges = const {},
  });

  final List<AppTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// index -> count, e.g. `{2: 1}` to flag one active order.
  final Map<int, int> badges;

  @override
  State<AppTabBar> createState() => _AppTabBarState();
}

class _AppTabBarState extends State<AppTabBar>
    with SingleTickerProviderStateMixin {
  // Damping ratio ~0.8: a short glide with a hint of overshoot.
  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 33,
  );

  /// Bead position in tab units (0 = first tab), driven by [_spring].
  late final AnimationController _position = AnimationController.unbounded(
    vsync: this,
    value: _index.toDouble(),
  );

  late int _target = _index;

  /// Where the current glide started, and the tab it left.
  late double _fromPosition = _position.value;
  late int _fromIndex = _index;

  /// Bead colour at the start of the glide and on the last frame, so an
  /// interrupted glide blends on from wherever the colour was.
  Color? _fromAccent;
  Color? _shownAccent;

  int? _pressed;
  bool _reduceMotion = false;

  /// Tab labels follow the system text size, but only up to a point —
  /// like iOS, the bar's height is fixed.
  TextScaler _labelScaler = TextScaler.noScaling;
  Object? _labelKey;
  double _labelSize = _Dock.labelSize;

  int get _index => widget.currentIndex.clamp(0, widget.items.length - 1);

  @override
  void didUpdateWidget(AppTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _index;
    if (target == _target) return;
    _fromIndex = _target;
    _target = target;
    _fromPosition = _position.value;
    _fromAccent = _shownAccent;
    if (_reduceMotion) {
      _position.value = target.toDouble();
    } else {
      _position.animateWith(
        SpringSimulation(
          _spring,
          _position.value,
          target.toDouble(),
          _position.velocity,
        ),
      );
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  void _setPressed(int? index) {
    if (_pressed != index) setState(() => _pressed = index);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _labelScaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.2);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // Sit just above the home indicator; phones without one get a fixed gap.
    final bottomGap = bottomInset > 0
        ? math.max(bottomInset - AppDimensions.space8, AppDimensions.space12)
        : AppDimensions.space12;

    return Stack(
      children: [
        // Soft fade so the dock reads as anchored while lists scroll
        // beneath it. Never catches taps.
        Positioned.fill(
          top: _Dock.rise,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    c.background.withValues(alpha: 0),
                    c.background.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimensions.bottomNavInset,
            0,
            AppDimensions.bottomNavInset,
            bottomGap,
          ),
          child: SizedBox(
            height: _Dock.height,
            child: LayoutBuilder(
              builder: (context, constraints) => AnimatedBuilder(
                animation: _position,
                builder: (context, _) =>
                    _buildDock(context, constraints.maxWidth),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDock(BuildContext context, double width) {
    final c = context.palette;
    final items = widget.items;
    final count = items.length;
    final layout = _DockLayout(width: width, count: count);

    // At rest, snap exactly onto the tab (the spring stops within a
    // tolerance). In flight, clamp so an overshoot at either end never
    // pushes the bump into the rounded corners.
    final moving = _position.isAnimating;
    final position = moving
        ? _position.value.clamp(0.0, count - 1.0)
        : _target.toDouble();
    final span = _target - _fromPosition;
    final progress = !moving || span.abs() < 1e-3
        ? 1.0
        : ((_position.value - _fromPosition) / span).clamp(0.0, 1.0);

    final targetAccent = items[_target].accent ?? c.primary;
    final fromAccent = _fromAccent ?? targetAccent;
    final accent = Color.lerp(fromAccent, targetAccent, progress)!;
    _shownAccent = accent;
    // Picked from the bead's colour on this frame, not blended — a blend
    // of white and navy is a muddy grey on any bead.
    final onAccent = _onAccent(accent);

    // Speed in px/s, normalised: leans the shoulders and squashes the bead.
    final lean = moving
        ? (_position.velocity * layout.slot / 1400).clamp(-1.0, 1.0)
        : 0.0;
    final squash = lean.abs();

    final cx = layout.center(position);
    final bead = Offset(cx, _Dock.bumpRadius);
    final skin = layout.skin(Size(width, _Dock.height), cx, lean);

    final surface = c.surface;
    // Without the live blur (web, see [kLiveBlur]) the fill closes up so
    // what scrolls beneath stays a soft hint rather than sharp text.
    const lift = kLiveBlur ? 0.0 : 0.08;
    final glass = c.isDark
        ? [
            Color.lerp(surface, Colors.white, 0.05)!
                .withValues(alpha: 0.86 + lift),
            surface.withValues(alpha: 0.80 + lift),
          ]
        : [
            surface.withValues(alpha: 0.90 + lift),
            surface.withValues(alpha: 0.84 + lift),
          ];
    final labelColor = _legibleOn(accent, surface);
    final labelStyle = AppTypography.caption2.copyWith(
      fontSize: _fitLabels(layout.slot),
      height: 1.2,
      letterSpacing: 0.1,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _DockUnderPainter(
                skin: skin,
                bead: bead,
                accent: accent,
                dark: c.isDark,
              ),
            ),
          ),
        ),
        // Frosted glass, cut to the skin's exact outline.
        Positioned.fill(
          child: IgnorePointer(
            child: ClipPath(
              clipper: _PathClipper(skin),
              child: _GlassFill(colors: glass),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _DockEdgePainter(
                skin: skin,
                bead: bead,
                accent: accent,
                edge: c.isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : c.border.withValues(alpha: 0.95),
              ),
            ),
          ),
        ),

        // Tabs, iOS style: outline icon over a small label, every label on
        // one baseline. The icon under the bead sinks and fades as if
        // absorbed; its label stays put and takes on the bead's colour.
        for (int i = 0; i < count; i++)
          _slot(
            layout,
            i,
            (1 - (position - i).abs()).clamp(0.0, 1.0),
            labelStyle,
            labelColor,
          ),

        // The bead.
        Positioned(
          left: cx - _Dock.beadRadius,
          top: _Dock.gap,
          width: _Dock.beadRadius * 2,
          height: _Dock.beadRadius * 2,
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(
                  1 + 0.08 * squash,
                  1 - 0.06 * squash,
                  1,
                ),
                child: AnimatedScale(
                  duration: AppMotion.fast,
                  curve: AppMotion.standard,
                  scale: _pressed == _target ? 0.9 : 1,
                  child: _Bead(
                    accent: accent,
                    dark: c.isDark,
                    child: AnimatedSwitcher(
                      duration: AppMotion.base,
                      switchInCurve: AppMotion.spring,
                      switchOutCurve: AppMotion.exit,
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: Tween<double>(begin: 0.4, end: 1)
                            .animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: Icon(
                        items[_target].activeIcon,
                        key: ValueKey(_target),
                        size: 22,
                        color: onAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if ((widget.badges[_target] ?? 0) > 0)
          Positioned(
            left: cx + _Dock.beadRadius * 0.45,
            top: _Dock.gap - 4,
            child: IgnorePointer(
              child: Opacity(
                opacity: progress,
                child: _Badge(count: widget.badges[_target]!),
              ),
            ),
          ),

        // Tap targets. The active one also covers the bump, so the bead
        // itself is tappable (re-tapping a tab returns to its root).
        for (int i = 0; i < count; i++)
          Positioned(
            left: i == 0 ? 0 : layout.pad + layout.slot * i,
            width: (i == 0 ? layout.pad : 0) +
                layout.slot +
                (i == count - 1 ? layout.pad : 0),
            top: i == _target ? 0 : _Dock.rise,
            bottom: 0,
            child: Semantics(
              button: true,
              selected: i == _target,
              label: items[i].label,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => _setPressed(i),
                onTapUp: (_) => _setPressed(null),
                onTapCancel: () => _setPressed(null),
                // Every press buzzes — re-tapping the current tab also acts.
                onTap: () {
                  AppHaptics.selection();
                  widget.onTap(i);
                },
              ),
            ),
          ),
      ],
    );
  }

  /// One tab. [cover] is how much of it the bead currently sits over (0–1).
  Widget _slot(
    _DockLayout layout,
    int i,
    double cover,
    TextStyle labelStyle,
    Color accentLabel,
  ) {
    final c = context.palette;
    final item = widget.items[i];
    final badge = widget.badges[i];
    // Bold only for the tab the bead is leaving or landing on — tabs it
    // merely flies over just catch its colour.
    final strong = cover > 0.5 && (i == _target || i == _fromIndex);
    return Positioned(
      left: layout.pad + layout.slot * i,
      width: layout.slot,
      top: _Dock.rise,
      height: _Dock.barHeight,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: AnimatedScale(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            scale: _pressed == i ? 0.9 : 1,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (cover < 1)
                  Positioned(
                    top: _Dock.iconTop,
                    left: 0,
                    right: 0,
                    child: Opacity(
                      opacity: 1 - cover,
                      child: Transform.translate(
                        offset: Offset(0, 8 * cover),
                        child: Transform.scale(
                          scale: 1 - 0.35 * cover,
                          child: Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  item.icon,
                                  size: _Dock.iconSize,
                                  color: c.textSecondary,
                                ),
                                if (badge != null && badge > 0)
                                  Positioned(
                                    right: -9,
                                    top: -4,
                                    child: _Badge(count: badge),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Free to run wider than the slot: [_fitLabels] already
                // sized the text so neighbours never touch.
                Positioned(
                  top: _Dock.labelTop,
                  left: -layout.slot,
                  right: -layout.slot,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    textScaler: _labelScaler,
                    style: labelStyle.copyWith(
                      color: Color.lerp(c.textSecondary, accentLabel, cover),
                      fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Label font size for a [slot] this wide. Every label shrinks alike —
  /// never one on its own — and only when two neighbours would otherwise
  /// touch on a narrow phone.
  double _fitLabels(double slot) {
    final key = (slot, _labelScaler, widget.items);
    if (key == _labelKey) return _labelSize;
    final widths = [
      for (final item in widget.items)
        (() {
          final painter = TextPainter(
            text: TextSpan(
              text: item.label,
              style: AppTypography.caption2.copyWith(
                fontSize: _Dock.labelSize,
                height: 1.2,
                letterSpacing: 0.1,
                fontWeight: FontWeight.w700,
              ),
            ),
            textDirection: TextDirection.ltr,
            textScaler: _labelScaler,
            maxLines: 1,
          )..layout();
          final width = painter.width;
          painter.dispose();
          return width;
        })(),
    ];
    var scale = 1.0;
    for (var i = 0; i + 1 < widths.length; i++) {
      final need = (widths[i] + widths[i + 1]) / 2 + _Dock.labelGap;
      if (need > slot) scale = math.min(scale, slot / need);
    }
    _labelKey = key;
    return _labelSize = _Dock.labelSize * math.max(scale, 0.7);
  }
}

/// Where the tabs sit inside the dock and the outline of its skin.
class _DockLayout {
  _DockLayout({required this.width, required this.count}) {
    // Inset the tabs just enough that the bump at the first and last tab,
    // shoulders included, clears the rounded corners.
    final needed = count < 2
        ? 0.0
        : (_Dock.cornerRadius + _Dock.reach(_Dock.edgeFillet) + 2 -
                width / (2 * count)) /
            (1 - 1 / count);
    pad = needed.clamp(AppDimensions.space8, width / 4);
    slot = (width - 2 * pad) / count;
  }

  final double width;
  final int count;
  late final double pad;
  late final double slot;

  /// Horizontal centre of tab [position] (fractional while gliding).
  double center(double position) => pad + slot * (position + 0.5);

  /// Rounded bar with a circular bump around the bead at [cx]. Velocity
  /// ([lean], -1…1) leans the surface: the trailing shoulder stretches,
  /// the leading one tightens.
  Path skin(Size size, double cx, double lean) {
    const top = _Dock.rise;
    const r = _Dock.cornerRadius;
    const radius = Radius.circular(r);
    final right = size.width;
    final bottom = size.height;
    final bead = Offset(cx, top + _Dock.sink);

    final fl = _Dock.fit(_Dock.fillet * (1 + 0.8 * lean), cx - r);
    final fr = _Dock.fit(_Dock.fillet * (1 - 0.5 * lean), right - r - cx);
    final dl = _Dock.reach(fl);
    final dr = _Dock.reach(fr);
    // Angle of the bead's centre as seen from each shoulder's centre.
    final al = math.atan2(_Dock.sink + fl, dl);
    final ar = math.atan2(_Dock.sink + fr, dr);

    final path = Path()
      ..moveTo(0, top + r)
      ..arcToPoint(const Offset(r, top), radius: radius)
      ..lineTo(cx - dl, top);
    if (fl > 0.01) {
      path.arcTo(
        Rect.fromCircle(center: Offset(cx - dl, top - fl), radius: fl),
        math.pi / 2,
        al - math.pi / 2,
        false,
      );
    }
    path.arcTo(
      Rect.fromCircle(center: bead, radius: _Dock.bumpRadius),
      al - math.pi,
      math.pi - al - ar,
      false,
    );
    if (fr > 0.01) {
      path.arcTo(
        Rect.fromCircle(center: Offset(cx + dr, top - fr), radius: fr),
        math.pi - ar,
        ar - math.pi / 2,
        false,
      );
    }
    return path
      ..lineTo(right - r, top)
      ..arcToPoint(Offset(right, top + r), radius: radius)
      ..lineTo(right, bottom - r)
      ..arcToPoint(Offset(right - r, bottom), radius: radius)
      ..lineTo(r, bottom)
      ..arcToPoint(Offset(0, bottom - r), radius: radius)
      ..close();
  }
}

/// Accent light pooling under the bead, plus the dock's drop shadow —
/// painted only *outside* the skin so it never muddies the glass.
class _DockUnderPainter extends CustomPainter {
  _DockUnderPainter({
    required this.skin,
    required this.bead,
    required this.accent,
    required this.dark,
  });

  final Path skin;
  final Offset bead;
  final Color accent;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    const glowRadius = 150.0;
    final glowCenter = Offset(bead.dx, size.height - _Dock.barHeight * 0.45);
    canvas
      ..save()
      ..translate(glowCenter.dx, glowCenter.dy)
      ..scale(1, 0.5)
      ..drawCircle(
        Offset.zero,
        glowRadius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              accent.withValues(alpha: dark ? 0.34 : 0.16),
              accent.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(center: Offset.zero, radius: glowRadius),
          ),
      )
      ..restore();

    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect((Offset.zero & size).inflate(80))
      ..addPath(skin, Offset.zero);
    canvas
      ..save()
      ..clipPath(outside)
      ..drawPath(
        skin.shift(const Offset(0, 10)),
        Paint()
          ..color = Colors.black.withValues(alpha: dark ? 0.45 : 0.10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      )
      ..drawPath(
        skin.shift(const Offset(0, 1)),
        Paint()
          ..color = Colors.black.withValues(alpha: dark ? 0.25 : 0.05)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_DockUnderPainter old) =>
      old.skin != skin ||
      old.bead != bead ||
      old.accent != accent ||
      old.dark != dark;
}

/// Hairline outline of the skin, lit in the accent colour near the bead.
class _DockEdgePainter extends CustomPainter {
  _DockEdgePainter({
    required this.skin,
    required this.bead,
    required this.accent,
    required this.edge,
  });

  final Path skin;
  final Offset bead;
  final Color accent;
  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      skin,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = edge,
    );
    final light = Rect.fromCircle(
      center: bead,
      radius: _Dock.bumpRadius * 2.4,
    );
    canvas.drawPath(
      skin,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: 0.75),
            accent.withValues(alpha: 0),
          ],
        ).createShader(light),
    );
  }

  @override
  bool shouldRepaint(_DockEdgePainter old) =>
      old.skin != skin ||
      old.bead != bead ||
      old.accent != accent ||
      old.edge != edge;
}

class _PathClipper extends CustomClipper<Path> {
  const _PathClipper(this.path);

  final Path path;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(_PathClipper oldClipper) => oldClipper.path != path;
}

/// The glowing accent circle that carries the active tab's icon.
class _Bead extends StatelessWidget {
  const _Bead({required this.accent, required this.dark, required this.child});

  final Color accent;
  final bool dark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(accent, Colors.white, 0.28)!,
            accent,
            Color.lerp(accent, Colors.black, 0.12)!,
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: dark ? 0.60 : 0.45),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 6,
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.5),
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.danger,
        borderRadius: AppDimensions.brPill,
        border: Border.all(color: c.surface, width: 2),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: AppTypography.caption2.copyWith(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// White or navy — whichever reads better on the bead.
Color _onAccent(Color accent) =>
    _contrast(Colors.white, accent) >= _contrast(AppColors.darkNavy, accent)
        ? Colors.white
        : AppColors.darkNavy;

/// Shifts [accent]'s lightness until it reads on [surface] (WCAG 4.5:1),
/// so a mint or orange label stays legible on the white bar.
Color _legibleOn(Color accent, Color surface) {
  final darken = surface.computeLuminance() > 0.5;
  var hsl = HSLColor.fromColor(accent);
  for (var i = 0; i < 30 && _contrast(hsl.toColor(), surface) < 4.5; i++) {
    hsl = hsl.withLightness(
      (hsl.lightness + (darken ? -0.025 : 0.025)).clamp(0.0, 1.0),
    );
  }
  return hsl.toColor();
}

/// Buyer shell: Bosh sahifa / Katalog / Buyurtmalar / Xarita / Profil.
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.badges = const {},
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final Map<int, int> badges;

  static const List<AppTabItem> _items = [
    AppTabItem(Icons.home_outlined, Icons.home_rounded, 'Bosh sahifa'),
    AppTabItem(Icons.grid_view_outlined, Icons.grid_view_rounded, 'Katalog',
        accent: AppColors.energyFlame),
    AppTabItem(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Buyurtmalar',
        accent: AppColors.energyElectric),
    AppTabItem(Icons.map_outlined, Icons.map_rounded, 'Xarita',
        accent: AppColors.energyMint),
    AppTabItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profil',
        accent: AppColors.energyRose),
  ];

  @override
  Widget build(BuildContext context) => AppTabBar(
        items: _items,
        currentIndex: currentIndex,
        onTap: onTap,
        badges: badges,
      );
}

/// Seller shell: Kabinet / Mahsulotlar / Buyurtmalar / Hisobot / Profil.
class SellerBottomNavigation extends StatelessWidget {
  const SellerBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.badges = const {},
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final Map<int, int> badges;

  static const List<AppTabItem> _items = [
    AppTabItem(Icons.space_dashboard_outlined, Icons.space_dashboard_rounded, 'Kabinet'),
    AppTabItem(Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Mahsulotlar',
        accent: AppColors.energyFlame),
    AppTabItem(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Buyurtmalar',
        accent: AppColors.energyElectric),
    AppTabItem(Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Hisobot',
        accent: AppColors.energyMint),
    AppTabItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profil',
        accent: AppColors.energyRose),
  ];

  @override
  Widget build(BuildContext context) => AppTabBar(
        items: _items,
        currentIndex: currentIndex,
        onTap: onTap,
        badges: badges,
      );
}

/// Admin shell: Bosh sahifa / Sotuvchilar / Mahsulotlar / Buyurtmalar / Sozlamalar.
class AdminBottomNavigation extends StatelessWidget {
  const AdminBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.badges = const {},
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final Map<int, int> badges;

  static const List<AppTabItem> _items = [
    AppTabItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Bosh sahifa'),
    AppTabItem(Icons.storefront_outlined, Icons.storefront_rounded, 'Sotuvchilar',
        accent: AppColors.energyMint),
    AppTabItem(Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Mahsulotlar',
        accent: AppColors.energyFlame),
    AppTabItem(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Buyurtmalar',
        accent: AppColors.energyElectric),
    AppTabItem(Icons.settings_outlined, Icons.settings_rounded, 'Sozlamalar',
        accent: AppColors.energyRose),
  ];

  @override
  Widget build(BuildContext context) => AppTabBar(
        items: _items,
        currentIndex: currentIndex,
        onTap: onTap,
        badges: badges,
      );
}

/// The dock's glass: frosted where the live blur is affordable, a plain
/// fill on the web (see [kLiveBlur]).
class _GlassFill extends StatelessWidget {
  const _GlassFill({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final fill = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
    );
    if (!kLiveBlur) return fill;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
      child: fill,
    );
  }
}
