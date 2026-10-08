import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The one place that decides how a touch *feels*. Every tappable in the
/// app (via `AppTappable`, the tab bar, switches, sheets…) goes through
/// here, so each press gives a clear, consistent buzz.
///
/// Why not just `HapticFeedback.selectionClick()` everywhere:
/// * **Web** (the app also runs in the browser): Flutter turns haptics into
///   `navigator.vibrate(ms)` — selection/light = 10 ms, which most Android
///   phone motors barely render. Medium = 20 ms is the lightest that is
///   reliably felt. (iOS Safari and desktops have no vibration API at
///   all, so nothing happens there whatever we call.)
/// * **Android app**: `selectionClick` maps to `CLOCK_TICK`, which many
///   devices ignore; `lightImpact` maps to `VIRTUAL_KEY`, which they don't.
/// * **iOS app**: the native generators are crisp at every level, so the
///   semantic ones (selection, light, medium) are kept.
class AppHaptics {
  AppHaptics._();

  static bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Any button, card, chip or icon press.
  static void tap() {
    if (kIsWeb) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  /// Picking between options: tabs, segments, switches, sheet choices.
  static void selection() {
    if (kIsWeb) {
      HapticFeedback.mediumImpact();
    } else if (_isIOS) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  /// Long press, swipe-to-delete, a confirmation dialog opening.
  static void emphasis() {
    if (kIsWeb) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  /// A finished flow worth celebrating (order placed).
  static void success() => HapticFeedback.heavyImpact();
}
