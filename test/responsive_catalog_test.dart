import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaz_energiya/app/theme/app_theme.dart';
import 'package:gaz_energiya/core/constants/app_constants.dart';
import 'package:gaz_energiya/core/widgets/category_artwork.dart';
import 'package:gaz_energiya/core/widgets/category_filter_bar.dart';
import 'package:gaz_energiya/core/widgets/responsive_frame.dart';
import 'package:gaz_energiya/core/widgets/service_category_grid.dart';
import 'package:gaz_energiya/features/catalog/presentation/pages/catalog_page.dart';
import 'package:gaz_energiya/features/companies/presentation/pages/company_list_page.dart';
import 'package:gaz_energiya/features/companies/presentation/providers/company_provider.dart';
import 'package:gaz_energiya/features/home/presentation/pages/home_page.dart';
import 'package:gaz_energiya/features/products/domain/entities/product.dart';
import 'package:gaz_energiya/features/products/presentation/providers/product_provider.dart';

const _product = Product(
  id: 'layout-test',
  name: 'Gaz ballon 50 litr va yetkazib berish',
  imageUrl: '',
  price: 120000,
  oldPrice: 150000,
  rating: 4.9,
  reviewCount: 214,
  isAvailable: true,
  companyId: 'layout-company',
  companyName: 'Sinov uchun uzun kompaniya nomi',
  categoryId: 'gazBallon',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => Directory.systemTemp.path);
    // Optional real-font renders; ordinary CI still uses Flutter's test font.
    final fonts = Platform.environment['GAZ_TEST_FONT_DIR'];
    if (fonts != null) {
      final loader = FontLoader('Roboto');
      for (final weight in ['regular', 'medium', 'bold']) {
        loader.addFont(File('$fonts/roboto-$weight.ttf')
            .readAsBytes()
            .then(ByteData.sublistView));
      }
      await loader.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(File('$fonts/materialicons-regular.otf')
          .readAsBytes()
          .then(ByteData.sublistView));
      await icons.load();
    }
  });

  Future<void> host(
    WidgetTester tester,
    Widget page, {
    double width = 390,
    double height = 844,
    double scale = 1,
    bool dark = false,
    bool reduceMotion = true,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        productsFutureProvider.overrideWith((_) async => [_product, _product]),
        companiesFutureProvider.overrideWith((_) async => []),
      ],
      child: MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: reduceMotion,
          ),
          child: ResponsiveFrame(child: child!),
        ),
        home: RepaintBoundary(key: const ValueKey('capture'), child: page),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.runAsync(() => precacheImage(
          const AssetImage('assets/images/promo_gas_cylinder.png'),
          tester.element(find.byType(MaterialApp)),
        ));
    await tester.pump();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    final output = Platform.environment['GAZ_RENDER_OUTPUT'];
    if (output == null) return;
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('capture')));
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(output).create(recursive: true);
      await File('$output/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(768, 600),
    const Size(1280, 800)
  ]) {
    for (final scale in [1.0, 1.25]) {
      for (final entry in <String, Widget>{
        'home': const HomePage(),
        'catalog': const CatalogPage(),
        'companies': const CompanyListPage(),
      }.entries) {
        testWidgets('${entry.key} fits ${size.width} at $scale text',
            (tester) async {
          addTearDown(tester.view.reset);
          await host(tester, entry.value,
              width: size.width, height: size.height, scale: scale);
          expect(tester.takeException(), isNull);
          if (scale == 1)
            await capture(tester, '${entry.key}-${size.width.toInt()}');
          final scroll = find.byType(CustomScrollView).first;
          await tester.drag(scroll, const Offset(0, -550));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('category selection, scrolling and initial selected item work',
      (tester) async {
    addTearDown(tester.view.reset);
    ServiceCategory? selected = ServiceCategory.market;
    await host(tester,
        Scaffold(body: StatefulBuilder(builder: (context, setState) {
      return CategoryFilterBar(
        selected: selected,
        counts: const {ServiceCategory.market: 3},
        onSelected: (value) => setState(() => selected = value),
      );
    })), width: 320);
    expect(find.text('Market').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Market'));
    await tester.pump();
    expect(selected, ServiceCategory.market);
    for (var i = 0; i < 8; i++) {
      await tester.tap(find.byTooltip('Oldingi toifalar'));
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.tap(find.text('Barchasi').hitTestable());
    await tester.pump();
    expect(selected, isNull);
    await tester.tap(find.text('Gaz ballon').hitTestable());
    await tester.pump();
    expect(selected, ServiceCategory.gazBallon);
    expect(find.textContaining('· 0'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all service tiles are contained and tappable with large text',
      (tester) async {
    addTearDown(tester.view.reset);
    ServiceCategory? tapped;
    await host(
        tester,
        Scaffold(
            body: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(20),
              child:
                  ServiceCategoryGrid(onSelected: (value) => tapped = value)),
        )),
        width: 320,
        scale: 1.25);
    for (final category in ServiceCategory.values) {
      final tile = find.text(category.titleUz);
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pump();
      expect(tapped, category);
      final rect = tester.getRect(tile);
      expect(rect.left, greaterThanOrEqualTo(20));
      expect(rect.right, lessThanOrEqualTo(300));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('artwork animates and respects reduced motion', (tester) async {
    addTearDown(tester.view.reset);
    const artwork = Scaffold(
        body: Center(
            child: CategoryArtwork(
                category: ServiceCategory.gazBallon, animate: true)));
    await host(tester, artwork, reduceMotion: false);
    Matrix4 transform() => tester
        .widget<Transform>(find
            .descendant(
                of: find.byType(CategoryArtwork),
                matching: find.byType(Transform))
            .first)
        .transform;
    final first = transform().clone();
    await tester.pump(const Duration(milliseconds: 750));
    expect(transform(), isNot(first));
    await host(tester, artwork, reduceMotion: true);
    final stopped = transform().clone();
    await tester.pump(const Duration(milliseconds: 750));
    expect(transform(), stopped);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark home and catalog render', (tester) async {
    addTearDown(tester.view.reset);
    await host(tester, const HomePage(), dark: true);
    expect(tester.takeException(), isNull);
    await capture(tester, 'home-dark');
    await host(tester, const CatalogPage(), dark: true);
    expect(tester.takeException(), isNull);
    await capture(tester, 'catalog-dark');
  });
}
