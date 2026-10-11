import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/product_illustration.dart';
import '../../../../core/widgets/app_tappable.dart';

/// A quiet, neutral photo gallery. Photos keep their original proportions;
/// several photos turn automatically and open full screen on tap.
class ProductGallery extends StatefulWidget {
  const ProductGallery({
    super.key,
    required this.images,
    required this.visual,
    required this.safeTop,
  });

  final List<String> images;
  final EnergyVisual visual;

  /// Status bar height; the app bar's round buttons sit just below it.
  final double safeTop;

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  late final PageController _controller = PageController();
  int _page = 0;
  Timer? _autoplay;
  bool _viewerOpen = false;
  bool _touching = false;

  /// A swipe or tap pauses the autoplay until then.
  DateTime _holdUntil = DateTime.fromMillisecondsSinceEpoch(0);

  static const _turnEvery = Duration(seconds: 4);
  static const _holdAfterTouch = Duration(seconds: 7);

  @override
  void initState() {
    super.initState();
    _restartAutoplay();
  }

  @override
  void didUpdateWidget(ProductGallery old) {
    super.didUpdateWidget(old);
    if (!listEquals(old.images, widget.images)) {
      _page = 0;
      if (_controller.hasClients) _controller.jumpToPage(0);
      _restartAutoplay();
    }
  }

  @override
  void dispose() {
    _autoplay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartAutoplay() {
    _autoplay?.cancel();
    if (widget.images.length < 2) return;
    _autoplay = Timer.periodic(_turnEvery, (_) => _turn());
  }

  void _turn() {
    if (!mounted || _viewerOpen || _touching || !_controller.hasClients) return;
    if (!TickerMode.valuesOf(context).enabled ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed ||
        _controller.position.isScrollingNotifier.value) {
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) return;
    if (DateTime.now().isBefore(_holdUntil)) return;
    _controller.animateToPage(
      (_page + 1) % widget.images.length,
      duration: AppMotion.slower,
      curve: AppMotion.standard,
    );
  }

  void _hold() => _holdUntil = DateTime.now().add(_holdAfterTouch);

  void _openViewer() {
    if (_viewerOpen || widget.images.isEmpty) return;
    final images = List<String>.of(widget.images);
    _hold();
    _viewerOpen = true;
    Navigator.of(context, rootNavigator: true)
        .push(
      PageRouteBuilder<int>(
        opaque: false,
        transitionDuration: AppMotion.base,
        reverseTransitionDuration: AppMotion.fast,
        pageBuilder: (_, __, ___) => ProductImageViewer(
          images: images,
          initialIndex: _page,
          visual: widget.visual,
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity:
              CurvedAnimation(parent: animation, curve: AppMotion.standard),
          child: child,
        ),
      ),
    )
        .then((index) {
      _viewerOpen = false;
      _hold();
      // The viewer may end on another photo — follow it here.
      if (!mounted ||
          index == null ||
          index == _page ||
          !listEquals(images, widget.images) ||
          !_controller.hasClients) {
        return;
      }
      setState(() => _page = index);
      _controller.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final images = widget.images;
    final illustration =
        ProductIllustration(visual: widget.visual, showStage: false);

    return ColoredBox(
      color: c.isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F5F7),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (images.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: widget.safeTop + kToolbarHeight),
              child: illustration,
            )
          else
            NotificationListener<ScrollStartNotification>(
              onNotification: (n) {
                if (n.dragDetails != null) _hold();
                return false;
              },
              child: Listener(
                onPointerDown: (_) {
                  _touching = true;
                  _hold();
                },
                onPointerUp: (_) {
                  _touching = false;
                  _hold();
                },
                onPointerCancel: (_) {
                  _touching = false;
                  _hold();
                },
                child: GestureDetector(
                  onTap: _openViewer,
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) => Padding(
                      padding:
                          EdgeInsets.fromLTRB(28, widget.safeTop + 68, 28, 52),
                      child: CachedNetworkImage(
                        key: ValueKey(images[i]),
                        imageUrl: images[i],
                        fit: BoxFit.contain,
                        fadeInDuration: AppMotion.fast,
                        placeholder: (_, __) => illustration,
                        errorWidget: (_, __, ___) => illustration,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: AppDimensions.space12,
              child: _Dots(
                  count: images.length, active: _page, color: c.textPrimary),
            ),
          if (images.isNotEmpty)
            Positioned(
              right: AppDimensions.gutter,
              bottom: AppDimensions.space10,
              child: Semantics(
                label: 'Rasmni kattalashtirish',
                button: true,
                child: AppTappable(
                  onTap: _openViewer,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Icons.open_in_full_rounded,
                        size: 17, color: c.textSecondary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active, required this.color});

  final int count;
  final int active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: AppMotion.base,
            curve: AppMotion.standard,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == active ? 14 : 5,
            height: 5,
            decoration: BoxDecoration(
              color:
                  i == active ? color : c.textTertiary.withValues(alpha: 0.35),
              borderRadius: AppDimensions.brPill,
            ),
          ),
      ],
    );
  }
}

/// Full-screen photos: swipe, pinch or double-tap to zoom, thumbnails to
/// jump. Pops with the index it ended on.
class ProductImageViewer extends StatefulWidget {
  const ProductImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.visual,
  });

  final List<String> images;
  final int initialIndex;
  final EnergyVisual visual;

  @override
  State<ProductImageViewer> createState() => _ProductImageViewerState();
}

class _ProductImageViewerState extends State<ProductImageViewer> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _page = widget.initialIndex;

  /// While a photo is zoomed in, a drag pans it instead of turning the page.
  bool _zoomed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop(_page);

  void _goTo(int index) {
    _controller.animateToPage(
      index,
      duration: AppMotion.base,
      curve: AppMotion.standard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final images = widget.images;
    final illustration =
        ProductIllustration(visual: widget.visual, showStage: false);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.gutter,
                  AppDimensions.space8,
                  AppDimensions.gutter,
                  0,
                ),
                child: Row(
                  children: [
                    AppIconButton(
                      icon: Icons.close_rounded,
                      iconSize: 20,
                      onTap: _close,
                    ),
                    const Spacer(),
                    if (images.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space12,
                          vertical: AppDimensions.space6,
                        ),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: AppDimensions.brPill,
                          border: Border.all(color: c.border),
                        ),
                        child: Text(
                          '${_page + 1} / ${images.length}',
                          style: AppTypography.caption.copyWith(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  physics: _zoomed
                      ? const NeverScrollableScrollPhysics()
                      : const PageScrollPhysics(),
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() {
                    _page = i;
                    _zoomed = false;
                  }),
                  itemBuilder: (_, i) => _ZoomablePhoto(
                    url: images[i],
                    placeholder: illustration,
                    onZoomChanged: (zoomed) {
                      if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
                    },
                  ),
                ),
              ),
              if (images.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.gutter,
                    AppDimensions.space8,
                    AppDimensions.gutter,
                    AppDimensions.space16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < images.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.space4,
                          ),
                          child: _Thumb(
                            url: images[i],
                            selected: i == _page,
                            onTap: () => _goTo(i),
                          ),
                        ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.space16),
                  child: Text(
                    'Kattalashtirish uchun ikki marta bosing',
                    style:
                        AppTypography.caption.copyWith(color: c.textTertiary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoomablePhoto extends StatefulWidget {
  const _ZoomablePhoto({
    required this.url,
    required this.placeholder,
    required this.onZoomChanged,
  });

  final String url;
  final Widget placeholder;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto>
    with SingleTickerProviderStateMixin {
  final _transform = TransformationController();
  late final AnimationController _anim;
  late final CurvedAnimation _curve;
  Matrix4Tween? _tween;
  Offset _tapAt = Offset.zero;

  static const double _doubleTapScale = 2.6;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: AppMotion.base);
    _curve = CurvedAnimation(parent: _anim, curve: AppMotion.standard);
    _anim.addListener(() => _transform.value = _tween!.evaluate(_curve));
  }

  @override
  void dispose() {
    _curve.dispose();
    _anim.dispose();
    _transform.dispose();
    super.dispose();
  }

  bool get _isZoomed => _transform.value.getMaxScaleOnAxis() > 1.01;

  void _animateTo(Matrix4 target) {
    _tween = Matrix4Tween(begin: _transform.value, end: target);
    _anim.forward(from: 0);
    widget.onZoomChanged(target.getMaxScaleOnAxis() > 1.01);
  }

  void _toggleZoom() {
    if (_isZoomed) {
      _animateTo(Matrix4.identity());
      return;
    }
    // Zoom towards the tapped point.
    const s = _doubleTapScale;
    _animateTo(
      Matrix4.identity()
        ..translateByDouble(-_tapAt.dx * (s - 1), -_tapAt.dy * (s - 1), 0, 1)
        ..scaleByDouble(s, s, 1, 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (d) => _tapAt = d.localPosition,
      onDoubleTap: _toggleZoom,
      child: InteractiveViewer(
        transformationController: _transform,
        minScale: 1,
        maxScale: 4,
        onInteractionEnd: (_) => widget.onZoomChanged(_isZoomed),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space20),
          child: CachedNetworkImage(
            imageUrl: widget.url,
            fit: BoxFit.contain,
            placeholder: (_, __) => widget.placeholder,
            errorWidget: (_, __, ___) => widget.placeholder,
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb(
      {required this.url, required this.selected, required this.onTap});

  final String url;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        width: 56,
        height: 56,
        padding: const EdgeInsets.all(AppDimensions.space4),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppDimensions.brSmall,
          border: Border.all(
            color: selected ? c.primary : c.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Opacity(
          opacity: selected ? 1 : 0.6,
          child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
