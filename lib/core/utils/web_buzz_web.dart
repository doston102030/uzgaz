import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// One short buzz from a web page.
///
/// * **Android browsers** have the Vibration API — `navigator.vibrate(ms)`.
/// * **iPhone Safari** has no Vibration API at all, so Flutter's
///   `HapticFeedback` does nothing there. Since iOS 18, though, toggling an
///   `<input type="checkbox" switch>` plays the system's light haptic tick,
///   and it does so even for a hidden switch clicked from script while a
///   real tap is being handled. That is the only buzz a page can get on an
///   iPhone, so [ios] uses it. Older iOS versions simply stay silent.
/// * Desktops have no motor; nothing happens.
///
/// Must run inside the tap's own event (Flutter web delivers `onTap`
/// synchronously from the browser's pointer event, so it does).
void webBuzz(int milliseconds, {required bool ios}) {
  try {
    final navigator = globalContext.getProperty<JSObject>('navigator'.toJS);
    if (navigator.has('vibrate')) {
      navigator.callMethod<JSAny?>('vibrate'.toJS, milliseconds.toJS);
      return;
    }
    if (ios) _switchTick();
  } catch (_) {
    // A haptic is a nicety — never let it break the tap that asked for it.
  }
}

void _switchTick() {
  final document = globalContext.getProperty<JSObject>('document'.toJS);
  JSObject create(String tag) =>
      document.callMethod<JSObject>('createElement'.toJS, tag.toJS);

  final label = create('label')..setProperty('ariaHidden'.toJS, 'true'.toJS);
  label
      .getProperty<JSObject>('style'.toJS)
      .setProperty('display'.toJS, 'none'.toJS);
  final input = create('input')..setProperty('type'.toJS, 'checkbox'.toJS);
  input.callMethod<JSAny?>('setAttribute'.toJS, 'switch'.toJS, ''.toJS);
  label.callMethod<JSAny?>('appendChild'.toJS, input);

  final head = document.getProperty<JSObject>('head'.toJS);
  head.callMethod<JSAny?>('appendChild'.toJS, label);
  label.callMethod<JSAny?>('click'.toJS);
  head.callMethod<JSAny?>('removeChild'.toJS, label);
}
