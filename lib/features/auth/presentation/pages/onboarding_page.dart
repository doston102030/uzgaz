import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_tappable.dart';

/// A cinematic first-run experience. It gives the brand a distinct, premium
/// first impression while the rest of the app stays practical and familiar.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = [
    _Copy('ENERGIYA, SIZNING RITMINGIZDA', 'Har bir yo\'l uchun\nkerakli quvvat.',
        'Gaz, yoqilg\'i va elektr quvvatlashni bitta aqlli ilovada boshqaring.', 'Kashf qilish'),
    _Copy('AQILLI TANLOV', 'Eng yaxshi taklif\nbir qarashda.',
        'Narx, masofa va yetkazish vaqtini solishtiring. Qarorni biz tezlashtiramiz.', 'Takliflarni ko\'rish'),
    _Copy('DOIMO XABARDOR', 'Buyurtmangiz\nharakatda.',
        'Kuryer qayerdaligini jonli kuzating va buyurtmangizni xotirjam kuting.', 'Boshlash'),
  ];

  void _next() {
    if (_index == _slides.length - 1) {
      context.go('/login');
    } else {
      _controller.nextPage(duration: AppMotion.slower, curve: AppMotion.enter);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = _slides[_index];
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FE),
      body: Stack(children: [
        const Positioned.fill(child: CustomPaint(painter: _BackdropPainter())),
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 16, 0),
              child: Row(children: [
                const _BrandMark(),
                const Spacer(),
                _SkipButton(onTap: () => context.go('/login')),
              ]),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (_, index) => _Visual(index: index),
              ),
            ),
            AnimatedSwitcher(
              duration: AppMotion.base,
              switchInCurve: AppMotion.enter,
              child: Padding(
                key: ValueKey(_index),
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(children: [
                  Text(copy.eyebrow, textAlign: TextAlign.center,
                      style: AppTypography.overline.copyWith(color: const Color(0xFF7EAEFF), letterSpacing: 1.35)),
                  const SizedBox(height: 12),
                  Text(copy.title, textAlign: TextAlign.center,
                      style: AppTypography.largeTitle.copyWith(color: const Color(0xFF101C33), fontSize: 32, height: 1.08, letterSpacing: -1.05)),
                  const SizedBox(height: 14),
                  Text(copy.body, textAlign: TextAlign.center,
                      style: AppTypography.callout.copyWith(color: const Color(0xFF60728D), height: 1.48)),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            _Progress(index: _index),
            Padding(
              padding: EdgeInsets.fromLTRB(22, 22, 22, 14 + bottom),
              child: Column(children: [
                _ActionButton(label: copy.action, onTap: _next),
                const SizedBox(height: 14),
                AppTappable(
                  onTap: () => context.go('/login'),
                  child: RichText(text: TextSpan(
                    style: AppTypography.footnote.copyWith(color: const Color(0xFF70809A)),
                    children: const [TextSpan(text: 'Hisobingiz bormi?  '), TextSpan(text: 'Kirish', style: TextStyle(color: Color(0xFF79A8FF), fontWeight: FontWeight.w700))],
                  )),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Copy {
  const _Copy(this.eyebrow, this.title, this.body, this.action);
  final String eyebrow, title, body, action;
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 32, height: 32, decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF5C9DFF), Color(0xFF2563EB)]), borderRadius: BorderRadius.circular(11),
      boxShadow: const [BoxShadow(color: Color(0x663B82F6), blurRadius: 16, offset: Offset(0, 5))],
    ), child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 19)),
    const SizedBox(width: 9),
    Text('GAZ & ENERGIYA', style: AppTypography.caption.copyWith(color: const Color(0xFF183D82), fontWeight: FontWeight.w800, letterSpacing: .55)),
  ]);
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => AppTappable(onTap: onTap, child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .72), border: Border.all(color: const Color(0xFFDCE6F6)), borderRadius: AppDimensions.brPill),
    child: Text('O\'tkazish', style: AppTypography.caption.copyWith(color: const Color(0xFF3B6FCA))),
  ));
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => AppTappable(onTap: onTap, pressedScale: .98, child: Container(
    height: 58, width: double.infinity,
    decoration: BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4C90FF), Color(0xFF2454E6)]),
      borderRadius: BorderRadius.circular(19), boxShadow: const [BoxShadow(color: Color(0x7A2563EB), blurRadius: 26, offset: Offset(0, 12))],
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(label, style: AppTypography.button.copyWith(color: Colors.white)), const SizedBox(width: 10), const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 21),
    ]),
  ));
}

class _Progress extends StatelessWidget {
  const _Progress({required this.index});
  final int index;
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => AnimatedContainer(
    duration: AppMotion.base, curve: AppMotion.standard, height: 5, width: i == index ? 28 : 6, margin: const EdgeInsets.symmetric(horizontal: 3),
    decoration: BoxDecoration(color: i == index ? const Color(0xFF377CF6) : const Color(0xFFD4DDEA), borderRadius: AppDimensions.brPill),
  )));
}

class _Visual extends StatelessWidget {
  const _Visual({required this.index});
  final int index;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(26, 22, 26, 0),
    child: Stack(alignment: Alignment.center, children: [
      const Positioned.fill(child: CustomPaint(painter: _OrbitPainter())),
      AnimatedSwitcher(
        duration: AppMotion.slow,
        switchInCurve: AppMotion.enter,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: Tween<double>(begin: .92, end: 1).animate(animation), child: child),
        ),
        child: _Frame(key: ValueKey(index), index: index),
      ),
    ]),
  );
}

class _Frame extends StatelessWidget {
  const _Frame({super.key, required this.index});
  final int index;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, constraints: const BoxConstraints(maxWidth: 360, maxHeight: 278),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .88), borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFFDCE6F6)), boxShadow: const [BoxShadow(color: Color(0x1A23466E), blurRadius: 36, offset: Offset(0, 20))]),
    child: ClipRRect(borderRadius: BorderRadius.circular(30), child: switch (index) { 0 => const _Hub(), 1 => const _Radar(), _ => const _Route() }),
  );
}

class _Hub extends StatelessWidget {
  const _Hub();
  @override
  Widget build(BuildContext context) => Stack(children: [
    const Positioned(top: 20, left: 20, child: _Label(icon: Icons.bolt_rounded, text: 'ENERGY HUB')),
    const Positioned(top: 75, left: 28, child: _Metric(label: 'Gaz ballon', value: '50 L', color: Color(0xFF5C9DFF))),
    const Positioned(top: 75, right: 28, child: _Metric(label: 'Elektr', value: '82%', color: Color(0xFFB17BFF))),
    Center(child: Container(width: 108, height: 108, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const RadialGradient(colors: [Color(0xFF397AFF), Color(0xFF153B9C)]), boxShadow: const [BoxShadow(color: Color(0x993B82F6), blurRadius: 34, spreadRadius: 5)], border: Border.all(color: const Color(0xFF8CB7FF), width: 2)), child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 48))),
    const Positioned(bottom: 21, left: 20, right: 20, child: _Status(text: 'Barcha xizmatlar tayyor')),
  ]);
}

class _Radar extends StatelessWidget {
  const _Radar();
  @override
  Widget build(BuildContext context) => Stack(children: [
    const Positioned(top: 20, left: 20, child: _Label(icon: Icons.auto_awesome_rounded, text: 'SMART MATCH')),
    Center(child: Stack(alignment: Alignment.center, children: [
      Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF315080)))),
      Container(width: 104, height: 104, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF42659C)))),
      Container(width: 58, height: 58, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF3477FF), boxShadow: [BoxShadow(color: Color(0x993477FF), blurRadius: 24)]), child: const Icon(Icons.storefront_rounded, color: Colors.white)),
    ])),
    const Positioned(top: 79, right: 24, child: _Offer(name: 'GazPlus', value: '125k', color: Color(0xFF35D39E))),
    const Positioned(bottom: 42, left: 24, child: _Offer(name: 'Mega Gaz', value: '118k', color: Color(0xFFB17BFF))),
  ]);
}

class _Route extends StatelessWidget {
  const _Route();
  @override
  Widget build(BuildContext context) => Stack(children: [
    const Positioned(top: 20, left: 20, child: _Label(icon: Icons.near_me_rounded, text: 'JONLI YETKAZISH')),
    Positioned.fill(child: Padding(padding: const EdgeInsets.fromLTRB(20, 64, 20, 52), child: CustomPaint(painter: _PathPainter()))),
    const Positioned(top: 104, left: 68, child: _Pin(icon: Icons.home_rounded, color: Color(0xFF9B7BFF))),
    const Positioned(right: 55, bottom: 85, child: _Pin(icon: Icons.local_shipping_rounded, color: Color(0xFF31D398))),
    const Positioned(bottom: 21, left: 20, right: 20, child: _Status(text: 'Kuryer 12 daqiqada yetib boradi')),
  ]);
}

class _Label extends StatelessWidget { const _Label({required this.icon, required this.text}); final IconData icon; final String text; @override Widget build(BuildContext context) => Row(children: [Icon(icon, size: 14, color: const Color(0xFF3477FF)), const SizedBox(width: 6), Text(text, style: AppTypography.caption2.copyWith(color: const Color(0xFF4775C1), letterSpacing: .7))]); }
class _Metric extends StatelessWidget { const _Metric({required this.label, required this.value, required this.color}); final String label, value; final Color color; @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: AppTypography.caption2.copyWith(color: const Color(0xFF71829C))), const SizedBox(height: 3), Text(value, style: AppTypography.title3.copyWith(color: color))]); }
class _Offer extends StatelessWidget { const _Offer({required this.name, required this.value, required this.color}); final String name, value; final Color color; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: const Color(0xFFF5F8FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: .48))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: AppTypography.caption2.copyWith(color: const Color(0xFF15213A))), Text(value, style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w800))])); }
class _Pin extends StatelessWidget { const _Pin({required this.icon, required this.color}); final IconData icon; final Color color; @override Widget build(BuildContext context) => Container(width: 42, height: 42, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withValues(alpha: .5), blurRadius: 18)]), child: Icon(icon, color: Colors.white, size: 20)); }
class _Status extends StatelessWidget { const _Status({required this.text}); final String text; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: const Color(0xFFF0FAF5), borderRadius: BorderRadius.circular(14)), child: Row(children: [Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF31B77A), shape: BoxShape.circle)), const SizedBox(width: 8), Expanded(child: Text(text, style: AppTypography.caption.copyWith(color: const Color(0xFF296443), fontWeight: FontWeight.w600)))])); }

class _OrbitPainter extends CustomPainter { const _OrbitPainter(); @override void paint(Canvas canvas, Size size) { final center = Offset(size.width / 2, size.height / 2); final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1; for (final scale in [.72, 1.0, 1.28]) { paint.color = const Color(0xFF5D8BD8).withValues(alpha: .12); canvas.drawOval(Rect.fromCenter(center: center, width: size.width * scale, height: size.width * scale * .42), paint); } } @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false; }
class _PathPainter extends CustomPainter { @override void paint(Canvas canvas, Size size) { final path = Path()..moveTo(size.width * .16, size.height * .22)..cubicTo(size.width * .62, size.height * .04, size.width * .28, size.height * .92, size.width * .84, size.height * .72); canvas.drawPath(path, Paint()..color = const Color(0xFF2E72FF).withValues(alpha: .22)..style = PaintingStyle.stroke..strokeWidth = 11..strokeCap = StrokeCap.round); canvas.drawPath(path, Paint()..color = const Color(0xFF6AA2FF)..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round); } @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false; }
class _BackdropPainter extends CustomPainter { const _BackdropPainter(); @override void paint(Canvas canvas, Size size) { final rect = Offset.zero & size; canvas.drawRect(rect, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF9FBFF), Color(0xFFF0F5FF), Color(0xFFF9F8FF)]).createShader(rect)); void glow(Offset center, double radius, Color color) => canvas.drawCircle(center, radius, Paint()..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: center, radius: radius))); glow(Offset(size.width * .12, size.height * .16), size.width * .65, const Color(0xFF72A7FF).withValues(alpha: .24)); glow(Offset(size.width * .98, size.height * .55), size.width * .55, const Color(0xFFC1A4FF).withValues(alpha: .18)); } @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false; }
