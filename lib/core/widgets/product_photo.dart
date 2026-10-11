import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// What a product photo is, read from a tiny decode of it:
/// a cut-out (transparent background — stands on the app's own stage) or
/// a full photo (its own background — shown framed, over a blurred copy).
@immutable
class ProductPhotoInfo {
  const ProductPhotoInfo({required this.cutout, required this.aspect});

  final bool cutout;

  /// Width / height.
  final double aspect;
}

final _known = <String, ProductPhotoInfo?>{};
final _pending = <String, Future<ProductPhotoInfo?>>{};

/// Already-probed result, so a rebuild never flashes the "unknown" look.
ProductPhotoInfo? knownProductPhotoInfo(String url) => _known[url];

/// Probes [url] once per app run (a 48 px decode); `null` if it won't load.
Future<ProductPhotoInfo?> productPhotoInfo(String url) {
  if (_known.containsKey(url)) return SynchronousFuture(_known[url]);
  return _pending.putIfAbsent(url, () async {
    final info = await _probe(url);
    _known[url] = info;
    _pending.remove(url);
    return info;
  });
}

@visibleForTesting
void debugSetProductPhotoInfo(String url, ProductPhotoInfo info) =>
    _known[url] = info;

Future<ProductPhotoInfo?> _probe(String url) async {
  final stream = ResizeImage(CachedNetworkImageProvider(url), width: 48)
      .resolve(ImageConfiguration.empty);
  final done = Completer<ui.Image?>();
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      if (!done.isCompleted) done.complete(info.image.clone());
      stream.removeListener(listener);
    },
    onError: (_, __) {
      if (!done.isCompleted) done.complete(null);
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);

  final image = await done.future;
  if (image == null) return null;
  try {
    final w = image.width;
    final h = image.height;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return null;
    // Cut-out: a good share of the border is see-through.
    var border = 0;
    var clear = 0;
    void sample(int x, int y) {
      border++;
      if (data.getUint8((y * w + x) * 4 + 3) < 200) clear++;
    }

    for (var x = 0; x < w; x++) {
      sample(x, 0);
      sample(x, h - 1);
    }
    for (var y = 1; y < h - 1; y++) {
      sample(0, y);
      sample(w - 1, y);
    }
    return ProductPhotoInfo(cutout: clear / border > 0.2, aspect: w / h);
  } catch (_) {
    return null;
  } finally {
    image.dispose();
  }
}

/// Calls [builder] with the photo's [ProductPhotoInfo] — `null` until the
/// probe finishes (or if the photo won't load).
class ProductPhotoInfoBuilder extends StatelessWidget {
  const ProductPhotoInfoBuilder(
      {super.key, required this.url, required this.builder});

  final String url;
  final Widget Function(BuildContext context, ProductPhotoInfo? info) builder;

  @override
  Widget build(BuildContext context) {
    final known = knownProductPhotoInfo(url);
    if (known != null) return builder(context, known);
    return FutureBuilder<ProductPhotoInfo?>(
      key: ValueKey(url),
      future: productPhotoInfo(url),
      builder: (context, snap) => builder(context, snap.data),
    );
  }
}

/// A full photo's own colours, blurred, filling the frame behind it — so a
/// dark poster or a white studio shot fills the space instead of sitting
/// as a small rectangle on a blue stage.
class ProductPhotoBackdrop extends StatelessWidget {
  const ProductPhotoBackdrop({super.key, required this.url, this.blur = 18});

  final String url;
  final double blur;

  @override
  Widget build(BuildContext context) {
    // The same provider as the sharp photo on top — already downloaded and
    // decoded, so the backdrop costs only the blur.
    return ClipRect(
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
            sigmaX: blur, sigmaY: blur, tileMode: TileMode.clamp),
        child: Image(
          image: CachedNetworkImageProvider(url),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.low,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
