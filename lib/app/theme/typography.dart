import 'package:flutter/material.dart';

/// Type scale modelled on the iOS (SF Pro) ramp so the app reads like a
/// native premium marketplace rather than a Material template.
///
/// Styles here carry **no colour** — colour comes from the theme's
/// `textTheme` or from `context.palette` at the call site, so the same
/// style works in light and dark mode.
class AppTypography {
  AppTypography._();

  /// `null` = the platform system face: SF Pro on iOS, Roboto on Android.
  /// Set this to a bundled family name to swap typography app-wide.
  static const String? fontFamily = null;

  // ── Display / titles ───────────────────────────────────────────────
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1.12,
    letterSpacing: -0.9,
  );

  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.16,
    letterSpacing: -0.7,
  );

  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.22,
    letterSpacing: -0.45,
  );

  static const TextStyle title3 = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    height: 1.26,
    letterSpacing: -0.35,
  );

  // ── Body ───────────────────────────────────────────────────────────
  static const TextStyle headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.3,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: -0.2,
  );

  static const TextStyle callout = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: -0.2,
  );

  static const TextStyle subhead = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: -0.1,
  );

  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.38,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.32,
  );

  static const TextStyle caption2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.28,
    letterSpacing: 0.1,
  );

  /// ALL-CAPS section label ("XIZMAT TURI", "AHOLI UCHUN").
  static const TextStyle overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.9,
  );

  // ── Numerals: tabular so prices line up in columns ──────────────────
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static const TextStyle price = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.4,
    fontFeatures: _tabular,
  );

  static const TextStyle priceLarge = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.8,
    fontFeatures: _tabular,
  );

  static const TextStyle priceSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.2,
    fontFeatures: _tabular,
  );

  static const TextStyle numeric = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    fontFeatures: _tabular,
  );

  static const TextStyle button = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.1,
  );

  // ── Aliases used by the Material TextTheme mapping ──────────────────
  static const TextStyle displayLarge = largeTitle;
  static const TextStyle h1 = title1;
  static const TextStyle h2 = title2;
  static const TextStyle h3 = title3;
  static const TextStyle bodyLarge = body;
  static const TextStyle bodyMedium = subhead;
  static const TextStyle bodySmall = footnote;
}
