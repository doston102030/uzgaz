import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'onboarding_film_art.dart';

/// The edit of the "GAZ & ENERGIYA — Oson buyurtma" creative, unchanged:
/// six scenes, 25 s in total, grouped into three chapters by the story bars.
abstract final class FilmTimeline {
  static const durations = [2500, 4000, 5500, 4500, 4500, 4000];
  static const starts = [0, 2500, 6500, 12000, 16500, 21000];
  static const total = 25000;
  static const sceneCount = 6;

  /// Story bars: question + advice, app + road, delivery + call to action.
  static const chapters = [(0, 6500), (6500, 16500), (16500, 25000)];

  /// What each scene shows, for screen readers.
  static const descriptions = [
    'GAZ KERAKMI? Mijoz: “Gaz balloni kelmayapti. Nima qilay?”',
    'Qo‘shningiz yechimni biladi. Mijoz: “Gaz kelmayapti. Nima qilsam '
        'bo‘ladi?” Qo‘shni: “Ilovadan buyurtma ber. GAZ & ENERGIYA!”',
    'Yechim telefonda. Ilovada kichik ballon tanlanadi, yetkazish manzili '
        'ko‘rsatiladi va “Buyurtma berish” bosiladi. Buyurtma qabul qilindi!',
    'Gaz yo‘lda. Ballonlar yuklangan gaz mashinasi gaz omboridan '
        'uyingizgacha kelmoqda.',
    'Gaz keldi. Ko‘ngil joyiga. Kuryer gaz ballonini eshikkacha olib keldi. '
        'Yetkazib berildi! “Rahmat, qo‘shni!”',
    'Oson buyurtma. Gazingiz. Uyingizgacha. GAZ & ENERGIYA.',
  ];

  static int sceneAt(double ms) {
    for (var i = sceneCount - 1; i > 0; i--) {
      if (ms >= starts[i]) return i;
    }
    return 0;
  }

  /// The last moment of [scene]: every entrance has finished, nothing is
  /// mid-motion. Used for paused navigation and reduced motion.
  static double settled(int scene) =>
      (starts[scene] + durations[scene] - 1).toDouble();

  /// The phone and the final scene sit on ink; the rest on paper.
  static bool isDark(int scene) => scene == 2 || scene == 5;
}

/// The creative rebuilt as a live Flutter scene. Everything is laid out on
/// the creative's own 405 × 720 canvas and scaled to fit, so the 9:16
/// composition never stretches. The film is a pure function of [time] —
/// the page owns the clock, which keeps pausing and seeking trivial.
class OnboardingFilm extends StatelessWidget {
  const OnboardingFilm({
    super.key,
    required this.time,
    this.reducedMotion = false,
  });

  /// Position in the edit, in milliseconds (0 … [FilmTimeline.total]).
  final double time;
  final bool reducedMotion;

  static const width = 405.0;
  static const height = 720.0;

  static const images = [
    'assets/images/onboarding/customer.jpg',
    'assets/images/onboarding/neighbor.jpg',
    'assets/images/onboarding/street.jpg',
    'assets/images/onboarding/truck.webp',
    'assets/images/onboarding/delivery.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    final t = time.clamp(0, FilmTimeline.total).toDouble();
    final scene = FilmTimeline.sceneAt(t);
    final local = t - FilmTimeline.starts[scene];
    final dark = FilmTimeline.isDark(scene);
    final Widget art = switch (scene) {
      0 => _QuestionScene(local),
      1 => _AdviceScene(local),
      2 => _AppScene(local, reducedMotion: reducedMotion),
      3 => _RoadScene(local),
      4 => _DeliveryScene(local),
      _ => _FinaleScene(local),
    };

    return MediaQuery.withNoTextScaling(
      child: FittedBox(
        child: SizedBox(
          width: width,
          height: height,
          child: DefaultTextStyle(
            style: filmText(12, color: filmInk),
            child: ColoredBox(
              color: dark ? filmInk : filmPaper,
              child: Stack(
                children: [
                  Positioned.fill(child: ExcludeSemantics(child: art)),
                  Positioned.fill(
                    child: ExcludeSemantics(
                      child: _Chrome(time: t, dark: dark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Motion helpers ──────────────────────────────────────────────────────

/// Eased progress of an entrance that starts at [delay] ms and lasts [dur]
/// ms — the equivalent of `animation: x <dur> <curve> <delay> both`.
double _at(double t, double delay, double dur, [Curve curve = filmEase]) {
  if (t <= delay) return 0;
  if (t >= delay + dur) return 1;
  return curve.transform((t - delay) / dur);
}

double _lerp(double a, double b, double p) => a + (b - a) * p;

/// One entrance: fades in while sliding, turning and scaling into place.
/// [turn] → [turnTo] are degrees; the offsets shrink to zero as [p] → 1.
class _In extends StatelessWidget {
  const _In(
    this.p, {
    this.dx = 0,
    this.dy = 0,
    this.turn = 0,
    this.turnTo = 0,
    this.scale = 1,
    required this.child,
  });

  final double p, dx, dy, turn, turnTo, scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final q = 1 - p;
    final s = _lerp(scale, 1, p);
    return Opacity(
      opacity: p.clamp(0.0, 1.0),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.translationValues(dx * q, dy * q, 0)
          ..rotateZ(_lerp(turn, turnTo, p) * math.pi / 180)
          ..scaleByDouble(s, s, 1, 1),
        child: child,
      ),
    );
  }
}

// ── Shared pieces ───────────────────────────────────────────────────────

const _muted = Color(0xFF788172);

class _Chrome extends StatelessWidget {
  const _Chrome({required this.time, required this.dark});

  final double time;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fills = [
      for (final (from, to) in FilmTimeline.chapters)
        ((time - from) / (to - from)).clamp(0.0, 1.0),
    ];
    return Stack(
      children: [
        Positioned(
          left: 22,
          right: 22,
          top: 14,
          height: 2,
          child: CustomPaint(
            painter: FilmProgressPainter(
              fills: fills,
              track: dark ? const Color(0x33FFFFFF) : const Color(0x2017221B),
            ),
          ),
        ),
        Positioned(
          left: 23,
          right: 23,
          top: 34,
          height: 36,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color:
                      dark ? const Color(0x30F5F1E8) : const Color(0x2817221B),
                ),
              ),
            ),
            child: Row(
              children: [
                const FilmGlyph.flame(size: 24),
                const SizedBox(width: 6),
                Text(
                  'GAZ & ENERGIYA',
                  style: filmText(11,
                      weight: FontWeight.w700,
                      color: dark ? filmPaper : filmInk,
                      spacing: .5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Widget _serial(String text, double t, {Color color = _muted}) {
  return Positioned(
    left: 25,
    top: 87,
    child: _In(
      _at(t, 0, 400),
      dy: 13,
      child: Text(text,
          style:
              filmText(8, weight: FontWeight.w700, color: color, spacing: 1.6)),
    ),
  );
}

Widget _footer(String text, {Color color = _muted}) {
  return Positioned(
    left: 24,
    right: 24,
    bottom: 18,
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: filmText(7, weight: FontWeight.w500, color: color, spacing: 1.4),
    ),
  );
}

/// Two-line headline, the second line in red.
Widget _headline(
  double t, {
  required double top,
  required String first,
  required String accent,
  required double size,
  required double height,
  required double spacing,
  Color color = filmInk,
  Widget? below,
}) {
  final style = filmText(size,
      weight: FontWeight.w700, color: color, height: height, spacing: spacing);
  // Each span carries the full style: the web engine drops a weight that
  // a span only inherits from `Text.rich(style:)`, which left the
  // headlines regular instead of bold.
  final title = Text.rich(
    TextSpan(children: [
      TextSpan(text: '$first\n', style: style),
      TextSpan(text: accent, style: style.copyWith(color: filmRed)),
    ]),
    style: style,
  );
  return Positioned(
    left: 24,
    right: 24,
    top: top,
    child: _In(
      _at(t, 50, 550),
      dy: 13,
      child: below == null
          ? title
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, below],
            ),
    ),
  );
}

class _Photo extends StatelessWidget {
  const _Photo(
    this.file, {
    required this.radius,
    this.border = 1.5,
    this.alignment = Alignment.topCenter,
  });

  final String file;
  final BorderRadius radius;
  final double border;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFD8D4C5),
        borderRadius: radius,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: filmInk, width: border),
      ),
      child: _image(file, alignment: alignment),
    );
  }
}

Widget _image(
  String file, {
  Alignment alignment = Alignment.topCenter,
  BoxFit fit = BoxFit.cover,
  double? width = double.infinity,
  double? height = double.infinity,
  Animation<double>? opacity,
}) {
  return Image.asset(
    'assets/images/onboarding/$file',
    fit: fit,
    alignment: alignment,
    width: width,
    height: height,
    opacity: opacity,
    gaplessPlayback: true,
    excludeFromSemantics: true,
    filterQuality: FilterQuality.medium,
  );
}

/// Text in a tight spot: one line, shrinking slightly rather than wrapping
/// if a platform font runs wider than Roboto.
class _OneLine extends StatelessWidget {
  const _OneLine(
    this.text, {
    required this.style,
    this.alignment = Alignment.centerLeft,
  });

  final String text;
  final TextStyle style;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(text, style: style, maxLines: 1, softWrap: false),
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast({required this.child, this.padding, this.radius = 12});

  final Widget child;
  final EdgeInsets? padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: filmPaper,
        border: Border.all(color: filmInk, width: 1.5),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [BoxShadow(color: filmRed, offset: Offset(4, 4))],
      ),
      child: child,
    );
  }
}

// ── 01 · 0:00–0:02.5 — "GAZ KERAKMI?" ───────────────────────────────────

class _QuestionScene extends StatelessWidget {
  const _QuestionScene(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _serial('01 / SAVOL', t),
        Positioned(
          left: 29,
          right: 29,
          top: 253,
          height: 381,
          child: _In(
            _at(t, 120, 650),
            dy: 35,
            turn: -3,
            child: const _Photo(
              'customer.jpg',
              border: 2,
              radius: BorderRadius.vertical(
                top: Radius.circular(174),
                bottom: Radius.circular(25),
              ),
            ),
          ),
        ),
        _footer('TANISH HOLAT. QULAY YECHIM.'),
        _headline(t,
            top: 112,
            first: 'GAZ',
            accent: 'KERAKMI?',
            size: 63,
            height: .92,
            spacing: -3.3),
        Positioned(
          left: 40,
          right: 27,
          top: 554,
          child: _In(
            _at(t, 450, 650),
            dy: 22,
            turn: 1,
            turnTo: -3,
            child: const _QuestionBubble(),
          ),
        ),
        Positioned(
          right: 18,
          top: 169,
          child: _In(
            _at(t, 300, 650),
            scale: .6,
            turn: -20,
            turnTo: 14,
            child: const FilmStamp(label: 'YECHIM\nBOR.'),
          ),
        ),
      ],
    );
  }
}

class _QuestionBubble extends StatelessWidget {
  const _QuestionBubble();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          decoration: BoxDecoration(
            color: filmPaper,
            border: Border.all(color: filmInk, width: 1.5),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: filmInk, offset: Offset(5, 5))],
          ),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                text: '“Gaz balloni kelmayapti.\n',
                style: filmText(16, height: 23 / 16),
              ),
              TextSpan(
                text: 'Nima qilay?”',
                style: filmText(23,
                    weight: FontWeight.w700, height: 28 / 23, spacing: -.8),
              ),
            ]),
            style: filmText(16, height: 23 / 16),
          ),
        ),
        // The speech-bubble tail, pointing up at the customer.
        Positioned(
          left: 34.5,
          top: -6.5,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 15,
              height: 15,
              decoration: const BoxDecoration(
                color: filmPaper,
                border: Border(
                  left: BorderSide(color: filmInk, width: 1.5),
                  top: BorderSide(color: filmInk, width: 1.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 02 · 0:02.5–0:06.5 — the neighbour's advice ─────────────────────────

class _AdviceScene extends StatelessWidget {
  const _AdviceScene(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    // The neighbour "types" before the answer lands.
    final typing = _at(t, 650, 150, Curves.easeOut) *
        (1 - _at(t, 1150, 100, Curves.linear));
    return Stack(
      children: [
        _serial('02 / TAVSIYA', t),
        Positioned(
          left: 27,
          top: 230,
          width: 160,
          height: 247,
          child: _In(
            _at(t, 120, 650),
            dy: 35,
            turn: -3,
            child: const _DialoguePortrait('customer.jpg', 'MIJOZ'),
          ),
        ),
        Positioned(
          right: 27,
          top: 230,
          width: 160,
          height: 247,
          child: _In(
            _at(t, 200, 650),
            dy: 35,
            turn: -3,
            child: const _DialoguePortrait('neighbor.jpg', 'QO‘SHNI'),
          ),
        ),
        Positioned(
          left: 187,
          top: 326,
          child: _In(
            _at(t, 450, 700),
            scale: .5,
            turn: -45,
            turnTo: -15,
            child: const FilmGlyph.arrow(size: 36, color: filmRed, weight: 2),
          ),
        ),
        Positioned(
          left: 24,
          top: 481,
          child: _In(
            _at(t, 350, 500),
            dy: 17,
            scale: .94,
            child: const _Chat(
              label: 'MIJOZ',
              message: '“Gaz kelmayapti.\nNima qilsam bo‘ladi?”',
            ),
          ),
        ),
        if (typing > 0)
          Positioned(
            right: 24,
            top: 570,
            child: Opacity(opacity: typing, child: _Typing(t)),
          ),
        Positioned(
          right: 24,
          top: 570,
          child: _In(
            _at(t, 1200, 500),
            dy: 17,
            scale: .94,
            child: const _Chat(
              label: 'QO‘SHNI',
              message: '“Ilovadan buyurtma ber.\n',
              strong: 'GAZ & ENERGIYA!”',
              accent: true,
            ),
          ),
        ),
        _footer('BIR TAVSIYA. BIR YECHIM.'),
        _headline(t,
            top: 113,
            first: 'QO‘SHNINGIZ',
            accent: 'YECHIMNI BILADI.',
            size: 32,
            height: 1.09,
            spacing: -1.5),
      ],
    );
  }
}

class _DialoguePortrait extends StatelessWidget {
  const _DialoguePortrait(this.file, this.caption);

  final String file;
  final String caption;

  static const _radius = BorderRadius.vertical(
    top: Radius.circular(95),
    bottom: Radius.circular(17),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Color(0xFFD8D4C5),
        borderRadius: _radius,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: _radius,
        border: Border.all(color: filmInk, width: 1.5),
      ),
      child: Column(
        children: [
          Expanded(child: _image(file)),
          Container(
            height: 31,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: filmPaper,
              border: Border(top: BorderSide(color: filmInk)),
            ),
            child: Text(caption,
                style: filmText(8, weight: FontWeight.w700, spacing: 1)),
          ),
        ],
      ),
    );
  }
}

class _Chat extends StatelessWidget {
  const _Chat({
    required this.label,
    required this.message,
    this.strong,
    this.accent = false,
  });

  final String label;
  final String message;
  final String? strong;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final fg = accent ? Colors.white : filmInk;
    final body = filmText(13, color: fg, height: 17 / 13);
    return Stack(
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 285),
          padding: EdgeInsets.fromLTRB(15, 13, accent ? 31 : 15, 13),
          decoration: BoxDecoration(
            color: accent ? filmRed : const Color(0xFFFFFDF7),
            border: accent ? null : Border.all(color: const Color(0xFFC5CBBB)),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(15),
              topRight: const Radius.circular(15),
              bottomLeft: Radius.circular(accent ? 15 : 3),
              bottomRight: Radius.circular(accent ? 3 : 15),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: filmText(6,
                      weight: FontWeight.w700,
                      color: fg.withValues(alpha: .65),
                      spacing: 1.2)),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(text: message, style: body, children: [
                  if (strong != null)
                    TextSpan(
                      text: strong,
                      style: body.copyWith(fontWeight: FontWeight.w700),
                    ),
                ]),
                style: body,
              ),
            ],
          ),
        ),
        if (accent)
          const Positioned(
            right: 9,
            bottom: 10,
            child: Row(
              children: [
                FilmGlyph.check(size: 9, color: Color(0xFFFFE3D3), weight: 2),
                SizedBox(width: 1),
                FilmGlyph.check(size: 9, color: Color(0xFFFFE3D3), weight: 2),
              ],
            ),
          ),
      ],
    );
  }
}

/// "…" while the neighbour is typing.
class _Typing extends StatelessWidget {
  const _Typing(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 34,
      decoration: const BoxDecoration(
        color: filmRed,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 3; i++)
            Transform.translate(
              offset: Offset(0, -2.5 * math.max(0, math.sin(t / 95 - i * .9))),
              child: Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                decoration: const BoxDecoration(
                  color: Color(0xE6FFFFFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── 03 · 0:06.5–0:12 — the order, in the app ────────────────────────────

const _appMuted = Color(0xFFA6AD9E);

class _AppScene extends StatelessWidget {
  const _AppScene(this.t, {required this.reducedMotion});

  final double t;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: -108,
          top: 303,
          width: 371,
          height: 371,
          child: Transform.scale(
            scale: _lerp(.9, 1.04, _at(t, 0, 5500, Curves.ease)),
            child: const DecoratedBox(
              decoration: BoxDecoration(color: filmRed, shape: BoxShape.circle),
            ),
          ),
        ),
        _serial('03 / BUYURTMA', t, color: _appMuted),
        _headline(t,
            top: 112,
            first: 'YECHIM',
            accent: 'TELEFONDA.',
            size: 50,
            height: .99,
            spacing: -2.4,
            color: filmPaper),
        Positioned(
          left: 25,
          top: 356,
          child: RotatedBox(
            quarterTurns: 3,
            child: Text(
              'GAZ BUYURTMASI\nTELEFONINGIZDA.',
              style: filmText(8,
                  weight: FontWeight.w700,
                  color: filmPaper,
                  height: 15 / 8,
                  spacing: 1.2),
            ),
          ),
        ),
        Positioned(
          left: 116,
          top: 282,
          width: 235,
          height: 394,
          child: _In(
            _at(t, 150, 800),
            dy: 60,
            turn: -15,
            turnTo: -6,
            child: _Device(t, reducedMotion: reducedMotion),
          ),
        ),
        Positioned(
          left: 25,
          right: 25,
          top: 230,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                _StepChip(1, 'Ballon', _at(t, 600, 400, Curves.ease)),
                const SizedBox(width: 7),
                _StepChip(2, 'Manzil', _at(t, 1400, 400, Curves.ease)),
                const SizedBox(width: 7),
                _StepChip(3, 'Buyurtma', _at(t, 2300, 400, Curves.ease)),
              ],
            ),
          ),
        ),
        if (!reducedMotion)
          Positioned(
            left: 25,
            top: 566,
            child: _In(
              _at(t, 3200, 650),
              dy: 24,
              child: _Toast(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FilmGlyph.check(size: 26, color: filmGreen),
                    const SizedBox(width: 10),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: 'Buyurtma\n',
                          style: filmText(8, color: filmInk, height: 14 / 8),
                        ),
                        TextSpan(
                          text: 'qabul qilindi!',
                          style: filmText(12,
                              weight: FontWeight.w700, height: 14 / 12),
                        ),
                      ]),
                      style: filmText(8, height: 14 / 8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        _footer('TANLANG. MANZILNI KIRITING. BUYURTMA BERING.',
            color: _appMuted),
      ],
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip(this.number, this.label, this.p);

  final int number;
  final String label;
  final double p;

  @override
  Widget build(BuildContext context) {
    final fg = Color.lerp(filmPaper, Colors.white, p)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 6, 9, 6),
      decoration: BoxDecoration(
        color: Color.lerp(const Color(0x0AFFFFFF), filmRed, p),
        border:
            Border.all(color: Color.lerp(const Color(0x44FFFFFF), filmRed, p)!),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 15,
            height: 15,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0x22FFFFFF),
              shape: BoxShape.circle,
            ),
            child: Text('$number',
                style: filmText(8, weight: FontWeight.w700, color: fg)),
          ),
          const SizedBox(width: 5),
          Text(label, style: filmText(8, color: fg)),
        ],
      ),
    );
  }
}

/// The phone: pick a cylinder, confirm the address, press order.
class _Device extends StatelessWidget {
  const _Device(this.t, {required this.reducedMotion});

  final double t;
  final bool reducedMotion;

  static const _frame = Color(0xFF1F282F);
  static const _soft = Color(0xFFF4F1E8);

  @override
  Widget build(BuildContext context) {
    // button-press: 0 → 40 % presses down, 40 → 100 % releases.
    final press = (t - 2300) / 800;
    final down = press <= 0 || press >= 1
        ? 0.0
        : press < .4
            ? Curves.ease.transform(press / .4)
            : 1 - Curves.ease.transform((press - .4) / .6);
    // tap: a ring that grows from the finger and fades.
    final tap = ((t - 2350) / 700).clamp(0.0, 1.0);
    final ringOpacity = tap <= 0 || tap >= 1
        ? 0.0
        : tap < .3
            ? filmEase.transform(tap / .3)
            : 1 - filmEase.transform((tap - .3) / .7);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _frame,
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(
              color: Color(0x3620324B), offset: Offset(10, 15), blurRadius: 30),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: const Color(0xFF5C6268), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: ColoredBox(
          color: const Color(0xFFFFFDF8),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 20, 14, 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(5, 1, 5, 12),
                        child: Row(
                          children: [
                            Text('9:41',
                                style: filmText(6,
                                    color: const Color(0xFF203449))),
                            const Spacer(),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFF203449),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Container(
                              width: 6,
                              height: 3,
                              decoration: BoxDecoration(
                                color: const Color(0xFF203449),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const FilmGlyph.flame(size: 21),
                          const SizedBox(width: 3),
                          Flexible(
                            child: _OneLine('GAZ & ENERGIYA',
                                style: filmText(7.5,
                                    weight: FontWeight.w700, spacing: .1)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const FilmGlyph.pin(size: 10),
                          const SizedBox(width: 3),
                          Expanded(
                            child: _OneLine('Uyga yetkazish',
                                style: filmText(7,
                                    color: const Color(0xFF79847B))),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 10, color: Color(0xFF79847B)),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 15),
                        child: Text('Ballonni\ntanlang',
                            style: filmText(23,
                                weight: FontWeight.w700,
                                height: 25 / 23,
                                spacing: -.5)),
                      ),
                      // The one block that may give a few pixels if a
                      // platform font sets taller lines than Roboto.
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 113),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _MiniProduct(
                                  small: true,
                                  chosen: _at(t, 600, 400, Curves.ease),
                                  badge: _at(t, 800, 350),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(child: _MiniProduct()),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _In(
                        _at(t, 1400, 500),
                        dy: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 9),
                          decoration: BoxDecoration(
                            color: _soft,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            children: [
                              const FilmGlyph.pin(size: 16),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _OneLine('Yetkazish manzili',
                                        style: filmText(5.5,
                                            color: const Color(0xFF8C99A9))),
                                    const SizedBox(height: 3),
                                    _OneLine('Mening uyim',
                                        style: filmText(8,
                                            weight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                              const FilmGlyph.check(size: 11, color: filmGreen),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Transform.scale(
                        scale: 1 - .03 * down,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 11, vertical: 12),
                              decoration: BoxDecoration(
                                color: Color.lerp(
                                    filmRed, const Color(0xFFBD2B1C), down),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _OneLine('Buyurtma berish',
                                        style: filmText(8,
                                            weight: FontWeight.w500,
                                            color: Colors.white)),
                                  ),
                                  const FilmGlyph.arrow(
                                      size: 12, color: Colors.white),
                                ],
                              ),
                            ),
                            if (ringOpacity > 0)
                              Positioned(
                                right: 30,
                                top: 9,
                                child: Opacity(
                                  opacity: ringOpacity,
                                  child: Transform.scale(
                                    scale: .6 + 2.4 * filmEase.transform(tap),
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: const Color(0x44FFFFFF),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 66,
                  height: 17,
                  decoration: const BoxDecoration(
                    color: _frame,
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(10)),
                  ),
                ),
              ),
              const _HomeBar(),
              if (!reducedMotion)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 64,
                  bottom: 19,
                  child: _In(
                    _at(t, 3000, 550),
                    dy: 24,
                    child: const _OrderConfirmed(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeBar extends StatelessWidget {
  const _HomeBar();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 7,
      child: Center(
        child: Container(
          width: 69,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFF152B40),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

class _MiniProduct extends StatelessWidget {
  const _MiniProduct({this.small = false, this.chosen = 0, this.badge = 0});

  final bool small;

  /// Progress of the selection highlight and of the check badge.
  final double chosen;
  final double badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(2, 15, 2, 10),
      decoration: BoxDecoration(
        color: Color.lerp(_Device._soft, const Color(0xFFFFF0E6), chosen),
        border: Border.all(
          color: Color.lerp(const Color(0xFFDADFD5), filmRed, chosen)!,
        ),
        borderRadius: BorderRadius.circular(12),
        // The second pixel of the selected outline sits outside the box,
        // like CSS `box-shadow: 0 0 0 1px`, so the content never shifts.
        boxShadow: [
          BoxShadow(color: filmRed.withValues(alpha: chosen), spreadRadius: 1),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: small ? 15 : 0),
                  FilmCylinder(bodyHeight: small ? 46 : 61),
                  const SizedBox(height: 14),
                  Text(small ? 'Kichik ballon' : 'Katta ballon',
                      maxLines: 1,
                      softWrap: false,
                      style: filmText(7.5, weight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          if (small)
            Positioned(
              right: 4,
              top: -7,
              child: _In(
                badge,
                scale: .6,
                child: Container(
                  width: 13,
                  height: 13,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: filmRed,
                    shape: BoxShape.circle,
                  ),
                  child: const FilmGlyph.check(
                      size: 9, color: Colors.white, weight: 3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderConfirmed extends StatelessWidget {
  const _OrderConfirmed();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xF7FFFDF8),
      padding: const EdgeInsets.only(top: 47),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFE2EFDD),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0xFFEFF6EB), spreadRadius: 7)],
            ),
            child: const FilmGlyph.check(size: 28, color: filmGreen),
          ),
          const SizedBox(height: 24),
          Text('Buyurtma\nqabul qilindi!',
              textAlign: TextAlign.center,
              style: filmText(20,
                  weight: FontWeight.w700, height: 23 / 20, spacing: -.5)),
          const SizedBox(height: 8),
          Text('Gaz balloni uyingizgacha',
              style: filmText(8, color: const Color(0xFF8490A0))),
          const SizedBox(height: 23),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2E5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: _OneLine('Buyurtmangiz tayyorlanmoqda',
                      style: filmText(6, color: filmGreen)),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFF20A666),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 04 · 0:12–0:16.5 — gas on the road ──────────────────────────────────

class _RoadScene extends StatelessWidget {
  const _RoadScene(this.t);

  final double t;

  /// truck-travel: 0 % −350 → 30 % 25 → 70 % 30 → 100 % 47 px.
  double get _truckX {
    final p = (t / 4500).clamp(0.0, 1.0);
    if (p < .3) return _lerp(-350, 25, filmEase.transform(p / .3));
    if (p < .7) return _lerp(25, 30, filmEase.transform((p - .3) / .4));
    return _lerp(30, 47, filmEase.transform((p - .7) / .3));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _serial('04 / YO‘LDA', t),
        _headline(t,
            top: 115,
            first: 'GAZ',
            accent: 'YO‘LDA.',
            size: 74,
            height: .9,
            spacing: -4),
        Positioned(
          left: 18,
          right: 18,
          top: 338,
          height: 245,
          child: _StreetWindow(shift: -300 * (t / 4500).clamp(0.0, 1.0)),
        ),
        Positioned(
          right: 26,
          top: 291,
          child: _In(
            _at(t, 250, 550),
            dx: 25,
            turn: -18,
            turnTo: -7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: filmInk,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('UYINGIZGACHA',
                      style: filmText(10,
                          weight: FontWeight.w700,
                          color: filmPaper,
                          spacing: 1)),
                  const SizedBox(width: 10),
                  const FilmGlyph.arrow(size: 23, color: filmRed),
                ],
              ),
            ),
          ),
        ),
        Positioned(left: 14, top: 411, child: _SpeedLines(t)),
        Positioned(
          left: 0,
          top: 397,
          width: 350,
          height: 175,
          child: Transform.translate(
            offset: Offset(_truckX, 0),
            child: _Truck(t),
          ),
        ),
        Positioned(
          left: 26,
          right: 26,
          top: 602,
          child: _In(
            _at(t, 500, 500),
            dy: 13,
            child: _Route(fill: ((t - 400) / 4000).clamp(0.0, 1.0)),
          ),
        ),
        _footer('TELEFONDAN ESHIKKACHA.'),
      ],
    );
  }
}

class _StreetWindow extends StatelessWidget {
  const _StreetWindow({required this.shift});

  final double shift;

  static const _radius = BorderRadius.vertical(
    top: Radius.circular(140),
    bottom: Radius.circular(16),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(borderRadius: _radius),
      foregroundDecoration: BoxDecoration(
        borderRadius: _radius,
        border: Border.all(color: const Color(0xD917221B), width: 1.5),
      ),
      child: Stack(
        children: [
          Positioned(
            left: shift,
            top: 0,
            width: 720,
            height: 245,
            child: _image(
              'street.jpg',
              alignment: const Alignment(0, .3),
              opacity: const AlwaysStoppedAnimation(.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedLines extends StatelessWidget {
  const _SpeedLines(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    const widths = [31.0, 44.0, 20.0];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 3; i++)
          Builder(builder: (context) {
            final local = t - i * 100;
            final q = local < 0 ? 0.0 : (local % 700) / 700;
            final opacity = local < 0
                ? 0.0
                : q < .4
                    ? Curves.ease.transform(q / .4)
                    : 1 - Curves.ease.transform((q - .4) / .6);
            return Padding(
              padding: const EdgeInsets.only(top: 17),
              child: Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(_lerp(8, -11, Curves.ease.transform(q)), 0),
                  child: Container(
                    width: widths[i],
                    height: 3,
                    decoration: BoxDecoration(
                      color: filmRed,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _Truck extends StatelessWidget {
  const _Truck(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    final bounce = (t % 260) / 260;
    final lift = -.6 * (bounce < .5 ? bounce * 2 : (1 - bounce) * 2);
    final turns = (t % 500) / 500;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 25,
          bottom: 15,
          width: 292,
          height: 11,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: const DecoratedBox(
              decoration: ShapeDecoration(
                color: Color(0x3317221B),
                shape: OvalBorder(),
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(0, lift),
          child: SizedBox(
            width: 350,
            height: 175,
            child: Stack(
              children: [
                _image('truck.webp',
                    fit: BoxFit.contain, alignment: Alignment.topLeft),
                Positioned(left: 74, top: 126, child: FilmWheel(turns: turns)),
                Positioned(left: 268, top: 126, child: FilmWheel(turns: turns)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Route extends StatelessWidget {
  const _Route({required this.fill});

  final double fill;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: _OneLine('Gaz ombori', style: filmText(10, spacing: -.1)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: FilmGlyph.arrow(size: 26, color: filmRed, weight: 2.4),
            ),
            Flexible(
              child: _OneLine('Sizning uyingiz',
                  alignment: Alignment.centerRight,
                  style: filmText(10, weight: FontWeight.w700, spacing: -.1)),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 9, bottom: 12),
          child: Container(
            height: 3,
            color: const Color(0x2017221B),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fill,
              heightFactor: 1,
              child: const ColoredBox(color: filmRed),
            ),
          ),
        ),
        Text('GAZ MASHINASIDA YETKAZISH',
            style: filmText(6, weight: FontWeight.w700, spacing: 1.4)),
      ],
    );
  }
}

// ── 05 · 0:16.5–0:21 — delivered ────────────────────────────────────────

class _DeliveryScene extends StatelessWidget {
  const _DeliveryScene(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _serial('05 / YETKAZILDI', t),
        Positioned(
          left: 25,
          right: 25,
          top: 214,
          height: 412,
          child: _In(
            _at(t, 150, 650),
            dy: 35,
            turn: -3,
            child: _Photo(
              'delivery.jpg',
              radius: BorderRadius.circular(28),
              alignment: const Alignment(0, -.2),
            ),
          ),
        ),
        Positioned(
          left: 26,
          right: 26,
          top: 681,
          child: _In(
            _at(t, 1550, 500),
            dy: 13,
            child: Text('“Rahmat, qo‘shni!”',
                textAlign: TextAlign.center,
                style: filmText(13, weight: FontWeight.w700, spacing: -.3)),
          ),
        ),
        _headline(t,
            top: 112,
            first: 'GAZ KELDI.',
            accent: 'KO‘NGIL JOYIGA.',
            size: 34,
            height: 1.1,
            spacing: -1.4),
        Positioned(
          right: 16,
          top: 200,
          child: _In(
            _at(t, 550, 700),
            scale: .5,
            turn: -60,
            turnTo: 12,
            child: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: filmRed,
                shape: BoxShape.circle,
                border: Border.all(color: filmPaper, width: 5),
              ),
              child: const FilmGlyph.check(size: 34, color: Colors.white),
            ),
          ),
        ),
        Positioned(
          left: 21,
          right: 41,
          top: 612,
          child: _In(
            _at(t, 750, 600),
            dy: 24,
            child: _Toast(
              radius: 15,
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BUYURTMANGIZ',
                            style: filmText(6,
                                color: const Color(0xFF7D8578), spacing: 1.4)),
                        const SizedBox(height: 4),
                        Text('Yetkazib berildi!',
                            style: filmText(17,
                                weight: FontWeight.w700, spacing: -.5)),
                      ],
                    ),
                  ),
                  const FilmGlyph.check(size: 25, color: filmGreen),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 06 · 0:21–0:25 — call to action ─────────────────────────────────────

class _FinaleScene extends StatelessWidget {
  const _FinaleScene(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: FilmBurstPainter(
              center: const Offset(112, 436),
              turn: _lerp(-20, 15, _at(t, 0, 4000, Curves.ease)),
            ),
          ),
        ),
        _serial('GAZ & ENERGIYA', t, color: const Color(0xFFADB4A5)),
        Positioned(
          left: 24,
          top: 517,
          child: RotatedBox(
            quarterTurns: 3,
            child: Text('GAZ BALLONI\nBUYURTMASI',
                style: filmText(6,
                    color: const Color(0xFFD9DFD1), height: 2, spacing: 1)),
          ),
        ),
        _headline(t,
            top: 118,
            first: 'OSON',
            accent: 'BUYURTMA.',
            size: 53,
            height: .97,
            spacing: -2.4,
            color: filmPaper,
            below: Padding(
              padding: const EdgeInsets.only(top: 17),
              child: Text('Gazingiz. Uyingizgacha.',
                  style: filmText(13,
                      color: const Color(0xFFB8C0AF), spacing: -.1)),
            )),
        Positioned(
          left: 233,
          top: 333,
          width: 135,
          height: 237,
          child: _In(
            _at(t, 150, 800),
            dy: 50,
            turn: 19,
            turnTo: 8,
            child: const _EndPhone(),
          ),
        ),
        Positioned(
          left: 80,
          top: 349,
          width: 140,
          height: 230,
          child: _In(
            _at(t, 200, 800),
            dy: 45,
            turn: -14,
            turnTo: -6,
            child: const Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: 20,
                  child: FilmCylinder(scale: 3.5, shadow: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EndPhone extends StatelessWidget {
  const _EndPhone();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF3C4438),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(color: Color(0x55000000), offset: Offset(4, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: ColoredBox(
          color: filmPaper,
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(7, 27, 7, 16),
                  child: Column(
                    children: [
                      const FilmGlyph.flame(size: 22),
                      const SizedBox(height: 4),
                      _OneLine('GAZ & ENERGIYA',
                          alignment: Alignment.center,
                          style: filmText(6,
                              weight: FontWeight.w700, spacing: .2)),
                      const SizedBox(height: 17),
                      Container(
                        width: 37,
                        height: 37,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE2EEDB),
                          shape: BoxShape.circle,
                        ),
                        child:
                            const FilmGlyph.check(size: 23, color: filmGreen),
                      ),
                      const SizedBox(height: 11),
                      _OneLine('Gaz keldi!',
                          alignment: Alignment.center,
                          style: filmText(18,
                              weight: FontWeight.w700,
                              height: 22 / 18,
                              spacing: -.8)),
                      const SizedBox(height: 7),
                      _OneLine('Buyurtmangiz yetkazildi',
                          alignment: Alignment.center,
                          style: filmText(5.5, color: const Color(0xFF788472))),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('ILOVA', style: filmText(6, spacing: .3)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: FilmGlyph.arrow(
                                size: 9, color: filmRed, weight: 2.6),
                          ),
                          Text('UYINGIZ', style: filmText(6, spacing: .3)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 66,
                  height: 17,
                  decoration: const BoxDecoration(
                    color: _Device._frame,
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(10)),
                  ),
                ),
              ),
              const _HomeBar(),
            ],
          ),
        ),
      ),
    );
  }
}

