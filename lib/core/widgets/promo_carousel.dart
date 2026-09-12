import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/motion.dart';
import 'app_tappable.dart';
import 'service_card.dart';

/// One [HighlightServiceCard]'s worth of content for [PromoCarousel].
class PromoSlide {
  const PromoSlide({
    required this.onTap,
    required this.title,
    required this.caption,
    this.overline = 'Aholi uchun',
    this.badge = 'Aktiv',
    this.icon = Icons.local_fire_department_rounded,
    this.photoUrl,
    this.gradient,
    this.glowColor,
  });

  final VoidCallback onTap;
  final String overline;
  final String title;
  final String caption;
  final String badge;
  final IconData icon;
  final String? photoUrl;
  final Gradient? gradient;
  final Color? glowColor;
}

/// Auto-rotating home-page promo banner. Replaces the single static
/// [HighlightServiceCard] with a swipeable `PageView` of them — plus the
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
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: widget.slides.length,
                onPageChanged: (i) {
                  setState(() => _index = i);
                  _scheduleAutoRotate();
                },
                itemBuilder: (context, i) {
                  final s = widget.slides[i];
                  return HighlightServiceCard(
                    onTap: s.onTap,
                    overline: s.overline,
                    title: s.title,
                    caption: s.caption,
                    badge: s.badge,
                    icon: s.icon,
                    photoUrl: s.photoUrl,
                    gradient: s.gradient,
                    glowColor: s.glowColor,
                  );
                },
              ),
              if (!single) ...[
                Positioned(
                  left: 2,
                  child: _CarouselArrow(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => _goTo((_index - 1 + widget.slides.length) % widget.slides.length),
                  ),
                ),
                Positioned(
                  right: 2,
                  child: _CarouselArrow(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => _goTo((_index + 1) % widget.slides.length),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (!single) ...[
          const SizedBox(height: AppDimensions.space10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                        : context.palette.border,
                    borderRadius: AppDimensions.brPill,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Left/right "‹ ›" control floating on the slide edge — always tappable,
/// not just decorative, so the carousel never feels stuck.
class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppTappable(
      onTap: onTap,
      pressedScale: 0.88,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
