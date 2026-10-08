import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../constants/app_constants.dart';
import 'product_illustration.dart';

/// Local artwork stays sharp offline and does not depend on catalogue photos.
class CategoryArtwork extends StatefulWidget {
  const CategoryArtwork({
    super.key,
    required this.category,
    this.animate = false,
    this.size = 76,
  });

  final ServiceCategory category;
  final bool animate;
  final double size;

  @override
  State<CategoryArtwork> createState() => _CategoryArtworkState();
}

class _CategoryArtworkState extends State<CategoryArtwork>
    with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(CategoryArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
    final enabled = widget.animate &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (enabled && !_motion.isAnimating) {
      _motion.repeat();
    } else if (!enabled) {
      _motion.stop();
      _motion.value = 0;
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final color = widget.category.color;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _motion,
            child: widget.category == ServiceCategory.gazBallon
                ? Padding(
                    // The photo is tall and narrow, so it gets almost the
                    // full height or it looks lost next to the drawings.
                    padding: EdgeInsets.symmetric(vertical: widget.size * .02),
                    child: Image.asset(
                      'assets/images/promo_gas_cylinder.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => ProductIllustration(
                        visual: EnergyVisual.cylinder,
                        showStage: false,
                        size: widget.size,
                      ),
                    ),
                  )
                : ProductIllustration(
                    visual: EnergyVisualX.fromCategory(widget.category.id),
                    showStage: false,
                    size: widget.size,
                  ),
            builder: (context, child) {
              final wave = math.sin(_motion.value * math.pi * 2);
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: widget.size * .82,
                    height: widget.size * .82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        color.withValues(alpha: c.isDark ? .25 : .14),
                        color.withValues(alpha: .02),
                      ]),
                    ),
                  ),
                  Positioned(
                    bottom: widget.size * .05,
                    child: Container(
                      width: widget.size * (.4 + wave * .025),
                      height: widget.size * .06,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, wave * widget.size * .025),
                    child: Transform.rotate(angle: wave * .025, child: child),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
