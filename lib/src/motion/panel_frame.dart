import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size, lerpDouble;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// How the collapsed content fades out as the panel begins to grow.
const Interval kPanelCollapsedFade = Interval(0, 0.25, curve: Curves.easeOut);

/// How the expanded content fades in once the panel is most of the way open.
const Interval kPanelExpandedFade = Interval(0.3, 0.7, curve: Curves.easeIn);

/// Everything needed to paint one frame of the panel.
///
/// Produced by [computePanelFrame], which is a pure function of the panel's
/// position, its expansion progress, and the space available. Keeping it pure
/// means the entire growth animation is testable without building a widget.
@immutable
final class PanelFrame {
  const PanelFrame({
    required this.rect,
    required this.collapsedOrigin,
    required this.expandedOrigin,
    required this.collapsedOpacity,
    required this.expandedOpacity,
    required this.expansion,
  });

  /// The panel's outline this frame.
  final Rect rect;

  /// Where the collapsed content is painted, in the same space as [rect].
  final Offset collapsedOrigin;

  /// Where the expanded content is painted, in the same space as [rect].
  final Offset expandedOrigin;

  final double collapsedOpacity;
  final double expandedOpacity;

  /// Progress clamped to `0..1`, for shape and elevation interpolation.
  final double expansion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PanelFrame &&
          other.rect == rect &&
          other.collapsedOrigin == collapsedOrigin &&
          other.expandedOrigin == expandedOrigin &&
          other.collapsedOpacity == collapsedOpacity &&
          other.expandedOpacity == expandedOpacity &&
          other.expansion == expansion;

  @override
  int get hashCode => Object.hash(
    rect,
    collapsedOrigin,
    expandedOrigin,
    collapsedOpacity,
    expandedOpacity,
    expansion,
  );

  @override
  String toString() => 'PanelFrame($rect, expansion: $expansion)';
}

/// Builds the frame for a panel anchored at [anchor] and grown to [expansion].
///
/// [origin] is the collapsed panel's top-left. The corner named by [anchor]
/// stays pinned as the panel grows, so it expands away from the edge it lives
/// against rather than drifting across the screen.
///
/// Children are positioned at their natural sizes and revealed by the growing
/// rect. Nothing is scaled, which is why arbitrary content — icons, text — never
/// distorts mid-animation.
///
/// When [reduceMotion] is set the rect steps between its two sizes instead of
/// sweeping, while the opacities still interpolate: a cross-fade is acceptable
/// where a translation is not.
PanelFrame computePanelFrame({
  required Offset origin,
  required Size collapsedSize,
  required Size expandedSize,
  required Alignment anchor,
  required Rect bounds,
  required double expansion,
  bool reduceMotion = false,
}) {
  final clamped = expansion.clamp(0.0, 1.0);
  final sizeT = reduceMotion ? (expansion > 0 ? 1.0 : 0.0) : expansion;

  final size = Size(
    lerpDouble(collapsedSize.width, expandedSize.width, sizeT)!,
    lerpDouble(collapsedSize.height, expandedSize.height, sizeT)!,
  );

  final ax = (anchor.x + 1) / 2;
  final ay = (anchor.y + 1) / 2;
  final pin = Offset(
    origin.dx + ax * collapsedSize.width,
    origin.dy + ay * collapsedSize.height,
  );

  final grown = Rect.fromLTWH(
    pin.dx - ax * size.width,
    pin.dy - ay * size.height,
    size.width,
    size.height,
  );

  final rect = Rect.lerp(grown, _nudgeInto(grown, bounds), clamped)!;

  final emergence = _visibleFraction(rect, bounds);

  return PanelFrame(
    rect: rect,
    collapsedOrigin: _alignIn(rect, collapsedSize, anchor),
    expandedOrigin: _alignIn(rect, expandedSize, anchor),
    collapsedOpacity: (1 - kPanelCollapsedFade.transform(clamped)) * emergence,
    expandedOpacity: kPanelExpandedFade.transform(clamped) * emergence,
    expansion: clamped,
  );
}

/// How much of [rect]'s width sits inside [bounds], from `0` to `1`.
///
/// Reaches `1` while a little of the panel is still off screen, so content is
/// fully legible before the panel finishes arriving.
double _visibleFraction(Rect rect, Rect bounds) {
  if (rect.width <= 0) return 1;
  final overlap =
      math.min(rect.right, bounds.right) - math.max(rect.left, bounds.left);
  return (overlap / rect.width / 0.75).clamp(0.0, 1.0);
}

/// Places a child of [child] size inside [rect], aligned to [anchor].
Offset _alignIn(Rect rect, Size child, Alignment anchor) => Offset(
  rect.left + (anchor.x + 1) / 2 * (rect.width - child.width),
  rect.top + (anchor.y + 1) / 2 * (rect.height - child.height),
);

/// Shifts [rect] the shortest distance that puts it inside [bounds], pinning to
/// the leading edge on an axis where it simply does not fit.
Rect _nudgeInto(Rect rect, Rect bounds) => rect.shift(
  Offset(
    _nudgeAxis(rect.left, rect.right, bounds.left, bounds.right),
    _nudgeAxis(rect.top, rect.bottom, bounds.top, bounds.bottom),
  ),
);

double _nudgeAxis(double low, double high, double min, double max) {
  if (high - low > max - min) return min - low;
  if (low < min) return min - low;
  if (high > max) return max - high;
  return 0;
}
