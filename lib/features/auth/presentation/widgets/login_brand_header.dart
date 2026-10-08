import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';

/// Top of the sign-in screen: the Alanga logo, large, on a warm cream
/// backdrop. The bottom edge is a thin blue wave, below which the page
/// colour takes over so the form reads as one surface with the page.
///
/// It has no height of its own: it fills what the page gives it (the
/// space the form leaves), so the whole screen fits without scrolling.
class LoginBrandHeader extends StatelessWidget {
  const LoginBrandHeader({super.key});

  static const logoAsset = 'assets/images/alanga_logo.png';

  /// Smallest useful header; below this the page scrolls instead.
  static const minHeight = 104.0;

  /// On tall screens the backdrop keeps growing but the logo stops here.
  static const _maxLogoHeight = 280.0;

  @override
  Widget build(BuildContext context) {
    // Positioned children don't count towards a Stack's intrinsic height,
    // so the page's IntrinsicHeight sees exactly [minHeight] here, while
    // the real header fills whatever height it is finally given.
    return Stack(
      children: [
        const SizedBox(height: minHeight, width: double.infinity),
        Positioned.fill(
          child: CustomPaint(
            painter: _BackdropPainter(
              pageColor: Theme.of(context).scaffoldBackgroundColor,
              lineColor: context.palette.primary,
            ),
            child: Padding(
              // Bottom inset clears the wave.
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 26),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: _maxLogoHeight),
                  child: Image.asset(
                    logoAsset,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    semanticLabel: 'Alanga',
                    frameBuilder: (context, child, frame, sync) => sync
                        ? child
                        : AnimatedOpacity(
                            opacity: frame == null ? 0 : 1,
                            duration: const Duration(milliseconds: 240),
                            child: child,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter({required this.pageColor, required this.lineColor});

  final Color pageColor;
  final Color lineColor;

  static const _top = Color(0xFFFFF7EE);
  static const _bottom = Color(0xFFFCE8D5);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final rect = Offset.zero & size;
    // The glow's circle reaches past the header; without this it smudges
    // the page below the wave (visible in dark mode).
    canvas.clipRect(rect);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_top, _bottom],
        ).createShader(rect),
    );

    // Soft light behind the logo so it lifts off the cream.
    final glowCenter = Offset(w / 2, h * 0.47);
    final glowRadius = math.min(w, h) * 0.62;
    canvas.drawCircle(
      glowCenter,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.85),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius)),
    );

    _paintWave(canvas, w, h);
  }

  void _paintWave(Canvas canvas, double w, double h) {
    final baseline = h - 9;
    const amplitude = 3.5;
    const wavelength = 130.0;
    double yAt(double x) =>
        baseline + amplitude * math.sin(x / wavelength * 2 * math.pi + 0.6);

    final line = Path()..moveTo(0, yAt(0));
    for (var x = 4.0; x <= w + 4; x += 4) {
      line.lineTo(x, yAt(x));
    }
    final below = Path.from(line)
      ..lineTo(w + 4, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(below, Paint()..color = pageColor);
    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) =>
      oldDelegate.pageColor != pageColor || oldDelegate.lineColor != lineColor;
}
