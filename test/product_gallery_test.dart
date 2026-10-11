import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaz_energiya/app/theme/app_theme.dart';
import 'package:gaz_energiya/core/widgets/product_illustration.dart';
import 'package:gaz_energiya/core/widgets/product_photo.dart';
import 'package:gaz_energiya/features/products/presentation/widgets/product_gallery.dart';

const _urls = ['https://test.invalid/a.png', 'https://test.invalid/b.png'];

void main() {
  Future<void> seed(WidgetTester tester) async {
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 48, 80),
        Paint()..color = Colors.blue,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(48, 80);
      picture.dispose();
      for (final url in _urls) {
        debugSetProductPhotoInfo(
            url, const ProductPhotoInfo(cutout: false, aspect: 0.6));
        PaintingBinding.instance.imageCache.putIfAbsent(
          await CachedNetworkImageProvider(url)
              .obtainKey(ImageConfiguration.empty),
          () => OneFrameImageStreamCompleter(
              SynchronousFuture(ImageInfo(image: image.clone()))),
        );
      }
      image.dispose();
    });
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  }

  Future<void> host(
    WidgetTester tester, {
    List<String> images = _urls,
    bool enabled = true,
    bool reduceMotion = false,
  }) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: TickerMode(
          enabled: enabled,
          child: Scaffold(
              body: SizedBox(
            width: 390,
            height: 440,
            child: ProductGallery(
                images: images, visual: EnergyVisual.cylinder, safeTop: 0),
          )),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));
  }

  int page(WidgetTester tester) => tester
      .widget<PageView>(find.byType(PageView).first)
      .controller!
      .page!
      .round();

  Future<void> turn(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('gallery advances and wraps around', (tester) async {
    await seed(tester);
    await host(tester);
    expect(page(tester), 0);
    await turn(tester);
    expect(page(tester), 1);
    await turn(tester);
    expect(page(tester), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gallery respects reduced motion, hidden routes and app pause',
      (tester) async {
    await seed(tester);
    await host(tester, reduceMotion: true);
    await turn(tester);
    expect(page(tester), 0);
    await host(tester, enabled: false);
    await turn(tester);
    expect(page(tester), 0);
    await host(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await turn(tester);
    expect(page(tester), 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await turn(tester);
    expect(page(tester), 1);
  });

  testWidgets('replacing or removing images resets the selected page',
      (tester) async {
    await seed(tester);
    await host(tester);
    await turn(tester);
    expect(page(tester), 1);
    await host(tester, images: _urls.reversed.toList());
    expect(page(tester), 0);
    await host(tester, images: [_urls.first]);
    await turn(tester);
    expect(page(tester), 0);
    await host(tester, images: []);
    await turn(tester);
    expect(find.byType(PageView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('holding a photo pauses autoplay throughout a long touch',
      (tester) async {
    await seed(tester);
    await host(tester);
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(PageView)));
    await tester.pump(const Duration(seconds: 12));
    await tester.pump(const Duration(seconds: 1));
    expect(page(tester), 0);
    await gesture.cancel();
    expect(tester.takeException(), isNull);
  });

  testWidgets('viewer selection returns to the gallery', (tester) async {
    await seed(tester);
    await host(tester);
    await tester.tap(find.byIcon(Icons.open_in_full_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(ProductImageViewer), findsOneWidget);
    await tester.drag(find.byType(PageView).last, const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(page(tester), 1);
    expect(tester.takeException(), isNull);
  });
}
