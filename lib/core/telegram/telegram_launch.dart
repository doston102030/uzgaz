import 'package:flutter/foundation.dart';

import 'telegram_session.dart';

/// What Telegram handed the page when it opened it as a Mini App.
///
/// Telegram opens a Mini App's URL with its launch data in the fragment:
///
///     https://…/#tgWebAppData=…&tgWebAppVersion=8.0&tgWebAppPlatform=ios&…
///
/// or `#/some/path?tgWebAppData=…` when the link already had a path. With
/// hash routing that fragment *is* the route, so GoRouter used to fail with
/// "no routes for location: tgWebAppData=…".
///
/// `web/index.html` lifts these params out of the URL before Flutter starts
/// and keeps them in sessionStorage — under the key and in the shape
/// Telegram's own `telegram-web-app.js` uses, so they survive reloads and
/// in-app navigation. [current] reads them back; [redirect] is the router's
/// safety net for a location that still carries them.
class TelegramLaunch {
  const TelegramLaunch(this.params);

  /// Every `tgWebApp…` launch param, decoded.
  final Map<String, String> params;

  /// The signed init data (`query_id`, `user`, `auth_date`, `hash`…): what
  /// a backend verifies to sign the user in with their Telegram account.
  String? get initData => params['tgWebAppData'];
  String? get version => params['tgWebAppVersion'];
  String? get platform => params['tgWebAppPlatform'];
  String? get themeParams => params['tgWebAppThemeParams'];
  String? get startParam => params['tgWebAppStartParam'];

  static const _prefix = 'tgWebApp';

  static TelegramLaunch? _current;
  static bool _loaded = false;

  /// This session's launch, or null when Telegram did not open the app.
  static TelegramLaunch? get current {
    if (!_loaded) {
      _loaded = true;
      // Fresh params from the URL win over stored ones, as in Telegram's SDK.
      final params = {
        ...?readStoredLaunchParams(),
        ...split(PlatformDispatcher.instance.defaultRouteName).params,
      };
      if (params.isNotEmpty) _current = TelegramLaunch(params);
    }
    return _current;
  }

  /// Top-level router redirect. A location carrying Telegram's launch
  /// params becomes the page it was meant for — its own path if it had
  /// one, otherwise [home] — and the params are kept for [current].
  /// Any other location is left alone (null).
  static String? redirect(Uri uri, {required String home}) {
    final location = uri.toString();
    if (!location.contains(_prefix)) return null;
    final parts = split(location);
    if (parts.params.isEmpty) return null;
    _remember(parts.params);
    final path =
        parts.path.startsWith('/') && parts.path != '/' ? parts.path : home;
    return parts.rest.isEmpty ? path : '$path?${parts.rest}';
  }

  /// Splits a location (a URL fragment) into its path, its Telegram launch
  /// params and whatever other query it had. Parsing follows
  /// `telegram-web-app.js`: `path?query`, or a bare `query` when there is
  /// no `?` but there is an `=`. A location without Telegram params comes
  /// back whole as the path.
  @visibleForTesting
  static ({String path, Map<String, String> params, String rest}) split(
      String location) {
    var path = '';
    var query = location;
    final q = location.indexOf('?');
    if (q >= 0) {
      path = location.substring(0, q);
      query = location.substring(q + 1);
    } else if (!location.contains('=')) {
      return (path: location, params: const {}, rest: '');
    }

    final params = <String, String>{};
    final rest = <String>[];
    for (final pair in query.split('&')) {
      if (pair.isEmpty) continue;
      final i = pair.indexOf('=');
      final key = _decode(i < 0 ? pair : pair.substring(0, i));
      if (key.startsWith(_prefix)) {
        params[key] = i < 0 ? '' : _decode(pair.substring(i + 1));
      } else {
        rest.add(pair);
      }
    }
    if (params.isEmpty) return (path: location, params: const {}, rest: '');
    return (path: path, params: params, rest: rest.join('&'));
  }

  static void _remember(Map<String, String> params) {
    final merged = {...?current?.params, ...params};
    _current = TelegramLaunch(merged);
    storeLaunchParams(merged);
  }

  /// Telegram's `urlSafeDecode`: `+` is a space, then percent-decoding.
  static String _decode(String value) {
    try {
      return Uri.decodeComponent(value.replaceAll('+', '%20'));
    } on ArgumentError {
      return value;
    }
  }

  @visibleForTesting
  static void debugReset() {
    _current = null;
    _loaded = false;
  }
}
