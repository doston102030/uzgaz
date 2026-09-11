import 'dart:ui';

/// Breaks [source] into a dashed version of itself — used to draw lane
/// markings and "remaining route" hints on the stylised map painters.
Path dashPath(Path source, {required double dashLength, required double gapLength}) {
  final dashed = Path();
  for (final metric in source.computeMetrics()) {
    var distance = 0.0;
    var draw = true;
    while (distance < metric.length) {
      final length = draw ? dashLength : gapLength;
      final next = (distance + length).clamp(0.0, metric.length);
      if (draw) {
        dashed.addPath(metric.extractPath(distance, next), Offset.zero);
      }
      distance = next;
      draw = !draw;
    }
  }
  return dashed;
}
