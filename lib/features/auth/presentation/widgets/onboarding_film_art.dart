import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Brand palette of the Gaz & Energiya creative. The film keeps it in both
/// app themes — it is artwork, like a poster, not themed UI.
const filmRed = Color(0xFFEE442C);
const filmPaper = Color(0xFFF5F1E8);
const filmInk = Color(0xFF17221B);
const filmGreen = Color(0xFF2E774B);

/// The creative's `--ease` curve: `cubic-bezier(.19, .85, .2, 1)`.
const filmEase = Cubic(.19, .85, .2, 1);

TextStyle filmText(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color? color,
  double? height,
  double spacing = 0,
}) {
  return TextStyle(
    fontFamily: 'Roboto',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: spacing,
    decoration: TextDecoration.none,
  );
}

enum _Glyph { flame, check, arrow, pin }

/// The creative's SVG symbols (flame, check, arrow, pin), drawn from the
/// same path data so they match it exactly at any scale.
class FilmGlyph extends StatelessWidget {
  const FilmGlyph.flame({super.key, required this.size})
      : _glyph = _Glyph.flame,
        color = filmRed,
        weight = 0;

  const FilmGlyph.check({
    super.key,
    required this.size,
    required this.color,
    this.weight = 2.5,
  }) : _glyph = _Glyph.check;

  /// A right-pointing arrow; rotate it for other directions.
  const FilmGlyph.arrow({
    super.key,
    required this.size,
    required this.color,
    this.weight = 1.8,
  }) : _glyph = _Glyph.arrow;

  const FilmGlyph.pin({super.key, required this.size, this.color = filmRed})
      : _glyph = _Glyph.pin,
        weight = 1.8;

  final _Glyph _glyph;
  final double size;
  final Color color;

  /// Stroke width in the symbol's own 24-unit viewBox, like SVG.
  final double weight;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GlyphPainter(_glyph, color, weight)),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.glyph, this.color, this.weight);

  final _Glyph glyph;
  final Color color;
  final double weight;

  @override
  void paint(Canvas canvas, Size size) {
    final box = glyph == _Glyph.flame ? 32.0 : 24.0;
    canvas.scale(size.width / box, size.height / box);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = weight
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (glyph) {
      case _Glyph.check:
        canvas.drawPath(
          Path()
            ..moveTo(5, 12)
            ..lineTo(9, 16)
            ..lineTo(19, 6),
          stroke,
        );
      case _Glyph.arrow:
        canvas.drawPath(
          Path()
            ..moveTo(4, 12)
            ..lineTo(19, 12)
            ..moveTo(13, 6)
            ..lineTo(19, 12)
            ..lineTo(13, 18),
          stroke,
        );
      case _Glyph.pin:
        canvas.drawPath(
          Path()
            ..moveTo(18, 10)
            ..cubicTo(18, 15, 12, 20, 12, 20)
            ..cubicTo(12, 20, 6, 15, 6, 10)
            ..arcToPoint(const Offset(18, 10),
                radius: const Radius.circular(6), largeArc: true)
            ..close(),
          stroke,
        );
        canvas.drawCircle(const Offset(12, 10), 2, Paint()..color = color);
      case _Glyph.flame:
        canvas.drawPath(
          Path()
            ..moveTo(17, 2)
            ..cubicTo(19, 9, 8, 10, 9, 18)
            ..cubicTo(9, 22, 12, 26, 16, 26)
            ..cubicTo(21, 26, 25, 22, 25, 17)
            ..cubicTo(25, 14, 24, 12, 22, 10)
            ..cubicTo(22, 14, 20, 15, 19, 15)
            ..cubicTo(20, 9, 19, 6, 17, 2)
            ..close(),
          Paint()..color = filmRed,
        );
        canvas.drawPath(
          Path()
            ..moveTo(16, 17)
            ..cubicTo(14, 20, 12, 21, 13, 24)
            ..cubicTo(14, 27, 19, 27, 20, 23)
            ..cubicTo(20, 21, 18, 20, 18, 17)
            ..cubicTo(18, 19, 17, 20, 16, 21)
            ..close(),
          Paint()..color = Colors.white,
        );
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph || old.color != color || old.weight != weight;
}

/// The red starburst stamp ("YECHIM BOR.").
class FilmStamp extends StatelessWidget {
  const FilmStamp({super.key, required this.label, this.size = 97});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: const _StampPainter(),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: filmText(10,
                weight: FontWeight.w700,
                color: filmPaper,
                height: 1.3,
                spacing: .6),
          ),
        ),
      ),
    );
  }
}

class _StampPainter extends CustomPainter {
  const _StampPainter();

  static const _points = [
    50, 0, 57, 32, 79, 10, 67, 40, 100, 39, 72, 53, 92, 77, 62, 67, 64, 100, //
    49, 72, 25, 94, 34, 63, 0, 67, 27, 49, 7, 23, 38, 33,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    final path = Path()..moveTo(50, 0);
    for (var i = 2; i < _points.length; i += 2) {
      path.lineTo(_points[i].toDouble(), _points[i + 1].toDouble());
    }
    canvas.drawPath(path..close(), Paint()..color = filmRed);
  }

  @override
  bool shouldRepaint(_StampPainter old) => false;
}

/// The creative's CSS gas cylinder (39 px wide), with handle, brass valve,
/// seam and foot. [bodyHeight] 46 is the small cylinder, 61 the large one.
class FilmCylinder extends StatelessWidget {
  const FilmCylinder({
    super.key,
    this.bodyHeight = 61,
    this.scale = 1,
    this.shadow = false,
  });

  final double bodyHeight;
  final double scale;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 39 * scale,
      height: bodyHeight * scale,
      child: CustomPaint(
        painter: _CylinderPainter(bodyHeight, scale, shadow),
      ),
    );
  }
}

class _CylinderPainter extends CustomPainter {
  const _CylinderPainter(this.bodyHeight, this.scale, this.shadow);

  final double bodyHeight;
  final double scale;
  final bool shadow;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(scale);
    final h = bodyHeight;
    final bodyRect = Rect.fromLTWH(0, 0, 39, h);
    final body = RRect.fromRectAndCorners(
      bodyRect,
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: const Radius.circular(7),
      bottomRight: const Radius.circular(7),
    );
    if (shadow) {
      // drop-shadow(5px 8px 4px #17221b44)
      canvas.drawRRect(
        body.shift(const Offset(5, 8)),
        Paint()
          ..color = const Color(0x4417221B)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFA92927),
            Color(0xFFD74339),
            Color(0xFFEF6A54),
            Color(0xFFE45542),
            Color(0xFFB4332A),
          ],
          stops: [0, .13, .40, .63, .95],
        ).createShader(bodyRect),
    );
    // Handle: a 24 × 13 frame with a 4 px border, 9 px above the body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(10, -7, 20, 9), const Radius.circular(2)),
      Paint()
        ..color = const Color(0xFFB83730)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    const valve = Rect.fromLTWH(17, -5, 5, 7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(valve, const Radius.circular(1)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF8A642D), Color(0xFFCFAA52), Color(0xFF967337)],
        ).createShader(valve),
    );
    canvas.drawRect(const Rect.fromLTWH(0, 19, 39, 1),
        Paint()..color = const Color(0x4DFF9178));
    canvas.drawRect(const Rect.fromLTWH(0, 20, 39, 2),
        Paint()..color = const Color(0x3DBC3729));
    final foot = Rect.fromLTWH(3, h - 2, 33, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(foot, const Radius.circular(2)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF98241E), Color(0xFFCC3E2C), Color(0xFF932621)],
        ).createShader(foot),
    );
  }

  @override
  bool shouldRepaint(_CylinderPainter old) =>
      old.bodyHeight != bodyHeight ||
      old.scale != scale ||
      old.shadow != shadow;
}

/// The big red "✳" behind the final cylinder: eight bars from one centre.
class FilmBurstPainter extends CustomPainter {
  const FilmBurstPainter({required this.center, required this.turn});

  final Offset center;

  /// Rotation in degrees.
  final double turn;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = filmRed
      ..strokeWidth = 15;
    for (var i = 0; i < 8; i++) {
      final a = (turn + i * 45 - 90) * math.pi / 180;
      canvas.drawLine(
          center, center + Offset(math.cos(a), math.sin(a)) * 134, paint);
    }
  }

  @override
  bool shouldRepaint(FilmBurstPainter old) =>
      old.turn != turn || old.center != center;
}

/// Spokes laid over the truck photo's hubs, so the wheels visibly turn.
class FilmWheel extends StatelessWidget {
  const FilmWheel({super.key, required this.turns});

  final double turns;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 25,
      child: CustomPaint(painter: _WheelPainter(turns)),
    );
  }
}

class _WheelPainter extends CustomPainter {
  const _WheelPainter(this.turns);

  final double turns;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..color = const Color(0xA87B888B)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final a = (turns + i / 8) * 2 * math.pi;
      final d = Offset(math.cos(a), math.sin(a)) * 8.5;
      canvas.drawLine(c - d, c + d, paint);
    }
  }

  @override
  bool shouldRepaint(_WheelPainter old) => old.turns != turns;
}

/// The three chapter bars at the top of the film.
class FilmProgressPainter extends CustomPainter {
  const FilmProgressPainter({required this.fills, required this.track});

  final List<double> fills;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 5.0;
    final w = (size.width - gap * (fills.length - 1)) / fills.length;
    final r = Radius.circular(size.height);
    for (var i = 0; i < fills.length; i++) {
      final x = i * (w + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, 0, w, size.height), r),
        Paint()..color = track,
      );
      if (fills[i] > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, 0, w * fills[i], size.height), r),
          Paint()..color = filmRed,
        );
      }
    }
  }

  @override
  bool shouldRepaint(FilmProgressPainter old) =>
      old.track != track || !_same(old.fills, fills);

  static bool _same(List<double> a, List<double> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
