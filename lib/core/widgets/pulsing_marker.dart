import 'package:flutter/material.dart';

/// Wraps [child] with an expanding radar ring — the visual cue that a
/// marker is "live" (the user's own position, a driver en route) rather
/// than a static pin.
class PulsingMarker extends StatefulWidget {
  const PulsingMarker({
    super.key,
    required this.color,
    required this.child,
    this.ringSize = 32,
  });

  final Color color;
  final Widget child;
  final double ringSize;

  @override
  State<PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<PulsingMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: widget.ringSize * _controller.value,
            height: widget.ringSize * _controller.value,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.22 * (1 - _controller.value)),
              shape: BoxShape.circle,
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}
