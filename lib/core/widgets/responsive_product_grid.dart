import 'package:flutter/widgets.dart';

import '../../app/theme/dimensions.dart';

SliverGridDelegate productGridDelegate(BuildContext context, double width) {
  final scale = MediaQuery.textScalerOf(context).scale(15) / 15;
  final columns = ((width + 12) / (156 * scale + 12)).floor().clamp(1, 6);
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
