import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gaz_energiya/app/theme/app_theme.dart';
import 'package:gaz_energiya/core/widgets/order_status_widget.dart';
import 'package:gaz_energiya/core/widgets/pulsing_marker.dart';
import 'package:gaz_energiya/features/home/presentation/pages/home_page.dart';

/// A screen nobody touches must stop drawing. A single endless animation
/// (the promo banner used to "breathe" forever) redraws the whole page 60
/// times a second — on a phone that is a busy CPU, a warm hand and a
/// draining battery. Timed rotations (banner, product photos) run on
/// timers between short animations, so between them nothing ticks.
void main() {
  Future<void> settle(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(theme: AppTheme.light, home: child),
    ));
    // Entrances, data and the first pulses all finish well within this.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  testWidgets('The home page goes still once it has loaded', (tester) async {
    await settle(tester, const HomePage());
    expect(tester.binding.transientCallbackCount, 0,
        reason: 'no animation may run forever on the home page');
  });

  testWidgets('Live markers pulse a few times, then rest', (tester) async {
    await settle(
      tester,
      const Scaffold(
        body: Column(children: [
          LivePulse(),
          PulsingMarker(color: Colors.blue, child: SizedBox.square(dimension: 8)),
        ]),
      ),
    );
    expect(tester.binding.transientCallbackCount, 0);
  });
}
