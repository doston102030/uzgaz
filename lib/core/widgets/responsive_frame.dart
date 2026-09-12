import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';

/// Keeps the app's mobile-designed shell readable on a wide desktop/web
/// window instead of stretching it full-bleed.
///
/// The app has a single, phone-width layout everywhere (bottom tab bar,
/// 20px gutters, no breakpoints of its own) — reasonable for a marketplace
/// that is primarily used on a phone. Rather than build a whole second
/// desktop layout (rail navigation, multi-column pages — a much bigger
/// change than asked for), this wraps the *entire* `MaterialApp.router`
/// once: above [AppDimensions.breakpointDesktop] it centers that same
/// phone-width shell in a fixed [AppDimensions.maxContentWidth] column on
/// a softly branded background, like a phone held up to a wide screen.
/// Below the breakpoint it is a no-op passthrough.
class ResponsiveFrame extends StatelessWidget {
  const ResponsiveFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppDimensions.breakpointDesktop) {
          return child;
        }

        final c = context.palette;
        return ColoredBox(
          color: c.backgroundSunken,
          child: Center(
            child: Container(
              width: AppDimensions.maxContentWidth,
              margin: const EdgeInsets.symmetric(vertical: AppDimensions.space24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSheet),
                boxShadow: c.shadowLg,
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
