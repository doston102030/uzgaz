import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/motion.dart';
import '../constants/app_constants.dart';
import 'app_surface.dart';
import 'category_artwork.dart';

/// Service categories as one row that scrolls sideways — it never wraps to
/// a second line. Each category is one white card, like the product cards
/// below it: the artwork on a softly tinted panel inset at the top (its
/// corners follow the card's), and the name on a glossy green 3D plate
/// underneath that presses in like a key. Categories that aren't live yet
/// look the same, only their artwork stays still; tapping them is still
/// reported, so the caller can say "coming soon".
class ServiceCategoryGrid extends StatelessWidget {
  const ServiceCategoryGrid({
    super.key,
    required this.onSelected,
    this.padding = EdgeInsets.zero,
  });

  final ValueChanged<ServiceCategory> onSelected;

  /// Inside the scroll view, so the row can run to the screen edges while
  /// its first card still lines up with the page gutter.
  final EdgeInsetsGeometry padding;

  static bool isAvailable(ServiceCategory category) =>
      category == ServiceCategory.gazBallon ||
      category == ServiceCategory.suyultirilganGaz;

  static const double _gap = 10;

  /// Preferred card width at normal text size.
  static const double _preferred = 88;

  /// How much of the next card shows at the edge, so the row reads as
  /// scrollable instead of cut off.
  static const double _peek = .55;

  /// Room above and below the cards for their shadow, which the list
  /// would otherwise clip.
  static const _shadowRoom = EdgeInsets.only(top: 2, bottom: 10);

  @override
  Widget build(BuildContext context) {
    final text = MediaQuery.textScalerOf(context);
    final grow = (text.scale(12) / 12).clamp(1.0, 1.4);
    final count = ServiceCategory.values.length;
    final pad = padding.resolve(Directionality.of(context));

    return LayoutBuilder(builder: (context, constraints) {
      // The row runs past the right edge, so only the leading padding
      // eats into what's visible.
      final visible = constraints.maxWidth - pad.left;
      final preferred = _preferred * grow;
      final fits = (visible + _gap) / (preferred + _gap);
      final double card;
      if (fits >= count) {
        card = preferred;
      } else {
        // Whole cards plus a slice of the next one, whatever the width.
        final whole = (fits - _peek).round().clamp(2, count - 1);
        // Whole pixels keep the card edges crisp.
        card = ((visible - whole * _gap) / (whole + _peek))
            .clamp(80 * grow, 104 * grow)
            .floorToDouble();
      }
      // Big text widens the card for the name; the stage (and its
      // artwork) grows only half as much.
      final stage = card / grow * (1 + (grow - 1) * .5) * .8;
      final height = _ServiceCard.heightFor(stage, text);

      return SizedBox(
        height: height + _shadowRoom.vertical,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: pad.add(_shadowRoom),
          itemCount: count,
          separatorBuilder: (_, __) => const SizedBox(width: _gap),
          itemBuilder: (context, i) {
            final category = ServiceCategory.values[i];
            return SizedBox(
              width: card,
              child: _ServiceCard(
                category: category,
                stage: stage,
                onTap: () => onSelected(category),
              ),
            );
          },
        ),
      );
    });
  }
}

class _ServiceCard extends StatefulWidget {
  const _ServiceCard({
    required this.category,
    required this.stage,
    required this.onTap,
  });

  final ServiceCategory category;
  final double stage;
  final VoidCallback onTap;

  static const double _inset = 5;
  static const double _radius = 20;
  static const _padding = EdgeInsets.fromLTRB(_inset, _inset, _inset, 6);

  /// Stage + gap + plate (with its 3D edge) + padding + the card's 1 px
  /// border top and bottom.
  static double heightFor(double stage, TextScaler text) =>
      stage +
      _inset +
      _NamePlate.heightFor(text) +
      _NamePlate.depth +
      _padding.vertical +
      2;

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _pressed = false;
  Offset? _down;

  void _press(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final category = widget.category;
    final active = ServiceCategoryGrid.isAvailable(category);
    final accent = category.color;
    const inner = _ServiceCard._radius - _ServiceCard._inset;

    return Semantics(
      button: true,
      label: '${category.titleUz}${active ? '' : ', tez orada'}',
      excludeSemantics: true,
      // A Listener sees the press without joining the gesture arena, so
      // AppCard still owns the tap; a drag (scrolling the row) lets go.
      child: Listener(
        onPointerDown: (e) {
          _down = e.position;
          _press(true);
        },
        onPointerMove: (e) {
          if (_down != null && (e.position - _down!).distance > kTouchSlop) {
            _press(false);
          }
        },
        onPointerUp: (_) => _press(false),
        onPointerCancel: (_) => _press(false),
        child: AppCard(
          onTap: widget.onTap,
          padding: _ServiceCard._padding,
          radius: _ServiceCard._radius,
          // Keeps the plate's glow inside the card.
          clip: true,
          child: Column(children: [
            Container(
              height: widget.stage,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: c.isDark ? .24 : .14),
                    accent.withValues(alpha: c.isDark ? .10 : .05),
                  ],
                ),
                // Concentric with the card: its radius minus the inset.
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(inner),
                ),
              ),
              child: CategoryArtwork(
                category: category,
                animate: active,
                size: widget.stage,
              ),
            ),
            const SizedBox(height: _ServiceCard._inset),
            _NamePlate(
              label: category.titleUz,
              radius: inner,
              pressed: _pressed,
            ),
          ]),
        ),
      ),
    );
  }
}

/// The name on a glossy green plate with a darker edge showing beneath
/// it, so it reads as a raised 3D key. Pressing sinks it onto that edge.
class _NamePlate extends StatelessWidget {
  const _NamePlate({
    required this.label,
    required this.radius,
    required this.pressed,
  });

  final String label;
  final double radius;
  final bool pressed;

  /// How far the plate stands above its edge.
  static const double depth = 3;

  static const double _fontSize = 12;
  static const double _lineHeight = 1.2;
  static const Color _green = Color(0xFF189A49);

  static const double _textInset = 3;

  /// Room for two lines, so every plate (and card) is the same height;
  /// a one-line name sits centred.
  static double heightFor(TextScaler text) =>
      text.scale(_fontSize) * _lineHeight * 2 + 12;

  /// The font size at which the name's longest word fits on one line —
  /// a narrow card shrinks the text rather than splitting "Suyultirilgan".
  static double _fittedSize(
    String label,
    TextStyle style,
    TextScaler scaler,
    double maxWidth,
  ) {
    var widest = 0.0;
    for (final word in label.split(' ')) {
      final painter = TextPainter(
        text: TextSpan(text: word, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      if (painter.width > widest) widest = painter.width;
      painter.dispose();
    }
    if (widest <= maxWidth) return _fontSize;
    // A hair under the exact ratio, so rounding never tips it over.
    return _fontSize * maxWidth / widest * .98;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final height = heightFor(MediaQuery.textScalerOf(context));
    final light = Color.lerp(_green, Colors.white, .24)!;
    final deep = Color.lerp(_green, Colors.black, .16)!;
    final edge = Color.lerp(_green, Colors.black, .42)!;
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    final lift = pressed ? 1.0 : depth;
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.instant;

    return SizedBox(
      height: height + depth,
      child: Stack(children: [
        // The plate's side, showing below its face, with a soft green glow.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: height,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: edge,
              shape: shape,
              shadows: [
                BoxShadow(
                  color: _green.withValues(alpha: c.isDark ? .42 : .3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
        AnimatedPositioned(
          duration: motion,
          curve: AppMotion.standard,
          left: 0,
          right: 0,
          top: depth - lift,
          height: height,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: shape,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [light, _green, deep],
                stops: const [0, .55, 1],
              ),
            ),
            child: Stack(fit: StackFit.expand, children: [
              // Gloss: a bright sheen across the upper half.
              Positioned(
                left: 3,
                right: 3,
                top: 2,
                height: height * .46,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(radius - 2),
                        bottom: Radius.circular(radius * .7),
                      ),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: .42),
                        Colors.white.withValues(alpha: .04),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _textInset),
                child: LayoutBuilder(builder: (context, box) {
                  // Merged with the inherited style, so the measuring
                  // below uses the same font family the Text will.
                  final style =
                      DefaultTextStyle.of(context).style.merge(TextStyle(
                            fontSize: _fontSize,
                            height: _lineHeight,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .1,
                            color: Colors.white,
                            // A crisp dark-green emboss keeps the white legible
                            // on the bright top of the plate.
                            shadows: [
                              Shadow(
                                color: edge.withValues(alpha: .6),
                                offset: const Offset(0, 1),
                                blurRadius: 1.5,
                              ),
                            ],
                          ));
                  final size = _fittedSize(label, style,
                      MediaQuery.textScalerOf(context), box.maxWidth);
                  // Full plate width, centred by textAlign.
                  return Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: style.copyWith(fontSize: size),
                      ),
                    ),
                  );
                }),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
