import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/company_card.dart';
import '../../../../core/widgets/order_status_widget.dart';
import '../../../../core/widgets/product_illustration.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = [
    (
      title: 'Gaz va energiya — bir joyda',
      subtitle:
          'Gaz ballon, suyultirilgan gaz, metan, propan, benzin va elektr quvvatlash — '
          'hammasi bitta ilovada.',
    ),
    (
      title: 'Kompaniyalarni solishtiring',
      subtitle:
          'Narx, masofa, reyting va yetkazish muddatini bir ekranda ko‘rib, '
          'eng foydali taklifni tanlang.',
    ),
    (
      title: 'Buyurtmangizni kuzating',
      subtitle:
          'Yetkazib berish yoki o‘zingiz olib ketish — kuryer harakatini '
          'real vaqtda xaritada ko‘rasiz.',
    ),
  ];

  void _next() {
    if (_index == _slides.length - 1) {
      context.go('/login');
    } else {
      _controller.nextPage(duration: AppMotion.slow, curve: AppMotion.standard);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BackdropPainter(c.isDark))),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppDimensions.space12),
                    child: AppButton(
                      label: 'O‘tkazib yuborish',
                      variant: AppButtonVariant.text,
                      size: AppButtonSize.small,
                      expand: false,
                      onPressed: () => context.go('/login'),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final slide = _slides[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space28,
                        ),
                        child: Column(
                          children: [
                            const Spacer(),
                            SizedBox(height: 268, child: _SlideArt(index: i)),
                            const SizedBox(height: AppDimensions.space40),
                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: AppTypography.title1.copyWith(color: c.textPrimary),
                            ),
                            const SizedBox(height: AppDimensions.space12),
                            Text(
                              slide.subtitle,
                              textAlign: TextAlign.center,
                              style: AppTypography.callout.copyWith(
                                color: c.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            const Spacer(flex: 2),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: AppMotion.base,
                      curve: AppMotion.standard,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active ? c.primary : c.borderStrong,
                        borderRadius: AppDimensions.brPill,
                      ),
                    );
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.space24,
                    AppDimensions.space24,
                    AppDimensions.space24,
                    AppDimensions.space16,
                  ),
                  child: AppButton(
                    label: _index == _slides.length - 1 ? 'Boshlash' : 'Keyingi',
                    trailingIcon: Icons.arrow_forward_rounded,
                    onPressed: _next,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.space12),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Hisobingiz bormi?',
                        style: AppTypography.footnote.copyWith(color: c.textSecondary),
                      ),
                      AppButton(
                        label: 'Kirish',
                        variant: AppButtonVariant.text,
                        size: AppButtonSize.small,
                        expand: false,
                        onPressed: () => context.go('/login'),
                      ),
                    ],
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

/// Each slide previews a real screen built from the real design system —
/// far more convincing than a stock illustration.
class _SlideArt extends StatelessWidget {
  const _SlideArt({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return switch (index) {
      0 => const _ArtCatalog(),
      1 => const _ArtCompare(),
      _ => const _ArtTracking(),
    };
  }
}

class _ArtCatalog extends StatelessWidget {
  const _ArtCatalog();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 0,
          top: 30,
          child: Transform.rotate(
            angle: -0.12,
            child: const _MiniProduct(visual: EnergyVisual.propane, label: 'Propan', price: '62 000'),
          ),
        ),
        Positioned(
          right: 0,
          top: 46,
          child: Transform.rotate(
            angle: 0.12,
            child: const _MiniProduct(visual: EnergyVisual.electric, label: 'Elektr', price: '1 200'),
          ),
        ),
        const _MiniProduct(
          visual: EnergyVisual.cylinder,
          label: 'Gaz ballon 50L',
          price: '120 000',
          large: true,
        ),
      ],
    );
  }
}

class _MiniProduct extends StatelessWidget {
  const _MiniProduct({
    required this.visual,
    required this.label,
    required this.price,
    this.large = false,
  });

  final EnergyVisual visual;
  final String label;
  final String price;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppCard(
      width: large ? 156 : 118,
      elevation: large ? AppElevation.lg : AppElevation.md,
      padding: const EdgeInsets.all(AppDimensions.space10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: large ? 110 : 78,
            width: double.infinity,
            child: ProductIllustration(visual: visual, radius: AppDimensions.radiusSmall),
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: c.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "$price so'm",
            style: AppTypography.priceSmall.copyWith(
              color: c.primary,
              fontSize: large ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtCompare extends StatelessWidget {
  const _ArtCompare();

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _CompareRow(name: 'GazPlus', price: '125 000', meta: '1,8 km · 30 daq', best: true),
        const SizedBox(height: AppDimensions.space10),
        const _CompareRow(name: 'UzGaz Servis', price: '120 000', meta: '1,2 km · 35 daq'),
        const SizedBox(height: AppDimensions.space10),
        const _CompareRow(name: 'Mega Gaz', price: '118 000', meta: '2,4 km · 45 daq'),
        const SizedBox(height: AppDimensions.space16),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space12,
            vertical: AppDimensions.space6,
          ),
          decoration: BoxDecoration(
            color: c.successSoft,
            borderRadius: AppDimensions.brPill,
          ),
          child: Text(
            'Yetkazish bepul · 5 daqiqada tanlang',
            style: AppTypography.caption.copyWith(
              color: c.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.name,
    required this.price,
    required this.meta,
    this.best = false,
  });

  final String name;
  final String price;
  final String meta;
  final bool best;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppCard(
      selected: best,
      elevation: best ? AppElevation.md : AppElevation.sm,
      padding: const EdgeInsets.all(AppDimensions.space10),
      child: Row(
        children: [
          CompanyLogo(name: name, size: 34),
          const SizedBox(width: AppDimensions.space10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (best) ...[
                      const SizedBox(width: 5),
                      const AppPill(label: 'Top', tone: PillTone.success, dense: true),
                    ],
                  ],
                ),
                Text(
                  meta,
                  style: AppTypography.caption2.copyWith(color: c.textTertiary, fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: AppTypography.priceSmall.copyWith(color: c.textPrimary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ArtTracking extends StatelessWidget {
  const _ArtTracking();

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppCard(
          elevation: AppElevation.lg,
          padding: EdgeInsets.zero,
          clip: true,
          child: Column(
            children: [
              SizedBox(
                height: 122,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(painter: _RoutePainter(c.primary, c.border, c.surfaceMuted)),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: c.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: c.primary.withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.local_shipping_rounded,
                            color: Colors.white, size: 17),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppDimensions.space14),
                child: Row(
                  children: [
                    const LivePulse(),
                    const SizedBox(width: AppDimensions.space6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yo‘lda · 12 daqiqa qoldi',
                            style: AppTypography.caption.copyWith(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Doston A. · Damas 01 A 234 BC',
                            style: AppTypography.caption2.copyWith(color: c.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: c.successSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.call_rounded, size: 15, color: c.success),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter(this.line, this.grid, this.bg);

  final Color line;
  final Color grid;
  final Color bg;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = bg);
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 26) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.82)
      ..cubicTo(
        size.width * 0.32, size.height * 0.86,
        size.width * 0.34, size.height * 0.42,
        size.width * 0.5, size.height * 0.5,
      )
      ..cubicTo(
        size.width * 0.68, size.height * 0.58,
        size.width * 0.72, size.height * 0.2,
        size.width * 0.9, size.height * 0.2,
      );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = line.withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.2),
      5,
      Paint()..color = line,
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) => old.line != line;
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.isDark);

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    void glow(Offset center, double radius, Color color) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    glow(
      Offset(size.width * 0.15, size.height * 0.12),
      size.width * 0.7,
      AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
    );
    glow(
      Offset(size.width * 0.95, size.height * 0.42),
      size.width * 0.6,
      AppColors.energyElectric.withValues(alpha: isDark ? 0.14 : 0.08),
    );
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter old) => old.isDark != isDark;
}
