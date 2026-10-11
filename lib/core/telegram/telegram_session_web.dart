import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// The key and JSON shape Telegram's own `telegram-web-app.js` uses
/// (`'__telegram__' + 'initParams'`), and that `web/index.html` writes —
/// so the SDK, if it is ever added, finds the same launch.
const _key = '__telegram__initParams';

Map<String, String>? readStoredLaunchParams() {
  try {
    final raw =
        _storage().callMethod<JSString?>('getItem'.toJS, _key.toJS)?.toDart;
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return {
      for (final entry in decoded.entries)
        if (entry.value != null) '${entry.key}': '${entry.value}',
    };
  } catch (_) {
    // No storage (a sandboxed frame) or a mangled value: no launch.
    return null;
  }
}

void storeLaunchParams(Map<String, String> params) {
  try {
    _storage()
        .callMethod<JSAny?>('setItem'.toJS, _key.toJS, jsonEncode(params).toJS);
  } catch (_) {
    // Storage full or blocked: the launch still lives for this page load.
  }
}

JSObject _storage() =>
    globalContext.getProperty<JSObject>('sessionStorage'.toJS);
