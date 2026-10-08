import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:gaz_energiya/app/theme/app_theme.dart';
import 'package:gaz_energiya/features/auth/presentation/pages/onboarding_page.dart';
import 'package:gaz_energiya/features/auth/presentation/widgets/onboarding_film.dart';
import 'package:gaz_energiya/features/auth/presentation/widgets/onboarding_film_art.dart';

const _loginDestination = 'Kirish sahifasi (test)';

/// A line of text that only its own scene shows.
const _markers = [
  '01 / SAVOL',
  '02 / TAVSIYA',
  '03 / BUYURTMA',
  '04 / YO‘LDA',
  '05 / YETKAZILDI',
  'GAZ BALLONI\nBUYURTMASI',
];

Future<GoRouter> _pumpOnboarding(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  bool reduceMotion = false,
  ThemeMode themeMode = ThemeMode.light,
  EdgeInsets safeInsets = EdgeInsets.zero,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const Scaffold(
          body: Center(child: Text(_loginDestination)),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduceMotion,
          textScaler: TextScaler.linear(textScale),
          padding: safeInsets,
          viewPadding: safeInsets,
        ),
        child: child!,
      ),
    ),
  );
  // The film clock takes its first tick on this frame: t = 0.
  await tester.pump();
  return router;
}

void _expectScene(WidgetTester tester, int scene) {
  final shown = [
    for (var i = 0; i < _markers.length; i++)
      if (find.text(_markers[i]).evaluate().isNotEmpty) i,
  ];
  expect(shown, [scene], reason: 'exactly scene ${scene + 1} is on screen');
  expect(
    find.text(scene == 5 ? 'Boshlash' : 'Davom etish').hitTestable(),
    findsOneWidget,
  );
  expect(tester.takeException(), isNull,
      reason: 'scene ${scene + 1} must render cleanly');
}

/// Product of every [Opacity] above [finder] — 1 means fully shown.
double _opacityOf(WidgetTester tester, Finder finder) {
  var opacity = 1.0;
  for (final widget in tester.widgetList<Opacity>(
      find.ancestor(of: finder, matching: find.byType(Opacity)))) {
    opacity *= widget.opacity;
  }
  return opacity;
}

/// Checks [scene] early, mid-way and late in its entrances. A step lands
/// on the next frame and the film clock restarts there, so pump that first.
Future<void> _walkScene(WidgetTester tester, int scene) async {
  await tester.pump();
  for (final ms in [300, 600, 1200]) {
    await tester.pump(Duration(milliseconds: ms));
    _expectScene(tester, scene);
  }
}

void _expectLogin(GoRouter router) {
  expect(router.routeInformationProvider.value.uri.path, '/login');
  expect(find.text(_loginDestination), findsOneWidget);
  expect(find.byType(OnboardingPage), findsNothing);
}

void _expectTapTarget(WidgetTester tester, Finder target, Rect safeViewport) {
  expect(target.hitTestable(), findsOneWidget);
  final bounds = tester.getRect(target);
  expect(bounds.width, greaterThanOrEqualTo(48));
  expect(bounds.height, greaterThanOrEqualTo(48));
  expect(bounds.left, greaterThanOrEqualTo(safeViewport.left));
  expect(bounds.top, greaterThanOrEqualTo(safeViewport.top));
  expect(bounds.right, lessThanOrEqualTo(safeViewport.right));
  expect(bounds.bottom, lessThanOrEqualTo(safeViewport.bottom));
}

void _expectLayout(
  WidgetTester tester,
  Size size,
  int scene, {
  EdgeInsets safeInsets = EdgeInsets.zero,
}) {
  final safeViewport = Rect.fromLTRB(
    safeInsets.left,
    safeInsets.top,
    size.width - safeInsets.right,
    size.height - safeInsets.bottom,
  );
  final film = tester.getRect(find.byType(OnboardingFilm));
  // The film always scales to fit entirely inside the safe viewport, at
  // its 9:16 ratio — never cropped, never scrolled. A short or narrow
  // window letterboxes it instead of running it past the edge.
  expect(film.left, greaterThanOrEqualTo(safeViewport.left - .01));
  expect(film.top, greaterThanOrEqualTo(safeViewport.top - .01));
  expect(film.right, lessThanOrEqualTo(safeViewport.right + .01));
  expect(film.bottom, lessThanOrEqualTo(safeViewport.bottom + .01));

  _expectTapTarget(
    tester,
    find.ancestor(
      of: find.text(scene == 5 ? 'Boshlash' : 'Davom etish'),
      matching: find.byType(FilledButton),
    ),
    safeViewport,
  );
  _expectTapTarget(tester, find.byTooltip('Oldingi sahna'), safeViewport);
  if (scene < 5) {
    _expectTapTarget(
      tester,
      find.ancestor(
        of: find.text('O‘tkazib yuborish'),
        matching: find.byType(TextButton),
      ),
      safeViewport,
    );
  }
  expect(tester.takeException(), isNull);
}

void main() {
  test('The film keeps the creative’s exact 25-second edit', () {
    expect(FilmTimeline.durations, [2500, 4000, 5500, 4500, 4500, 4000]);
    expect(FilmTimeline.total, 25000);
    expect(FilmTimeline.durations.reduce((a, b) => a + b), FilmTimeline.total);

    var start = 0;
    for (var i = 0; i < FilmTimeline.sceneCount; i++) {
      expect(FilmTimeline.starts[i], start);
      expect(FilmTimeline.sceneAt(start.toDouble()), i);
      if (i > 0) expect(FilmTimeline.sceneAt(start - .5), i - 1);
      expect(FilmTimeline.sceneAt(FilmTimeline.settled(i)), i);
      start += FilmTimeline.durations[i];
    }
    expect(FilmTimeline.sceneAt(FilmTimeline.total.toDouble()), 5);

    // Story bars run back to back from the first frame to the last.
    expect(FilmTimeline.chapters.first.$1, 0);
    expect(FilmTimeline.chapters.last.$2, FilmTimeline.total);
    for (var i = 1; i < FilmTimeline.chapters.length; i++) {
      expect(FilmTimeline.chapters[i].$1, FilmTimeline.chapters[i - 1].$2);
    }
    expect(FilmTimeline.descriptions, hasLength(FilmTimeline.sceneCount));
  });

  testWidgets(
      'Autoplays all six scenes on time and stops on the call to action',
      (tester) async {
    await _pumpOnboarding(tester);
    _expectScene(tester, 0);

    var elapsed = 0;
    Future<void> advanceTo(int ms) async {
      await tester.pump(Duration(milliseconds: ms - elapsed));
      elapsed = ms;
    }

    for (var i = 1; i < FilmTimeline.sceneCount; i++) {
      await advanceTo(FilmTimeline.starts[i] - 20);
      _expectScene(tester, i - 1);
      await advanceTo(FilmTimeline.starts[i] + 20);
      _expectScene(tester, i);
    }

    await advanceTo(FilmTimeline.total + 500);
    await tester.pump();
    _expectScene(tester, 5);
    expect(find.byTooltip('Boshidan ko‘rish'), findsNothing);
    expect(tester.binding.transientCallbackCount, 0,
        reason: 'the clock stops on the last frame');
  });

  for (final size in [const Size(320, 568), const Size(390, 844)]) {
    testWidgets('Every frame of the 25 s film renders cleanly at $size',
        (tester) async {
      await _pumpOnboarding(tester, size: size);
      for (var ms = 100; ms <= FilmTimeline.total; ms += 100) {
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull, reason: 'at $ms ms');
      }
    });
  }

  testWidgets('Next, swipe, back and Boshlash move through the scenes',
      (tester) async {
    final router = await _pumpOnboarding(tester);
    _expectScene(tester, 0);
    expect(tester.widget<IconButton>(find.byType(IconButton).first).onPressed,
        isNull,
        reason: 'nothing before the first scene');

    await tester.tap(find.text('Davom etish'));
    await tester.pump(const Duration(milliseconds: 100));
    _expectScene(tester, 1);

    await tester.drag(find.byType(OnboardingFilm), const Offset(-200, 0));
    await tester.pump(const Duration(milliseconds: 100));
    _expectScene(tester, 2);

    await tester.tap(find.byTooltip('Oldingi sahna'));
    await tester.pump(const Duration(milliseconds: 100));
    _expectScene(tester, 1);

    await tester.drag(find.byType(OnboardingFilm), const Offset(200, 0));
    await tester.pump(const Duration(milliseconds: 100));
    _expectScene(tester, 0);

    // A short drag is not a swipe.
    await tester.dragFrom(
        tester.getCenter(find.byType(OnboardingFilm)), const Offset(-30, 0));
    await tester.pump(const Duration(milliseconds: 100));
    _expectScene(tester, 0);

    for (var scene = 1; scene <= 5; scene++) {
      await tester.tap(find.text('Davom etish'));
      await tester.pump(const Duration(milliseconds: 100));
      _expectScene(tester, scene);
    }

    // Swiping past the last scene stays there; only Boshlash leaves.
    await tester.drag(find.byType(OnboardingFilm), const Offset(-200, 0));
    await tester.pump(const Duration(milliseconds: 100));
    _expectScene(tester, 5);

    await tester.tap(find.text('Boshlash'));
    await tester.pumpAndSettle();
    _expectLogin(router);
  });

  testWidgets('O‘tkazib yuborish opens the login route directly',
      (tester) async {
    final router = await _pumpOnboarding(tester);
    await tester.tap(find.text('O‘tkazib yuborish'));
    await tester.pumpAndSettle();
    _expectLogin(router);
  });

  testWidgets('Film pauses in the background and resumes on return',
      (tester) async {
    await _pumpOnboarding(tester);
    await tester.pump(const Duration(milliseconds: 500));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 10));
    _expectScene(tester, 0);
    expect(tester.binding.transientCallbackCount, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2500));
    _expectScene(tester, 1);
  });

  testWidgets('Arrow keys step between scenes', (tester) async {
    await _pumpOnboarding(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 100));
    _expectScene(tester, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump(const Duration(milliseconds: 100));
    _expectScene(tester, 0);
  });

  testWidgets('Reduced motion: six still frames, nothing animates',
      (tester) async {
    final router = await _pumpOnboarding(tester, reduceMotion: true);
    expect(find.byTooltip('Animatsiyani to‘xtatish'), findsNothing);

    for (var scene = 0; scene <= 5; scene++) {
      // One frame for the step itself (it may enable the back button,
      // whose colour fades for 200 ms), then a long wait: the film itself
      // must not schedule a single further frame.
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      _expectScene(tester, scene);
      expect(tester.binding.transientCallbackCount, 0,
          reason: 'scene ${scene + 1}');
      expect(_opacityOf(tester, find.text(_markers[scene])), 1,
          reason: 'every element is already in place');
      if (scene == 2) {
        // A still frame shows the order screen, not the overlay hiding it.
        expect(find.text('Buyurtma\nqabul qilindi!'), findsNothing);
        expect(find.text('Buyurtma berish'), findsOneWidget);
      }
      if (scene < 5) await tester.tap(find.text('Davom etish'));
    }

    await tester.tap(find.text('Boshlash'));
    await tester.pumpAndSettle();
    _expectLogin(router);
  });

  const sizes = {
    'small phone': Size(320, 568),
    'phone': Size(390, 844),
    'reported browser viewport': Size(575, 680),
    'landscape phone': Size(844, 390),
    'tablet': Size(820, 1180),
  };

  for (final entry in sizes.entries) {
    for (final textScale in [1.0, 2.0]) {
      testWidgets('Every scene fits a ${entry.key} with ${textScale}x text',
          (tester) async {
        await _pumpOnboarding(tester, size: entry.value, textScale: textScale);

        for (var scene = 0; scene <= 5; scene++) {
          await _walkScene(tester, scene);
          _expectLayout(tester, entry.value, scene);
          expect(find.byTooltip('Animatsiyani to‘xtatish'), findsNothing);
          if (scene < 5) {
            await tester.tap(find.text('Davom etish'));
          }
        }
      });
    }
  }

  for (final (size, insets) in [
    (const Size(390, 844), const EdgeInsets.only(top: 44, bottom: 34)),
    (const Size(844, 390), const EdgeInsets.fromLTRB(44, 0, 44, 21)),
  ]) {
    testWidgets('All scenes and controls respect safe areas at $size',
        (tester) async {
      final router = await _pumpOnboarding(
        tester,
        size: size,
        safeInsets: insets,
        reduceMotion: true,
        textScale: 2,
      );
      for (var scene = 0; scene <= 5; scene++) {
        await tester.pumpAndSettle();
        _expectScene(tester, scene);
        _expectLayout(tester, size, scene, safeInsets: insets);
        if (scene < 5) await tester.tap(find.text('Davom etish'));
      }
      await tester.tap(find.text('Boshlash'));
      await tester.pumpAndSettle();
      _expectLogin(router);
    });
  }

  testWidgets('The film keeps its own palette in the dark theme',
      (tester) async {
    await _pumpOnboarding(tester, themeMode: ThemeMode.dark);
    for (var scene = 0; scene <= 5; scene++) {
      await _walkScene(tester, scene);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor,
          FilmTimeline.isDark(scene) ? filmInk : filmPaper);
      if (scene < 5) await tester.tap(find.text('Davom etish'));
    }
  });

  testWidgets('Screen readers hear each scene from first to last',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpOnboarding(tester);
    expect(find.bySemanticsLabel(RegExp(r'1-sahna, jami 6 ta\. GAZ KERAKMI\?')),
        findsOneWidget);

    await tester.pump(const Duration(seconds: 26));
    expect(find.bySemanticsLabel(RegExp(r'6-sahna, jami 6 ta\. Oson buyurtma')),
        findsOneWidget);
    semantics.dispose();
  });
}
