import 'package:flutter/material.dart';

/// Raw brand constants. Screens should almost never read these directly —
/// they read [AppPalette] through `context.palette`, which resolves the
/// right value for light *and* dark mode.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryDeep = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryTint = Color(0xFF93C5FD);
  static const Color darkNavy = Color(0xFF0F172A);

  // ── Energy accents (one per service category) ──────────────────────
  static const Color energyFlame = Color(0xFFF97316); // gaz / propan
  static const Color energyAmber = Color(0xFFF59E0B); // benzin
  static const Color energyElectric = Color(0xFF8B5CF6); // elektr
  static const Color energyMint = Color(0xFF10B981); // metan
  static const Color energySlate = Color(0xFF475569); // dizel
  static const Color energyRose = Color(0xFFE11D48); // market / aksiya
  static const Color energyGreen = Color(0xFF22C55E); // suyultirilgan gaz — aholi subsidiyasi

  // ── Status ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);
  static const Color star = Color(0xFFFBBF24);

  // ── Neutrals (slate ramp) ──────────────────────────────────────────
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color white = Color(0xFFFFFFFF);

  // Dark-mode canvas (blue-black, like iOS dark on OLED)
  static const Color inkBackground = Color(0xFF080C14);
  static const Color inkSurface = Color(0xFF121A28);
  static const Color inkElevated = Color(0xFF1B2536);
  static const Color inkBorder = Color(0xFF283349);

  // Legacy aliases kept so older call sites keep compiling.
  static const Color background = slate50;
  static const Color surfaceDark = inkSurface;
  static const Color backgroundDark = inkBackground;
  static const Color textPrimary = slate900;
  static const Color textSecondary = slate500;
  static const Color textMuted = slate400;
  static const Color textOnPrimary = white;
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = slate400;
  static const Color border = slate200;
  static const Color borderDark = inkBorder;
  static const Color gasBlue = primary;
  static const Color gasRed = error;
  static const Color gasGray = slate400;

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB), Color(0xFF1D4ED8)],
    stops: [0, 0.55, 1],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B1526), Color(0xFF14306B), Color(0xFF1D4ED8)],
    stops: [0, 0.6, 1],
  );

  static const LinearGradient flameGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFB923C), Color(0xFFF97316)],
  );
}

/// Every colour a screen is allowed to use, resolved per brightness.
///
/// Read it with `context.palette` (see [PaletteX]) so light and dark mode
/// stay in sync automatically — no `Theme.of(context).brightness` checks
/// scattered through the widget tree.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.backgroundSunken,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceMuted,
    required this.border,
    required this.borderStrong,
    required this.separator,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textInverse,
    required this.primary,
    required this.primaryPressed,
    required this.primarySoft,
    required this.onPrimary,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.info,
    required this.infoSoft,
    required this.star,
    required this.scrim,
    required this.shadowSm,
    required this.shadowMd,
    required this.shadowLg,
    required this.brandGradient,
  });

  final Brightness brightness;

  final Color background;
  final Color backgroundSunken;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceMuted;

  final Color border;
  final Color borderStrong;
  final Color separator;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textInverse;

  final Color primary;
  final Color primaryPressed;
  final Color primarySoft;
  final Color onPrimary;

  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color info;
  final Color infoSoft;
  final Color star;

  final Color scrim;

  final List<BoxShadow> shadowSm;
  final List<BoxShadow> shadowMd;
  final List<BoxShadow> shadowLg;

  final LinearGradient brandGradient;

  bool get isDark => brightness == Brightness.dark;

  /// Soft tinted background for a coloured icon chip / badge.
  Color tint(Color color, [double alpha = 0.12]) =>
      color.withValues(alpha: isDark ? alpha + 0.08 : alpha);

  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF6F8FC),
    backgroundSunken: Color(0xFFEEF2F8),
    surface: AppColors.white,
    surfaceElevated: AppColors.white,
    surfaceMuted: Color(0xFFF1F5F9),
    border: Color(0xFFE6EAF2),
    borderStrong: Color(0xFFD6DDEA),
    separator: Color(0xFFEDF1F7),
    textPrimary: Color(0xFF0B1526),
    textSecondary: Color(0xFF5A6B85),
    textTertiary: Color(0xFF94A3B8),
    textInverse: AppColors.white,
    primary: AppColors.primary,
    primaryPressed: AppColors.primaryDark,
    primarySoft: Color(0xFFEAF1FE),
    onPrimary: AppColors.white,
    success: AppColors.success,
    successSoft: Color(0xFFE7F7EE),
    warning: Color(0xFFD97706),
    warningSoft: Color(0xFFFEF3E2),
    danger: AppColors.error,
    dangerSoft: Color(0xFFFDECEC),
    info: Color(0xFF0284C7),
    infoSoft: Color(0xFFE4F4FD),
    star: AppColors.star,
    scrim: Color(0x660B1526),
    shadowSm: [
      BoxShadow(color: Color(0x0A0B1526), blurRadius: 8, offset: Offset(0, 2)),
      BoxShadow(color: Color(0x080B1526), blurRadius: 2, offset: Offset(0, 1)),
    ],
    shadowMd: [
      BoxShadow(color: Color(0x120B1526), blurRadius: 20, offset: Offset(0, 8)),
      BoxShadow(color: Color(0x080B1526), blurRadius: 4, offset: Offset(0, 1)),
    ],
    shadowLg: [
      BoxShadow(color: Color(0x1A0B1526), blurRadius: 36, offset: Offset(0, 16)),
      BoxShadow(color: Color(0x0D0B1526), blurRadius: 8, offset: Offset(0, 2)),
    ],
    brandGradient: AppColors.primaryGradient,
  );

  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    background: AppColors.inkBackground,
    backgroundSunken: Color(0xFF050810),
    surface: AppColors.inkSurface,
    surfaceElevated: AppColors.inkElevated,
    surfaceMuted: Color(0xFF1A2434),
    border: Color(0xFF243044),
    borderStrong: Color(0xFF33415C),
    separator: Color(0xFF1E2839),
    textPrimary: Color(0xFFF2F6FC),
    textSecondary: Color(0xFF9FB0C9),
    textTertiary: Color(0xFF6B7C96),
    textInverse: Color(0xFF0B1526),
    primary: Color(0xFF5B9BFF),
    primaryPressed: Color(0xFF3B82F6),
    primarySoft: Color(0xFF15263F),
    onPrimary: AppColors.white,
    success: Color(0xFF34D399),
    successSoft: Color(0xFF10261F),
    warning: Color(0xFFFBBF24),
    warningSoft: Color(0xFF2A2010),
    danger: Color(0xFFF87171),
    dangerSoft: Color(0xFF2C1517),
    info: Color(0xFF38BDF8),
    infoSoft: Color(0xFF0D2333),
    star: AppColors.star,
    scrim: Color(0x99000000),
    shadowSm: [
      BoxShadow(color: Color(0x40000000), blurRadius: 10, offset: Offset(0, 3)),
    ],
    shadowMd: [
      BoxShadow(color: Color(0x59000000), blurRadius: 24, offset: Offset(0, 10)),
    ],
    shadowLg: [
      BoxShadow(color: Color(0x73000000), blurRadius: 40, offset: Offset(0, 18)),
    ],
    brandGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF3B82F6), Color(0xFF2563EB), Color(0xFF1E3A8A)],
      stops: [0, 0.55, 1],
    ),
  );

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? background,
    Color? backgroundSunken,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceMuted,
    Color? border,
    Color? borderStrong,
    Color? separator,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textInverse,
    Color? primary,
    Color? primaryPressed,
    Color? primarySoft,
    Color? onPrimary,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? danger,
    Color? dangerSoft,
    Color? info,
    Color? infoSoft,
    Color? star,
    Color? scrim,
    List<BoxShadow>? shadowSm,
    List<BoxShadow>? shadowMd,
    List<BoxShadow>? shadowLg,
    LinearGradient? brandGradient,
  }) {
    return AppPalette(
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      backgroundSunken: backgroundSunken ?? this.backgroundSunken,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      separator: separator ?? this.separator,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textInverse: textInverse ?? this.textInverse,
      primary: primary ?? this.primary,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      primarySoft: primarySoft ?? this.primarySoft,
      onPrimary: onPrimary ?? this.onPrimary,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      info: info ?? this.info,
      infoSoft: infoSoft ?? this.infoSoft,
      star: star ?? this.star,
      scrim: scrim ?? this.scrim,
      shadowSm: shadowSm ?? this.shadowSm,
      shadowMd: shadowMd ?? this.shadowMd,
      shadowLg: shadowLg ?? this.shadowLg,
      brandGradient: brandGradient ?? this.brandGradient,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: c(background, other.background),
      backgroundSunken: c(backgroundSunken, other.backgroundSunken),
      surface: c(surface, other.surface),
      surfaceElevated: c(surfaceElevated, other.surfaceElevated),
      surfaceMuted: c(surfaceMuted, other.surfaceMuted),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      separator: c(separator, other.separator),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textTertiary: c(textTertiary, other.textTertiary),
      textInverse: c(textInverse, other.textInverse),
      primary: c(primary, other.primary),
      primaryPressed: c(primaryPressed, other.primaryPressed),
      primarySoft: c(primarySoft, other.primarySoft),
      onPrimary: c(onPrimary, other.onPrimary),
      success: c(success, other.success),
      successSoft: c(successSoft, other.successSoft),
      warning: c(warning, other.warning),
      warningSoft: c(warningSoft, other.warningSoft),
      danger: c(danger, other.danger),
      dangerSoft: c(dangerSoft, other.dangerSoft),
      info: c(info, other.info),
      infoSoft: c(infoSoft, other.infoSoft),
      star: c(star, other.star),
      scrim: c(scrim, other.scrim),
      shadowSm: BoxShadow.lerpList(shadowSm, other.shadowSm, t)!,
      shadowMd: BoxShadow.lerpList(shadowMd, other.shadowMd, t)!,
      shadowLg: BoxShadow.lerpList(shadowLg, other.shadowLg, t)!,
      brandGradient: LinearGradient.lerp(brandGradient, other.brandGradient, t)!,
    );
  }
}

extension PaletteX on BuildContext {
  /// The resolved colour set for the current brightness.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
