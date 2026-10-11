// The browser half of `AppHaptics`. Native builds get the no-op stub.
export 'web_buzz_stub.dart' if (dart.library.js_interop) 'web_buzz_web.dart';
