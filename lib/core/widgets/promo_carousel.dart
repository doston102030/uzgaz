import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/typography.dart';
import 'app_tappable.dart';

/// One [PromoCard]'s worth of content for [PromoCarousel].
class PromoSlide {
  const PromoSlide({
    required this.onTap,
    required this.title,
    required this.caption,
    required this.accent,
    this.footIcon = Icons.local_shipping_outlined,
    this.motionLines = false,
    this.image,
    this.icon = Icons.local_fire_department_rounded,
  });

  final VoidCallback onTap;
  final String title;
  final String caption;

  /// Tints the card, the caption and the art.
  final Color accent;

  /// Small glyph in the bottom-left corner (the delivery truck, etc.).
  final IconData footIcon;

  /// Speed lines streaming behind [footIcon] — for the delivery slide.
  final bool motionLines;

  /// Cut-out product shot (transparent PNG asset) on the right. Without
  /// one, [icon] is drawn as a glowing badge instead.
  final String? image;
  final IconData icon;
}

/// Auto-rotating home-page promo banner: a swipeable `PageView` of
/// [PromoCard]s — plus the
/// left/right chevron arrows a plain auto-rotating banner needs so a
/// buyer isn't stuck waiting for the next slide (or guessing there are
/// more than one).
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({
    super.key,
    required this.slides,
    this.autoRotate = const Duration(seconds: 6),
  });

  final List<PromoSlide> slides;

  /// How long each slide stays before auto-advancing. Any manual swipe
  /// or arrow tap resets this timer, so it never fights the buyer.
  final Duration autoRotate;

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  late final PageController _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _scheduleAutoRotate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleAutoRotate() {
    _timer?.cancel();
    if (widget.slides.length < 2) return;
    _timer = Timer.periodic(widget.autoRotate, (_) {
      _goTo((_index + 1) % widget.slides.length);
    });
  }

  void _goTo(int index) {
    if (!_controller.hasClients) return;
    _controller.animateToPage(index, duration: AppMotion.slow, curve: AppMotion.standard);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) return const SizedBox.shrink();
    final single = widget.slides.length == 1;

    return Column(
      children: [
        SizedBox(
          height: 148,
          child: PageView.builder(
            controller: _controller,
            // The card's coloured glow reaches past its bounds; clipping
            // it at the page rect drew a hard square behind the rounded
            // corners. Only the visible page is built, so nothing leaks.
            clipBehavior: Clip.none,
            itemCount: widget.slides.length,
            onPageChanged: (i) {
              setState(() => _index = i);
              _scheduleAutoRotate();
            },
            itemBuilder: (context, i) {
              final s = widget.slides[i];
              return PromoCard(slide: s);
            },
          ),
        ),
        if (!single) ...[
          const SizedBox(height: AppDimensions.space12),
          // Arrows flank the page dots, below the banner — on the slide
          // itself they covered the headline and the photo.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CarouselArrow(
                icon: Icons.chevron_left_rounded,
                label: 'Oldingi',
                onTap: () => _goTo((_index - 1 + widget.slides.length) % widget.slides.length),
              ),
              const SizedBox(width: AppDimensions.space10),
              for (int i = 0; i < widget.slides.length; i++)
                AnimatedContainer(
                  duration: AppMotion.base,
                  curve: AppMotion.standard,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _index
                        ? context.palette.primary
                        : context.palette.borderStrong,
                    borderRadius: AppDimensions.brPill,
                  ),
                ),
              const SizedBox(width: AppDimensions.space10),
              _CarouselArrow(
                icon: Icons.chevron_right_rounded,
                label: 'Keyingi',
                onTap: () => _goTo((_index + 1) % widget.slides.length),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Left/right "‹ ›" control beside the page dots — always tappable, not
/// just decorative, so the carousel never feels stuck.
class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Semantics(
      button: true,
      label: label,
      child: AppTappable(
        onTap: onTap,
        pressedScale: 0.88,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: c.surface,
            shape: BoxShape.circle,
            border: Border.all(color: c.border),
            boxShadow: c.shadowSm,
          ),
          child: Icon(icon, color: c.textSecondary, size: 18),
        ),
      ),
    );
  }
}

/// Light promo card: headline and accent caption on the left, a footer
/// glyph (the truck, with speed lines streaming behind it) bottom-left,
/// and a cut-out product shot gently floating on the right over a soft
/// halo.
class PromoCard extends StatefulWidget {
  const PromoCard({super.key, required this.slide});

  final PromoSlide slide;

  @override
  State<PromoCard> createState() => _PromoCardState();
}

class _PromoCardState extends State<PromoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _loop
        ..stop()
        ..value = 0.25;
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final s = widget.slide;
    final accent = s.accent;
    const radius = BorderRadius.all(Radius.circular(24));

    final background = c.isDark
        ? [
            Color.alphaBlend(accent.withValues(alpha: 0.14), c.surface),
            Color.alphaBlend(accent.withValues(alpha: 0.26), c.surface),
          ]
        : [
            Color.lerp(Colors.white, accent, 0.05)!,
            Color.lerp(Colors.white, accent, 0.15)!,
          ];
    final caption = _legibleOn(accent, background.last);
    final ink = c.textPrimary;

    return AppTappable(
      onTap: s.onTap,
      pressedScale: 0.98,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: background,
          ),
          border: Border.all(
            color: c.isDark
                ? Colors.white.withValues(alpha: 0.06)
                : accent.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: c.isDark ? 0.22 : 0.16),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.maxHeight;
              final artWidth = math.min(132.0, constraints.maxWidth * 0.36);
              final textWidth = math.max(
                0.0,
                constraints.maxWidth - AppDimensions.space20 - artWidth - 16,
              );
              final compact = textWidth < 170;
              return AnimatedBuilder(
                animation: _loop,
                builder: (context, _) {
                  final t = _loop.value;
                  // One slow breath per loop: the art lifts 3 px and its
                  // shadow tightens as it does.
                  final lift = math.sin(t * 2 * math.pi);
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _PromoHaloPainter(
                            accent: accent,
                            dark: c.isDark,
                            center: Offset(
                              constraints.maxWidth - artWidth / 2 - 8,
                              height * 0.52,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        top: 10,
                        bottom: 8,
                        width: artWidth,
                        child: Transform.translate(
                          offset: Offset(0, -3 * lift),
                          child: s.image != null
                              ? _CutoutArt(
                                  image: s.image!,
                                  icon: s.icon,
                                  accent: accent,
                                  lift: lift,
                                )
                              : _BadgeArt(icon: s.icon, accent: accent),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppDimensions.space20,
                          AppDimensions.space20,
                          artWidth + 16,
                          AppDimensions.space16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Shrinks as a block, never overflows: narrow
                            // phones wrap both lines, large system text
                            // scales the pair down to fit above the footer.
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.topLeft,
                                child: SizedBox(
                                  width: textWidth,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.title3.copyWith(
                                          color: ink,
                                          fontSize: compact ? 17 : 19,
                                          fontWeight: FontWeight.w800,
                                          height: 1.15,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: AppDimensions.space6,
                                      ),
                                      Text(
                                        s.caption,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            AppTypography.subhead.copyWith(
                                          color: caption,
                                          fontSize: compact ? 12.5 : 13.5,
                                          fontWeight: FontWeight.w600,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (s.motionLines) ...[
                                  SizedBox(
                                    width: 22,
                                    height: 18,
                                    child: CustomPaint(
                                      painter: _SpeedLinesPainter(
                                        t: t,
                                        color: caption,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Icon(s.footIcon, size: 30, color: ink),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Cut-out product shot with a soft contact shadow that tightens as the
/// shot floats up ([lift] -1…1).
class _CutoutArt extends StatelessWidget {
  const _CutoutArt({
    required this.image,
    required this.icon,
    required this.accent,
    required this.lift,
  });

  final String image;
  final IconData icon;
  final Color accent;
  final double lift;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          bottom: -3 - 3 * lift,
          child: Container(
            width: 58 - 6 * lift,
            height: 10,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.elliptical(29, 5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22 - 0.05 * lift),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: Image.asset(
            image,
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => _BadgeArt(icon: icon, accent: accent),
          ),
        ),
      ],
    );
  }
}

/// Stand-in art when a slide has no cut-out photo: the category glyph on
/// a glowing accent disc.
class _BadgeArt extends StatelessWidget {
  const _BadgeArt({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(accent, Colors.white, 0.3)!,
              accent,
              Color.lerp(accent, Colors.black, 0.15)!,
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.40),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, size: 38, color: Colors.white),
      ),
    );
  }
}

/// Soft halo and ring behind the art, plus faint bubbles at the edges, so
/// the right side never reads as a flat block of colour.
class _PromoHaloPainter extends CustomPainter {
  _PromoHaloPainter({
    required this.accent,
    required this.dark,
    required this.center,
  });

  final Color accent;
  final bool dark;
  final Offset center;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height * 0.62;
    final halo = dark ? accent : Colors.white;
    canvas
      ..drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              halo.withValues(alpha: dark ? 0.22 : 0.85),
              halo.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      )
      ..drawCircle(
        center,
        r * 0.78,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = accent.withValues(alpha: dark ? 0.22 : 0.14),
      )
      ..drawCircle(
        Offset(size.width - 18, size.height + 6),
        size.height * 0.34,
        Paint()..color = accent.withValues(alpha: dark ? 0.16 : 0.10),
      )
      ..drawCircle(
        Offset(size.width * 0.52, -size.height * 0.12),
        size.height * 0.30,
        Paint()
          ..color = (dark ? Colors.white : accent).withValues(alpha: 0.05),
      );
  }

  @override
  bool shouldRepaint(_PromoHaloPainter old) =>
      old.accent != accent || old.dark != dark || old.center != center;
}

/// Three dashes streaming right-to-left behind the truck, so it reads as
/// moving. [t] is the 0–1 loop phase.
class _SpeedLinesPainter extends CustomPainter {
  _SpeedLinesPainter({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const lengths = [12.0, 16.0, 9.0];
    for (var i = 0; i < lengths.length; i++) {
      final y = size.height * (0.25 + 0.25 * i);
      // Each dash crosses the full width twice per loop, offset in phase.
      final phase = (t * 2 + i * 0.37) % 1;
      final x = size.width * (1 - phase) - lengths[i] * 0.5;
      final fade = math.sin(phase * math.pi);
      canvas.drawLine(
        Offset(math.max(0, x), y),
        Offset(math.min(size.width, x + lengths[i]), y),
        Paint()
          ..color = color.withValues(alpha: 0.85 * fade)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_SpeedLinesPainter old) =>
      old.t != t || old.color != color;
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Shifts [accent]'s lightness until it reads on [background] (4.5:1).
Color _legibleOn(Color accent, Color background) {
  final darken = background.computeLuminance() > 0.4;
  var hsl = HSLColor.fromColor(accent);
  for (var i = 0; i < 30 && _contrast(hsl.toColor(), background) < 4.5; i++) {
    hsl = hsl.withLightness(
      (hsl.lightness + (darken ? -0.025 : 0.025)).clamp(0.0, 1.0),
    );
  }
  return hsl.toColor();
}
