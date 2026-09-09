import 'package:flutter/animation.dart';

/// Shared timing so every transition in the app feels like it came from
/// the same hand — short, springy, never bouncy-cartoonish.
class AppMotion {
  AppMotion._();

  static const Duration instant = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 360);
  static const Duration slower = Duration(milliseconds: 520);
  static const Duration page = Duration(milliseconds: 320);

  /// Default easing: quick start, long settle (iOS-like).
  static const Curve standard = Cubic(0.22, 0.61, 0.36, 1);

  /// For elements entering the screen.
  static const Curve enter = Cubic(0.16, 1, 0.3, 1);

  /// For elements leaving.
  static const Curve exit = Cubic(0.4, 0, 1, 1);

  /// Slight overshoot for badges / success ticks.
  static const Curve spring = Cubic(0.34, 1.42, 0.64, 1);

  /// Staggered list entrance delay per item.
  static Duration stagger(int index, {int stepMs = 55, int maxMs = 400}) =>
      Duration(milliseconds: (index * stepMs).clamp(0, maxMs));
}
