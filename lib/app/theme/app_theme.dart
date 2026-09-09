import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';
import 'dimensions.dart';
import 'typography.dart';

/// Builds the light and dark [ThemeData] from a single [AppPalette], so a
/// colour only ever has to change in one place.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppPalette.light);
  static ThemeData get dark => _build(AppPalette.dark);

  static ThemeData _build(AppPalette p) {
    final isDark = p.isDark;

    final textTheme = TextTheme(
      displayLarge: AppTypography.largeTitle.copyWith(color: p.textPrimary),
      displayMedium: AppTypography.title1.copyWith(color: p.textPrimary),
      headlineLarge: AppTypography.title1.copyWith(color: p.textPrimary),
      headlineMedium: AppTypography.title2.copyWith(color: p.textPrimary),
      headlineSmall: AppTypography.title3.copyWith(color: p.textPrimary),
      titleLarge: AppTypography.title3.copyWith(color: p.textPrimary),
      titleMedium: AppTypography.headline.copyWith(color: p.textPrimary),
      titleSmall: AppTypography.callout.copyWith(color: p.textPrimary),
      bodyLarge: AppTypography.body.copyWith(color: p.textPrimary),
      bodyMedium: AppTypography.subhead.copyWith(color: p.textSecondary),
      bodySmall: AppTypography.footnote.copyWith(color: p.textTertiary),
      labelLarge: AppTypography.button.copyWith(color: p.textPrimary),
      labelMedium: AppTypography.caption.copyWith(color: p.textSecondary),
      labelSmall: AppTypography.caption2.copyWith(color: p.textTertiary),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      extensions: <ThemeExtension<dynamic>>[p],

      colorScheme: ColorScheme(
        brightness: p.brightness,
        primary: p.primary,
        onPrimary: p.onPrimary,
        primaryContainer: p.primarySoft,
        onPrimaryContainer: p.primary,
        secondary: p.info,
        onSecondary: p.onPrimary,
        secondaryContainer: p.infoSoft,
        onSecondaryContainer: p.info,
        error: p.danger,
        onError: Colors.white,
        errorContainer: p.dangerSoft,
        onErrorContainer: p.danger,
        surface: p.surface,
        onSurface: p.textPrimary,
        surfaceContainerHighest: p.surfaceMuted,
        onSurfaceVariant: p.textSecondary,
        outline: p.border,
        outlineVariant: p.separator,
        shadow: Colors.black,
        scrim: p.scrim,
        inverseSurface: p.textPrimary,
        onInverseSurface: p.surface,
        inversePrimary: p.primarySoft,
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: AppDimensions.gutter,
        titleTextStyle: AppTypography.title3.copyWith(color: p.textPrimary),
        iconTheme: IconThemeData(color: p.textPrimary, size: AppDimensions.iconSize),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: p.background,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: p.background,
              ),
      ),

      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppDimensions.brLarge),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          disabledBackgroundColor: p.surfaceMuted,
          disabledForegroundColor: p.textTertiary,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          textStyle: AppTypography.button,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: const RoundedRectangleBorder(borderRadius: AppDimensions.brMedium),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          backgroundColor: Colors.transparent,
          side: BorderSide(color: p.borderStrong),
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          textStyle: AppTypography.button,
          shape: const RoundedRectangleBorder(borderRadius: AppDimensions.brMedium),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: AppTypography.buttonSmall,
          minimumSize: const Size(0, AppDimensions.touchTargetMin),
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space8),
          shape: const RoundedRectangleBorder(borderRadius: AppDimensions.brSmall),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: p.textPrimary,
          minimumSize: const Size.square(AppDimensions.touchTargetMin),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? p.surfaceMuted : p.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space16,
        ),
        border: OutlineInputBorder(
          borderRadius: AppDimensions.brMedium,
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.brMedium,
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimensions.brMedium,
          borderSide: BorderSide(color: p.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.brMedium,
          borderSide: BorderSide(color: p.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.brMedium,
          borderSide: BorderSide(color: p.danger, width: 1.6),
        ),
        hintStyle: AppTypography.body.copyWith(color: p.textTertiary),
        labelStyle: AppTypography.subhead.copyWith(color: p.textSecondary),
        errorStyle: AppTypography.caption.copyWith(color: p.danger),
        prefixIconColor: p.textTertiary,
        suffixIconColor: p.textTertiary,
      ),

      textTheme: textTheme,
      primaryTextTheme: textTheme,

      iconTheme: IconThemeData(color: p.textSecondary, size: AppDimensions.iconSize),

      dividerTheme: DividerThemeData(
        color: p.separator,
        thickness: 1,
        space: 1,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.surface,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: p.borderStrong,
        dragHandleSize: const Size(38, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusSheet),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: p.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppDimensions.brXLarge),
        titleTextStyle: AppTypography.title3.copyWith(color: p.textPrimary),
        contentTextStyle: AppTypography.subhead.copyWith(color: p.textSecondary),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? p.surfaceElevated : const Color(0xFF16233A),
        contentTextStyle: AppTypography.callout.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppDimensions.space16),
        shape: const RoundedRectangleBorder(borderRadius: AppDimensions.brMedium),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: p.primary,
        unselectedLabelColor: p.textTertiary,
        labelStyle: AppTypography.callout.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTypography.callout,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.primary : p.borderStrong,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.surfaceMuted,
        circularTrackColor: Colors.transparent,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        textColor: p.textPrimary,
        titleTextStyle: AppTypography.callout.copyWith(color: p.textPrimary),
        subtitleTextStyle: AppTypography.footnote.copyWith(color: p.textTertiary),
        shape: const RoundedRectangleBorder(borderRadius: AppDimensions.brMedium),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.textPrimary.withValues(alpha: 0.92),
          borderRadius: AppDimensions.brSmall,
        ),
        textStyle: AppTypography.caption.copyWith(color: p.surface),
      ),
    );
  }
}

/// Bouncing, glow-free scrolling on every platform — the single change
/// that makes an Android build feel iOS-native.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
