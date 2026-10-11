import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gaz_energiya/app/app.dart';
import 'package:gaz_energiya/app/router/app_router.dart';
import 'package:gaz_energiya/core/telegram/telegram_launch.dart';
import 'package:gaz_energiya/features/home/presentation/pages/home_page.dart';

/// The signed init data exactly as Telegram builds it: the `user` JSON is
/// percent-encoded inside it…
const _initData = 'query_id=AAHdF6IQAAAAAN0XohDhrOrc'
    '&user=%7B%22id%22%3A279058397%2C%22first_name%22%3A%22Doston%22%2C'
    '%22language_code%22%3A%22uz%22%7D'
    '&auth_date=1760000000'
    '&hash=c501b71e775f74ce10e377dea85a7ea24ecd640b223ea86dfe453e0eaed2e2b2';

/// …and then the whole of it is percent-encoded again into the fragment.
final _fragment = 'tgWebAppData=${Uri.encodeComponent(_initData)}'
    '&tgWebAppVersion=8.0'
    '&tgWebAppPlatform=ios'
    '&tgWebAppThemeParams=${Uri.encodeComponent('{"bg_color":"#ffffff"}')}';

void main() {
  setUp(TelegramLaunch.debugReset);

  group('split', () {
    test('a bare Telegram fragment has no path, only params', () {
      final parts = TelegramLaunch.split(_fragment);
      expect(parts.path, '');
      expect(parts.rest, '');
      expect(parts.params['tgWebAppData'], _initData);
      expect(parts.params['tgWebAppVersion'], '8.0');
      expect(parts.params['tgWebAppPlatform'], 'ios');
      expect(parts.params['tgWebAppThemeParams'], '{"bg_color":"#ffffff"}');
    });

    test('a path keeps its own query; Telegram params come out', () {
      final parts = TelegramLaunch.split('/catalog?sort=price&$_fragment');
      expect(parts.path, '/catalog');
      expect(parts.rest, 'sort=price');
      expect(parts.params['tgWebAppData'], _initData);
    });

    test('ordinary locations pass through whole', () {
      for (final location in ['/', '/home', '/product/42', '/orders?x=1']) {
        final parts = TelegramLaunch.split(location);
        expect(parts.path, location);
        expect(parts.params, isEmpty);
      }
    });
  });

  group('redirect', () {
    test('a bare Telegram fragment goes home and is remembered', () {
      expect(TelegramLaunch.redirect(Uri.parse(_fragment), home: '/home'),
          '/home');
      expect(TelegramLaunch.current?.initData, _initData);
      expect(TelegramLaunch.current?.platform, 'ios');
    });

    test('a Telegram link to a page opens that page', () {
      expect(
        TelegramLaunch.redirect(
            Uri.parse('/catalog?sort=price&$_fragment'), home: '/home'),
        '/catalog?sort=price',
      );
      expect(
        TelegramLaunch.redirect(Uri.parse('/orders?$_fragment'), home: '/home'),
        '/orders',
      );
    });

    test('ordinary locations are left alone', () {
      for (final location in ['/', '/splash', '/home', '/product/42?q=1']) {
        expect(TelegramLaunch.redirect(Uri.parse(location), home: '/home'),
            isNull);
      }
      expect(TelegramLaunch.current, isNull);
    });
  });

  testWidgets(
      'Opened by Telegram, the real app lands on the home page — '
      'no "no routes for location" error', (tester) async {
    // What hash routing hands Flutter when Telegram opens the Mini App
    // and nothing in index.html cleaned the URL first.
    tester.binding.platformDispatcher.defaultRouteNameTestValue = _fragment;
    addTearDown(
        tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: GazEnergiyaApp()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(appRouter.routeInformationProvider.value.uri.path, '/home');
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.textContaining('GoException'), findsNothing);
    expect(find.textContaining('no routes for location'), findsNothing);

    final launch = TelegramLaunch.current!;
    expect(launch.initData, _initData);
    expect(launch.version, '8.0');
    expect(launch.platform, 'ios');

    // Unmount so the app's own timers and listeners wind down.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
