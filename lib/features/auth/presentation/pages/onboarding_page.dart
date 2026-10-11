import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/haptics.dart';
import '../widgets/onboarding_film.dart';
import '../widgets/onboarding_film_art.dart';

/// First-run intro: the "GAZ & ENERGIYA — Oson buyurtma" creative, played
/// as a 25-second story. It autoplays scene to scene; the viewer can pause,
/// step, swipe or use the arrow keys between the six scenes, or skip to
/// sign in. With reduced motion the film becomes six still frames.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: FilmTimeline.total),
  )..addListener(_onTick);

  static const _last = FilmTimeline.sceneCount - 1;

  int _scene = 0;
  bool _finished = false;
  bool _started = false;
  bool _reduceMotion = false;
  bool _paused = false;
  bool _foreground = true;
  bool _leaving = false;

  /// Paused navigation shows a scene's settled frame; pressing play then
  /// replays that scene from its start instead of cutting to the next one.
  bool _replayOnResume = false;
  double _dragDx = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (!_started) {
      _started = true;
      for (final image in OnboardingFilm.images) {
        precacheImage(AssetImage(image), context);
      }
    } else if (reduce == _reduceMotion) {
      return;
    }
    _reduceMotion = reduce;
    if (reduce) _hold(_scene);
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // `inactive` is a blurred browser tab or a pulled-down shade: the film
    // is still visible, so it keeps playing.
    _foreground = state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock.dispose();
    super.dispose();
  }

  void _onTick() {
    final scene = FilmTimeline.sceneAt(_clock.value * FilmTimeline.total);
    final finished = _clock.value >= 1;
    if (scene != _scene || finished != _finished) {
      setState(() {
        _scene = scene;
        _finished = finished;
      });
    }
  }

  /// Runs the clock exactly while the film should be moving.
  void _sync() {
    final run = !_reduceMotion &&
        !_paused &&
        _foreground &&
        !_leaving &&
        _clock.value < 1;
    if (run && !_clock.isAnimating) {
      if (_replayOnResume) {
        _replayOnResume = false;
        _clock.value = FilmTimeline.starts[_scene] / FilmTimeline.total;
      }
      _clock.forward();
    } else if (!run && _clock.isAnimating) {
      _clock.stop();
    }
  }

  /// Shows [scene] fully built and still.
  void _hold(int scene) {
    _clock.value = FilmTimeline.settled(scene) / FilmTimeline.total;
    _replayOnResume = true;
  }

  void _show(int scene) {
    if (_leaving) return;
    AppHaptics.selection();
    if (_reduceMotion || _paused) {
      _hold(scene);
    } else {
      _replayOnResume = false;
      _clock.value = FilmTimeline.starts[scene] / FilmTimeline.total;
      _sync();
    }
  }

  void _step(int delta) {
    final target = _scene + delta;
    if (target >= 0 && target <= _last) _show(target);
  }

  void _next() {
    if (_scene == _last) {
      _openLogin();
    } else {
      _show(_scene + 1);
    }
  }

  void _togglePlayback() {
    AppHaptics.tap();
    if (_finished) {
      _paused = false;
      _replayOnResume = false;
      _clock.value = 0;
    } else {
      _paused = !_paused;
    }
    _sync();
    setState(() {});
  }

  void _openLogin() {
    if (_leaving) return;
    _leaving = true;
    _sync();
    AppHaptics.tap();
    context.go('/login');
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final dx = _dragDx;
    _dragDx = 0;
    if (dx.abs() >= 45) {
      _step(dx < 0 ? 1 : -1);
    } else if (velocity.abs() >= 350) {
      _step(velocity < 0 ? 1 : -1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _scene == _last;
    // The page wears the scene's own colour, so the film reads as the
    // whole screen (a story) instead of a card on a card. Scenes cut
    // instantly, and so does the page — no seam during a cut.
    final dark = FilmTimeline.isDark(_scene);
    _FilmStage film(EdgeInsets padding) => _FilmStage(
          clock: _clock,
          scene: _scene,
          reducedMotion: _reduceMotion,
          padding: padding,
          onSkip: last ? null : _openLogin,
          onDragStart: () => _dragDx = 0,
          onDragUpdate: (dx) => _dragDx += dx,
          onDragEnd: _onDragEnd,
        );
    final controls = _Controls(
      dark: dark,
      label: last ? 'Boshlash' : 'Davom etish',
      onBack: _scene > 0 ? () => _step(-1) : null,
      onNext: _next,
      // Doston: ▶/⏸ tugmasi video'ga o'xshab ketardi — olib tashlandi,
      // animatsiya avtomatik ketaveradi.
      playback: null,
      onPlayback: _togglePlayback,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: dark ? filmInk : filmPaper,
        body: SafeArea(
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
                  _step(1),
              const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
                  _step(-1),
            },
            child: Focus(
              autofocus: true,
              child: LayoutBuilder(
                builder: (context, box) {
                  // Landscape and wide windows: film and controls side by side.
                  if (box.maxWidth > box.maxHeight * 1.1) {
                    final filmWidth = math.min(
                      box.maxWidth * .55,
                      (box.maxHeight - 20) *
                              OnboardingFilm.width /
                              OnboardingFilm.height +
                          24,
                    );
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: filmWidth,
                          child: film(const EdgeInsets.all(12)),
                        ),
                        SizedBox(
                          width: math.min(380, box.maxWidth - filmWidth),
                          child: Center(
                            child: SingleChildScrollView(child: controls),
                          ),
                        ),
                      ],
                    );
                  }
                  // Portrait and square-ish windows: film and controls stay
                  // together as one centred group, so a tall phone does not
                  // open a gap between them. The film always scales to fit
                  // fully inside its box — full width on a tall phone,
                  // letterboxed on a short window — so it is never cropped
                  // and never needs to scroll. Both share one explicit
                  // width (rather than letting the film size itself and
                  // controls stretch independently) so a short window
                  // never leaves them as two mismatched-width cards.
                  // The film runs edge to edge: it has its own margins,
                  // and the page around it is the same colour.
                  final groupWidth = math.min(
                    box.maxWidth,
                    math.min(
                      520.0,
                      (box.maxHeight - _Controls.height) *
                          OnboardingFilm.width /
                          OnboardingFilm.height,
                    ),
                  );
                  return Center(
                    child: SizedBox(
                      width: groupWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Flexible(child: film(EdgeInsets.zero)),
                          controls,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The film with swipe navigation and the skip button laid over its brand
/// row. It always scales to fit fully inside its box at its 9:16 ratio —
/// full width on a tall phone, letterboxed on a short window — so it is
/// never cropped and never needs to scroll.
class _FilmStage extends StatelessWidget {
  const _FilmStage({
    required this.clock,
    required this.scene,
    required this.reducedMotion,
    required this.padding,
    required this.onSkip,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final Animation<double> clock;
  final int scene;
  final bool reducedMotion;
  final EdgeInsets padding;
  final VoidCallback? onSkip;
  final VoidCallback onDragStart;
  final ValueChanged<double> onDragUpdate;
  final GestureDragEndCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final onSkip = this.onSkip;
    final film = AspectRatio(
      aspectRatio: OnboardingFilm.width / OnboardingFilm.height,
      child: LayoutBuilder(
        builder: (context, box) {
          // Film pixels → screen pixels.
          final s = box.maxWidth / OnboardingFilm.width;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // No card, no shadow: the page around the film is the
              // film's own colour, so its edges simply disappear.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (_) => onDragStart(),
                  onHorizontalDragUpdate: (details) =>
                      onDragUpdate(details.delta.dx),
                  onHorizontalDragEnd: onDragEnd,
                  child: Semantics(
                    container: true,
                    liveRegion: true,
                    label: 'Kirish filmi, ${scene + 1}-sahna, jami '
                        '${FilmTimeline.sceneCount} ta. '
                        '${FilmTimeline.descriptions[scene]}',
                    child: AnimatedBuilder(
                      animation: clock,
                      builder: (context, _) => OnboardingFilm(
                        time: clock.value * FilmTimeline.total,
                        reducedMotion: reducedMotion,
                      ),
                    ),
                  ),
                ),
              ),
              if (onSkip != null)
                // Right of the brand name. On a small film (landscape)
                // only the label shrinks; the button stays 48 px tall
                // so it is always an easy target.
                Positioned(
                  top: 52 * s - 24,
                  left: 160 * s,
                  right: math.max(0, 23 * s - 12),
                  height: 48,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _SkipButton(
                      dark: FilmTimeline.isDark(scene),
                      onPressed: onSkip,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
    return Padding(
      padding: padding,
      child: Center(
        // Only as tall as the 9:16 film itself; AspectRatio above already
        // scaled it to fit the available box.
        heightFactor: 1,
        child: film,
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.dark, required this.onPressed});

  final bool dark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = dark ? filmPaper : filmInk;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: const StadiumBorder(),
          textStyle: filmText(12.5, weight: FontWeight.w600),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('O‘tkazib yuborish'),
              const SizedBox(width: 4),
              Transform.rotate(
                angle: -math.pi / 4,
                child: FilmGlyph.arrow(size: 18, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Playback { pause, play, replay }

class _Controls extends StatelessWidget {
  const _Controls({
    required this.dark,
    required this.label,
    required this.onBack,
    required this.onNext,
    required this.playback,
    required this.onPlayback,
  });

  /// Fixed intrinsic height: the 56 px buttons don't grow with text scale
  /// (labels shrink to fit via `FittedBox` instead), so this is exact at
  /// any scale — used to size the film to match this bar's width.
  static const height = 56.0 + 14 + 12;

  /// On an ink scene the bar inverts, so it never sinks into the page.
  final bool dark;
  final String label;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  /// `null` with reduced motion: there is nothing to pause.
  final _Playback? playback;
  final VoidCallback onPlayback;

  @override
  Widget build(BuildContext context) {
    final playback = this.playback;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.6,
        child: Row(
          children: [
            _RoundButton(
              dark: dark,
              icon: Icons.arrow_back_rounded,
              tooltip: 'Oldingi sahna',
              onPressed: onBack,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: dark ? filmPaper : filmInk,
                  foregroundColor: dark ? filmInk : filmPaper,
                  minimumSize: const Size(0, 56),
                  padding: const EdgeInsets.fromLTRB(22, 12, 18, 12),
                  shape: const StadiumBorder(),
                  textStyle:
                      filmText(16, weight: FontWeight.w700, spacing: -.2),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(label),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const FilmGlyph.arrow(size: 24, color: filmRed),
                  ],
                ),
              ),
            ),
            if (playback != null) ...[
              const SizedBox(width: 10),
              _RoundButton(
                dark: dark,
                icon: switch (playback) {
                  _Playback.pause => Icons.pause_rounded,
                  _Playback.play => Icons.play_arrow_rounded,
                  _Playback.replay => Icons.replay_rounded,
                },
                tooltip: switch (playback) {
                  _Playback.pause => 'Animatsiyani to‘xtatish',
                  _Playback.play => 'Animatsiyani davom ettirish',
                  _Playback.replay => 'Boshidan ko‘rish',
                },
                onPressed: onPlayback,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.dark,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final bool dark;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 24,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(56),
        backgroundColor: dark ? const Color(0x14F5F1E8) : Colors.white,
        foregroundColor: dark ? filmPaper : filmInk,
        disabledBackgroundColor: Colors.transparent,
        disabledForegroundColor:
            dark ? const Color(0x55F5F1E8) : const Color(0x5517221B),
        side: BorderSide(
          color: dark ? const Color(0x40F5F1E8) : const Color(0xFFD9D4C7),
        ),
        shape: const CircleBorder(),
      ),
      icon: Icon(icon),
    );
  }
}
