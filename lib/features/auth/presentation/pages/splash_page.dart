import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../widgets/login_brand_header.dart';
import '../widgets/onboarding_film.dart';

/// First screen: the Alanga logo on the brand cream, while the intro's
/// photos load.
///
/// On the web, `web/index.html` paints this very screen (same cream, same
/// glow, the logo at the same size and spot) before Flutter has even
/// started, and fades out on Flutter's first frame — so opening the app
/// on a phone goes cream → cream with no white or blue flash. Keep the
/// two in step: [logoWidthFor] and the colours below match the CSS.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  /// The logo's width on a screen [width] wide — `min(56vw, 240px)` in
  /// the HTML.
  static double logoWidthFor(double width) => math.min(width * .56, 240);

  static const top = Color(0xFFFFF7EE);
  static const bottom = Color(0xFFFCE8D5);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  /// Brings in the tagline and the loading dots under the (already
  /// visible) logo.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  /// Long enough for the brand to register…
  Timer? _minimum;

  /// …and never held hostage by a slow image.
  Timer? _maximum;

  bool _minimumDone = false;
  bool _imagesReady = false;
  bool _started = false;
  bool _left = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else {
      _intro.forward();
    }

    // The intro shows these the moment it opens; loading them here means
    // its first scene never pops in photo by photo.
    Future.wait([
      for (final image in [
        LoginBrandHeader.logoAsset,
        ...OnboardingFilm.images
      ])
        precacheImage(AssetImage(image), context),
    ]).then((_) {
      _imagesReady = true;
      _maybeLeave();
    });
    _minimum = Timer(const Duration(milliseconds: 1100), () {
      _minimumDone = true;
      _maybeLeave();
    });
    _maximum = Timer(const Duration(seconds: 4), _leave);
  }

  void _maybeLeave() {
    if (_minimumDone && _imagesReady) _leave();
  }

  void _leave() {
    if (_left || !mounted) return;
    _left = true;
    _minimum?.cancel();
    _maximum?.cancel();
    context.go('/onboarding');
  }

  @override
  void dispose() {
    _minimum?.cancel();
    _maximum?.cancel();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _intro, curve: Curves.easeOut);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: SplashPage.bottom,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [SplashPage.top, SplashPage.bottom],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              final logoWidth = SplashPage.logoWidthFor(box.maxWidth);
              final logoHeight = logoWidth * 612 / 720;
              return Stack(
                children: [
                  // The soft light behind the logo, as on the sign-in header.
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        // A fraction of the shorter side: `62vmin` in CSS.
                        gradient: RadialGradient(
                          radius: .62,
                          colors: [
                            Colors.white.withValues(alpha: .85),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Dead centre of the whole screen, exactly where the
                  // HTML put it — no safe-area shift.
                  Center(
                    child: Image.asset(
                      LoginBrandHeader.logoAsset,
                      width: logoWidth,
                      height: logoHeight,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.medium,
                      semanticLabel: 'Alanga',
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    top: box.maxHeight / 2 + logoHeight / 2 + 14,
                    child: FadeTransition(
                      opacity: fade,
                      child: Text(
                        AppConstants.tagline,
                        textAlign: TextAlign.center,
                        style: AppTypography.callout.copyWith(
                          color: const Color(0xFF3B4A66),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 40 + MediaQuery.paddingOf(context).bottom,
                    child: FadeTransition(
                      opacity: fade,
                      child: const _LoadingDots(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  /// The logo's flame orange and ring navy.
  static const _colors = [
    Color(0xFFF59E0B),
    Color(0xFFEA580C),
    Color(0xFF1E3A8A),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Yuklanmoqda',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final phase = (_controller.value - i * 0.18) % 1;
              final lift =
                  (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0).toDouble();
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                transform: Matrix4.translationValues(0, -5 * lift, 0),
                decoration: BoxDecoration(
                  color: _colors[i].withValues(alpha: 0.45 + 0.55 * lift),
                  shape: BoxShape.circle,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
