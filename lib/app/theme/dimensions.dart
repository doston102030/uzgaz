import 'package:flutter/widgets.dart';

/// Spacing, radius and sizing tokens. Every screen shares this rhythm
/// (4pt base grid) so the app feels like one designed product.
class AppDimensions {
  AppDimensions._();

  // ── Spacing ────────────────────────────────────────────────────────
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space14 = 14;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space28 = 28;
  static const double space32 = 32;
  static const double space40 = 40;
  static const double space48 = 48;
  static const double space64 = 64;

  /// Horizontal page gutter — the single value that sets the app's margin.
  static const double gutter = 20;

  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: gutter);

  // ── Radius ─────────────────────────────────────────────────────────
  static const double radiusXSmall = 10;
  static const double radiusSmall = 14;
  static const double radiusMedium = 18;
  static const double radiusLarge = 22;
  static const double radiusXLarge = 28;
  static const double radiusSheet = 32;
  static const double radiusPill = 999;

  static const BorderRadius brSmall =
      BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius brMedium =
      BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius brLarge =
      BorderRadius.all(Radius.circular(radiusLarge));
  static const BorderRadius brXLarge =
      BorderRadius.all(Radius.circular(radiusXLarge));
  static const BorderRadius brPill =
      BorderRadius.all(Radius.circular(radiusPill));

  // ── Components ─────────────────────────────────────────────────────
  static const double buttonHeight = 54;
  static const double buttonHeightSmall = 42;
  static const double inputHeight = 54;
  static const double navBarHeight = 52;
  static const double bottomNavHeight = 62;
  static const double iconSize = 22;
  static const double iconSizeSmall = 18;
  static const double iconSizeLarge = 26;
  static const double avatarSize = 44;
  static const double avatarSizeLarge = 68;
  static const double chipHeight = 36;
  static const double touchTargetMin = 44;
  static const double productImageHeight = 108;
  static const double heroImageHeight = 300;

  /// Extra bottom padding so content clears the floating tab bar.
  static const double bottomBarClearance = 96;

  // ── Responsive (desktop/web) ───────────────────────────────────────
  /// Above this window width, [ResponsiveFrame] stops stretching the
  /// mobile-designed shell full-bleed and clamps it to [maxContentWidth]
  /// instead — this app has no separate desktop layout, so a wide
  /// browser/window tab otherwise reads as a stretched phone screen.
  static const double breakpointDesktop = 900;

  /// The column width the app is designed at; also this app's largest
  /// phone target (a big-screen phone in landscape stays full-bleed).
  static const double maxContentWidth = 480;
}
