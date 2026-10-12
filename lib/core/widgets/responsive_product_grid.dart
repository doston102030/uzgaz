import 'package:flutter/widgets.dart';

import '../../app/theme/dimensions.dart';

/// Two columns on every phone: a 360 px phone used to get one column of
/// screen-wide, very tall cards. Only below [_minTwoUp] (narrower than any
/// phone in portrait) does it fall back to one; wider screens add columns
/// as each can stay ~150 px wide.
SliverGridDelegate productGridDelegate(BuildContext context, double width) {
  final scale = MediaQuery.textScalerOf(context).scale(15) / 15;
  final columns = width < _minTwoUp
      ? 1
      : ((width + 12) / (150 * scale + 12)).floor().clamp(2, 6);
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    mainAxisSpacing: AppDimensions.space12,
    crossAxisSpacing: AppDimensions.space12,
    mainAxisExtent:
        AppDimensions.productCardHeight + (scale > 1 ? (scale - 1) * 150 : 0),
  );
}

class ResponsiveProductGrid extends StatelessWidget {
  const ResponsiveProductGrid({super.key, required this.delegate});

  final SliverChildDelegate delegate;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
        builder: (context, constraints) => SliverGrid(
          gridDelegate:
              productGridDelegate(context, constraints.crossAxisExtent),
          delegate: delegate,
        ),
      );
}

/// Two cards of 124 px and the gap between them.
const double _minTwoUp = 2 * 124 + 12;
