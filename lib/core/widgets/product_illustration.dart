import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

/// The visual identity of each energy product. Drawn with a painter
/// instead of stock icons so cards look like a real commercial catalogue
/// even before photography exists.
enum EnergyVisual { cylinder, propane, methane, liquid, electric, petrol, diesel, market }

extension EnergyVisualX on EnergyVisual {
  /// Maps a mock category id / product name onto a visual.
  static EnergyVisual fromCategory(String categoryId, {String name = ''}) {
    final key = '$categoryId $name'.toLowerCase();
    if (key.contains('elektr') || key.contains('electric')) return EnergyVisual.electric;
    if (key.contains('benzin') || key.contains('petrol')) return EnergyVisual.petrol;
    if (key.contains('dizel') || key.contains('diesel')) return EnergyVisual.diesel;
    if (key.contains('market')) return EnergyVisual.market;
    if (key.contains('metan')) return EnergyVisual.methane;
    if (key.contains('propan')) return EnergyVisual.propane;
    if (key.contains('suyultirilgan') || key.contains('liquid')) return EnergyVisual.liquid;
    return EnergyVisual.cylinder;
  }

  Color get accent => switch (this) {
        EnergyVisual.cylinder => AppColors.primary,
        EnergyVisual.propane => AppColors.energyFlame,
        EnergyVisual.methane => AppColors.energyMint,
        EnergyVisual.liquid => AppColors.energyRose,
        EnergyVisual.electric => AppColors.energyElectric,
        EnergyVisual.petrol => AppColors.energyAmber,
        EnergyVisual.diesel => AppColors.energySlate,
        EnergyVisual.market => AppColors.info,
      };

  Color get accentDark => Color.lerp(accent, Colors.black, 0.34)!;

  IconData get icon => switch (this) {
        EnergyVisual.cylinder ||
        EnergyVisual.propane ||
        EnergyVisual.methane ||
        EnergyVisual.liquid =>
          Icons.propane_tank_rounded,
        EnergyVisual.electric => Icons.bolt_rounded,
        EnergyVisual.petrol => Icons.local_gas_station_rounded,
        EnergyVisual.diesel => Icons.local_shipping_rounded,
        EnergyVisual.market => Icons.storefront_rounded,
      };
}

/// Renders an energy product on a soft tinted stage.
class ProductIllustration extends StatelessWidget {
  const ProductIllustration({
    super.key,
    required this.visual,
    this.size,
    this.showStage = true,
    this.radius = 16,
  });

  final EnergyVisual visual;
  final double? size;
  final bool showStage;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final accent = visual.accent;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = size ??
            (constraints.hasBoundedHeight
                ? constraints.maxHeight
                : constraints.maxWidth);
        return DecoratedBox(
          decoration: showStage
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accent.withValues(alpha: c.isDark ? 0.20 : 0.11),
                      accent.withValues(alpha: c.isDark ? 0.07 : 0.03),
                    ],
                  ),
                )
              : const BoxDecoration(),
          child: Center(
            child: SizedBox(
              width: side * 0.72,
              height: side * 0.82,
              child: CustomPaint(
                painter: _EnergyPainter(visual: visual, isDark: c.isDark),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EnergyPainter extends CustomPainter {
  _EnergyPainter({required this.visual, required this.isDark});

  final EnergyVisual visual;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    switch (visual) {
      case EnergyVisual.cylinder:
      case EnergyVisual.propane:
      case EnergyVisual.methane:
      case EnergyVisual.liquid:
        _paintCylinder(canvas, size);
      case EnergyVisual.electric:
        _paintCharger(canvas, size);
      case EnergyVisual.petrol:
      case EnergyVisual.diesel:
        _paintPump(canvas, size);
      case EnergyVisual.market:
        _paintStore(canvas, size);
    }
  }

  Color get _accent => visual.accent;
  Color get _accentDeep => visual.accentDark;

  void _shadow(Canvas canvas, Size size) {
    final ellipse = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.965),
      width: size.width * 0.66,
      height: size.height * 0.06,
    );
    canvas.drawOval(
      ellipse,
      Paint()
        ..color = Colors.black.withValues(alpha: isDark ? 0.32 : 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  void _paintCylinder(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _shadow(canvas, size);

    final body = RRect.fromRectAndCorners(
      Rect.fromLTRB(w * 0.20, h * 0.24, w * 0.80, h * 0.94),
      topLeft: Radius.circular(w * 0.18),
      topRight: Radius.circular(w * 0.18),
      bottomLeft: Radius.circular(w * 0.09),
      bottomRight: Radius.circular(w * 0.09),
    );

    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(_accent, Colors.white, 0.22)!,
            _accent,
            _accentDeep,
          ],
          stops: const [0, 0.5, 1],
        ).createShader(body.outerRect),
    );

    // Neck + valve
    final neck = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.41, h * 0.12, w * 0.59, h * 0.27),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(neck, Paint()..color = _accentDeep);

    final valve = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.30, h * 0.05, w * 0.70, h * 0.13),
      Radius.circular(h * 0.03),
    );
    canvas.drawRRect(
      valve,
      Paint()..color = Color.lerp(_accentDeep, Colors.black, 0.15)!,
    );
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.09),
      w * 0.055,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );

    // Label band
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.20, h * 0.52, w * 0.80, h * 0.65),
        Radius.circular(w * 0.02),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );

    // Specular highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.29, h * 0.32, w * 0.36, h * 0.86),
        Radius.circular(w * 0.05),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.30),
    );

    // Base ring
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTRB(w * 0.20, h * 0.87, w * 0.80, h * 0.94),
        bottomLeft: Radius.circular(w * 0.09),
        bottomRight: Radius.circular(w * 0.09),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.16),
    );
  }

  void _paintCharger(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _shadow(canvas, size);

    final body = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.22, h * 0.10, w * 0.78, h * 0.94),
      Radius.circular(w * 0.16),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(_accent, Colors.white, 0.2)!, _accentDeep],
        ).createShader(body.outerRect),
    );

    // Screen
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.31, h * 0.20, w * 0.69, h * 0.46),
        Radius.circular(w * 0.07),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    // Bolt
    final bolt = Path()
      ..moveTo(w * 0.54, h * 0.23)
      ..lineTo(w * 0.40, h * 0.36)
      ..lineTo(w * 0.49, h * 0.36)
      ..lineTo(w * 0.46, h * 0.44)
      ..lineTo(w * 0.61, h * 0.30)
      ..lineTo(w * 0.51, h * 0.30)
      ..close();
    canvas.drawPath(bolt, Paint()..color = const Color(0xFFFFE27A));

    // Cable
    final cable = Path()
      ..moveTo(w * 0.78, h * 0.58)
      ..quadraticBezierTo(w * 1.02, h * 0.68, w * 0.86, h * 0.88);
    canvas.drawPath(
      cable,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.07
        ..strokeCap = StrokeCap.round
        ..color = _accentDeep,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.31, h * 0.56, w * 0.69, h * 0.64),
        Radius.circular(h * 0.02),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );
  }

  void _paintPump(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _shadow(canvas, size);

    final body = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.16, h * 0.16, w * 0.68, h * 0.94),
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(_accent, Colors.white, 0.22)!, _accentDeep],
        ).createShader(body.outerRect),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.24, h * 0.26, w * 0.60, h * 0.48),
        Radius.circular(w * 0.06),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.32),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.28, h * 0.32, w * 0.50, h * 0.37),
        Radius.circular(h * 0.02),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.28, h * 0.40, w * 0.44, h * 0.44),
        Radius.circular(h * 0.02),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );

    // Nozzle arm
    final arm = Path()
      ..moveTo(w * 0.68, h * 0.40)
      ..quadraticBezierTo(w * 0.94, h * 0.42, w * 0.90, h * 0.66)
      ..lineTo(w * 0.90, h * 0.80);
    canvas.drawPath(
      arm,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.06
        ..strokeCap = StrokeCap.round
        ..color = _accentDeep,
    );
    canvas.drawCircle(
      Offset(w * 0.90, h * 0.84),
      w * 0.07,
      Paint()..color = Color.lerp(_accent, Colors.white, 0.1)!,
    );
  }

  void _paintStore(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _shadow(canvas, size);

    // Building
    final body = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.12, h * 0.40, w * 0.88, h * 0.94),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(_accent, Colors.white, 0.2)!, _accentDeep],
        ).createShader(body.outerRect),
    );

    // Awning stripes
    for (int i = 0; i < 5; i++) {
      final left = w * (0.08 + i * 0.168);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(left, h * 0.24, left + w * 0.168, h * 0.42),
          Radius.circular(w * 0.03),
        ),
        Paint()
          ..color = i.isEven
              ? Colors.white.withValues(alpha: 0.92)
              : Color.lerp(_accent, Colors.black, 0.1)!,
      );
    }

    // Door
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTRB(w * 0.38, h * 0.62, w * 0.62, h * 0.94),
        topLeft: Radius.circular(w * 0.06),
        topRight: Radius.circular(w * 0.06),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );
  }

  @override
  bool shouldRepaint(covariant _EnergyPainter old) =>
      old.visual != visual || old.isDark != isDark;
}

/// Compact circular avatar version — used in cart rows, order items and
/// the tracking screen where a full illustration would be too heavy.
class EnergyAvatar extends StatelessWidget {
  const EnergyAvatar({super.key, required this.visual, this.size = 52});

  final EnergyVisual visual;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.tint(visual.accent, 0.12),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: ProductIllustration(
        visual: visual,
        showStage: false,
        size: size,
      ),
    );
  }
}
