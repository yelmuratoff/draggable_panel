import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size, lerpDouble;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// How the collapsed content fades out as the panel begins to grow.
const Interval kPanelCollapsedFade = Interval(0, 0.25, curve: Curves.easeOut);

/// How the expanded content fades in once the panel is most of the way open.
const Interval kPanelExpandedFade = Interval(0.3, 0.7, curve: Curves.easeIn);

/// How the edge handle fades out as the panel is drawn off its park.
const Interval kPanelHandleFade = Interval(0, 0.55, curve: Curves.easeOut);

/// How the collapsed face fades in as the panel arrives from a park.
///
/// Starts after [kPanelHandleFade] is well underway, so the two are never both
/// half-there in the same place — the slide separates them, this keeps the
/// overlap short.
const Interval kPanelEmergeFade = Interval(0.35, 0.9, curve: Curves.easeIn);

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
    required this.handleOrigin,
    required this.collapsedOpacity,
    required this.expandedOpacity,
    required this.handleOpacity,
    required this.emergence,
    required this.parkedFade,
    required this.expansion,
  });

  /// The panel's outline this frame.
  final Rect rect;

  /// Where the collapsed content is painted, in the same space as [rect].
  final Offset collapsedOrigin;

  /// Where the expanded content is painted, in the same space as [rect].
  final Offset expandedOrigin;

  /// Where the edge handle is painted, centred on the part still on screen.
  final Offset handleOrigin;

  final double collapsedOpacity;
  final double expandedOpacity;
  final double handleOpacity;

  /// How far the panel has been pulled out from a parked position, `0` to `1`.
  final double emergence;

  /// How far the panel has closed on a parked position, `0` to `1`.
  ///
  /// Opens where the panel leaves the bounds it rests in, so it covers the
  /// whole journey rather than only the stretch spent crossing the edge.
  /// [emergence] stays the narrower measure the geometry morphs on.
  final double parkedFade;

  /// Progress clamped to `0..1`, for shape and elevation interpolation.
  final double expansion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PanelFrame &&
          other.rect == rect &&
          other.collapsedOrigin == collapsedOrigin &&
          other.expandedOrigin == expandedOrigin &&
          other.handleOrigin == handleOrigin &&
          other.collapsedOpacity == collapsedOpacity &&
          other.expandedOpacity == expandedOpacity &&
          other.handleOpacity == handleOpacity &&
          other.emergence == emergence &&
          other.parkedFade == parkedFade &&
          other.expansion == expansion;

  @override
  int get hashCode => Object.hash(
    rect,
    collapsedOrigin,
    expandedOrigin,
    handleOrigin,
    collapsedOpacity,
    expandedOpacity,
    handleOpacity,
    emergence,
    parkedFade,
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
///
/// [isDragging] and [isParking] each release the containment that otherwise
/// holds an expanded panel inside [bounds] — a finger and a park are both
/// allowed to carry it out through the edge.
PanelFrame computePanelFrame({
  required Offset origin,
  required Size collapsedSize,
  required Size expandedSize,
  required Size stashedSize,
  required Alignment anchor,
  required Rect bounds,
  required Rect viewport,
  required double stashedPeek,
  required double expansion,
  bool isDragging = false,
  bool isParking = false,
  bool reduceMotion = false,
}) {
  final clamped = expansion.clamp(0.0, 1.0);
  final sizeT = panelSizeProgress(expansion, reduceMotion: reduceMotion);

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

  final open = isDragging || isParking
      ? grown
      : Rect.lerp(grown, _nudgeInto(grown, bounds), clamped)!;

  final collapsedBox = origin & collapsedSize;
  final emergence = _emergence(collapsedBox, viewport, stashedPeek);
  final reveal = lerpDouble(emergence, 1, clamped)!;
  final rect = reveal >= 1
      ? open
      : Rect.lerp(_tabIn(collapsedBox, stashedSize, viewport), open, reveal)!;

  final towardsEdge = collapsedBox.left < viewport.left ? -1.0 : 1.0;
  final reel = Offset(towardsEdge * stashedSize.width, 0);

  return PanelFrame(
    rect: rect,
    collapsedOrigin:
        _alignIn(rect, collapsedSize, anchor) + reel * (emergence - 1),
    expandedOrigin: _alignIn(rect, expandedSize, anchor),
    handleOrigin:
        _handleIn(rect, handleSizeFor(stashedSize, stashedPeek), viewport) +
        reel * emergence,
    collapsedOpacity:
        (1 - kPanelCollapsedFade.transform(clamped)) *
        kPanelEmergeFade.transform(emergence),
    expandedOpacity: kPanelExpandedFade.transform(clamped),
    handleOpacity: (1 - kPanelHandleFade.transform(emergence)) * (1 - clamped),
    emergence: emergence,
    parkedFade: _parkedFade(collapsedBox, bounds, viewport, stashedPeek),
    expansion: clamped,
  );
}

/// How much of the collapsed-to-expanded size difference the panel is showing.
///
/// Steps between the two ends under [reduceMotion] rather than sweeping through
/// them, so nothing scales while a reduced-motion preference is set.
double panelSizeProgress(double expansion, {required bool reduceMotion}) =>
    reduceMotion ? (expansion > 0 ? 1.0 : 0.0) : expansion;

/// The part of a [tab]-sized parked panel that stays on screen.
Size handleSizeFor(Size tab, double stashedPeek) =>
    Size(math.min(stashedPeek, tab.width), tab.height);

/// Puts a [handle]-sized box on whichever side of [rect] faces the screen.
Offset _handleIn(Rect rect, Size handle, Rect viewport) => Offset(
  rect.left < viewport.left ? rect.right - handle.width : rect.left,
  rect.center.dy - handle.height / 2,
);

/// The tab a parked panel shows, sized [tab] inside [box].
///
/// Aligned to whichever side of [box] faces the screen, so shrinking the panel
/// into a tab trims what was going off the edge rather than the visible sliver.
Rect _tabIn(Rect box, Size tab, Rect viewport) => Rect.fromLTWH(
  box.left < viewport.left ? box.right - tab.width : box.left,
  box.center.dy - tab.height / 2,
  tab.width,
  tab.height,
);

/// How far the panel has been pulled clear of a parked position, `0` to `1`.
///
/// `0` is parked — exactly [stashedPeek] showing — and `1` is fully on screen.
/// Because it is continuous, the handle can cross-fade into the panel's own
/// content as the finger pulls rather than swapping at a threshold.
double _emergence(Rect rect, Rect viewport, double stashedPeek) {
  final travel = rect.width - stashedPeek;
  if (travel <= 0) return 1;
  final hidden =
      math.max(0, viewport.left - rect.left) +
      math.max(0, rect.right - viewport.right);
  return (1 - hidden / travel).clamp(0.0, 1.0);
}

/// How far [rect] has closed on a parked position, `0` to `1`.
///
/// `0` is anywhere inside [bounds], where a panel at rest lives, and `1` is
/// parked with exactly [stashedPeek] showing. Spans the whole journey between
/// the two, unlike [_emergence], which only leaves `1` once the panel is
/// already crossing the edge — the stretch a settling spring crawls through,
/// so anything hung on it holds still while the panel travels and then changes
/// all at once.
double _parkedFade(Rect rect, Rect bounds, Rect viewport, double stashedPeek) {
  final pastStart = bounds.left - rect.left;
  final pastEnd = rect.right - bounds.right;
  final towardsEnd = pastEnd >= pastStart;
  final beyond = towardsEnd ? pastEnd : pastStart;
  if (beyond <= 0) return 0;

  final margin = towardsEnd
      ? viewport.right - bounds.right
      : bounds.left - viewport.left;
  final span = margin + rect.width - stashedPeek;
  return span <= 0 ? 1 : (beyond / span).clamp(0.0, 1.0);
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
