// Where Telegram's launch params are kept between page loads. Only the web
// build has a session to keep them in; native builds get the no-op stub.
export 'telegram_session_stub.dart'
    if (dart.library.js_interop) 'telegram_session_web.dart';
