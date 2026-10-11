import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';

/// Top of the sign-in screen: the Alanga logo, large, on a warm cream
/// backdrop. The bottom edge is a thin blue wave, below which the page
/// colour takes over so the form reads as one surface with the page.
///
/// It has no height of its own: it fills what the page gives it (the
/// space the form leaves), so the whole screen fits without scrolling.
/// The backdrop runs up under the status bar / notch — the page leaves
/// the top safe area to it, and it keeps the logo below that inset.
class LoginBrandHeader extends StatelessWidget {
  const LoginBrandHeader({super.key});

  static const logoAsset = 'assets/images/alanga_logo.png';

  /// Smallest useful header (below the status bar); below this the page
  /// scrolls instead.
  static const minHeight = 104.0;

  /// On tall screens the backdrop keeps growing but the logo stops here.
  static const _maxLogoHeight = 280.0;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final topInset = MediaQuery.paddingOf(context).top;
    final still = MediaQuery.disableAnimationsOf(context);

    // Positioned children don't count towards a Stack's intrinsic height,
    // so the page's IntrinsicHeight sees exactly [minHeight] here, while
    // the real header fills whatever height it is finally given.
    return Stack(
      children: [
        SizedBox(height: minHeight + topInset, width: double.infinity),
        Positioned.fill(
          child: CustomPaint(
            painter: _BackdropPainter(
              pageColor: Theme.of(context).scaffoldBackgroundColor,
              lineColor: c.primary,
              dark: c.isDark,
            ),
            child: Padding(
              // Bottom inset clears the wave.
              padding: EdgeInsets.fromLTRB(24, 16 + topInset, 24, 30),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: _maxLogoHeight),
                  // The logo settles in once, with the page: a short rise
                  // from slightly smaller. Reduced motion shows it still.
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: still ? 1 : 0, end: 1),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, child) => Transform.scale(
                      scale: .92 + .08 * t,
                      child: Opacity(opacity: t, child: child),
                    ),
                    child: Image.asset(
                      logoAsset,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      semanticLabel: 'Alanga',
                      // Not decoded yet on the first frame: fade it in when
                      // it arrives instead of popping.
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
        ),
      ],
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter({
    required this.pageColor,
    required this.lineColor,
    required this.dark,
  });

  final Color pageColor;
  final Color lineColor;

  /// In dark mode the cream is toned down a step, so the header still
  /// carries the logo but no longer glares next to the dark form.
  final bool dark;

  static const _top = Color(0xFFFFF7EE);
  static const _bottom = Color(0xFFFCE8D5);
  static const _topDim = Color(0xFFF1E4D3);
  static const _bottomDim = Color(0xFFE6CDB2);

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
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark ? const [_topDim, _bottomDim] : const [_top, _bottom],
        ).createShader(rect),
    );

    // Soft light behind the logo so it lifts off the cream.
    final glowCenter = Offset(w / 2, h * 0.5);
    final glowRadius = math.min(w, h) * 0.62;
    canvas.drawCircle(
      glowCenter,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: dark ? 0.6 : 0.85),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius)),
    );

    _paintWave(canvas, w, h);
  }

  void _paintWave(Canvas canvas, double w, double h) {
    final baseline = h - 10;
    const amplitude = 4.0;
    const wavelength = 130.0;
    double yAt(double x) =>
        baseline + amplitude * math.sin(x / wavelength * 2 * math.pi + 0.6);

    final line = Path()..moveTo(-4, yAt(-4));
    for (var x = 0.0; x <= w + 4; x += 4) {
      line.lineTo(x, yAt(x));
    }
    final below = Path.from(line)
      ..lineTo(w + 4, h + 20)
      ..lineTo(-4, h + 20)
      ..close();

    // A soft shade on the cream just above the wave: the form side reads
    // as a sheet lying over the header rather than a flat colour change.
    canvas.drawPath(
      below.shift(const Offset(0, -3)),
      Paint()
        ..color = const Color(0xFF7A4A1E).withValues(alpha: dark ? .30 : .16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
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
      oldDelegate.pageColor != pageColor ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.dark != dark;
}
