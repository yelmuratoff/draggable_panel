import 'package:draggable_panel/src/model/panel_behavior.dart';
import 'package:draggable_panel/src/model/panel_corner.dart';
import 'package:draggable_panel/src/model/panel_edge.dart';
import 'package:draggable_panel/src/model/panel_placement.dart';
import 'package:draggable_panel/src/model/panel_viewport.dart';
import 'package:draggable_panel/src/motion/panel_motion_spec.dart';
import 'package:draggable_panel/src/motion/panel_physics.dart';
import 'package:flutter/painting.dart';

/// Decides where a released panel belongs.
///
/// The decision is made against the point the panel's momentum *projects* to,
/// not the point the finger left it at, so a flick lands where it was aimed.
/// This is the rule Apple's Picture-in-Picture uses and the reason a quick
/// flick from mid-screen reaches the far corner.
PanelPlacement resolvePanelRelease({
  required Offset topLeft,
  required Offset velocity,
  required Size panelSize,
  required PanelViewport viewport,
  required PanelBehavior behavior,
  required PanelMotionSpec motion,
}) {
  final projected = PanelPhysics.projectOffset(
    topLeft,
    velocity,
    motion.decelerationRate,
  );

  final stash = _stashDecision(
    projected: projected,
    velocity: velocity,
    panelSize: panelSize,
    viewport: viewport,
    behavior: behavior,
    motion: motion,
  );
  if (stash != null) return stash;

  return switch (behavior.snapPolicy) {
    PanelSnapPolicy.corners => _nearestCorner(projected, panelSize, viewport),
    PanelSnapPolicy.edges => _nearestEdge(projected, panelSize, viewport),
    PanelSnapPolicy.free => _free(projected, panelSize, viewport),
  };
}

/// A stash needs the gesture to be clearly horizontal *and* to project the
/// panel's centre past the edge, so one threshold covers both a slow shove and
/// a fast flick from mid-screen.
PanelPlacement? _stashDecision({
  required Offset projected,
  required Offset velocity,
  required Size panelSize,
  required PanelViewport viewport,
  required PanelBehavior behavior,
  required PanelMotionSpec motion,
}) {
  if (!behavior.stashable) return null;

  final bounds = viewport.bounds;
  final commit = panelSize.width * motion.stashCommit;

  // Measured from the resting edge outwards, so pushing the panel off the side
  // is what parks it. Comparing centres instead would need the panel dragged
  // half its width past a position it can barely reach through the rubber band.
  final pastStart = bounds.left - projected.dx;
  final pastEnd = projected.dx + panelSize.width - bounds.right;
  if (pastStart < commit && pastEnd < commit) return null;

  final vertical = _verticalAlignmentOf(projected, panelSize, viewport);
  return PanelPlacement.stashed(
    _edgeForSide(isLeft: pastStart >= pastEnd, viewport: viewport),
    verticalAlignment: vertical,
  );
}

PanelPlacement _nearestCorner(
  Offset projected,
  Size panelSize,
  PanelViewport viewport,
) => PanelPlacement.corner(
  PanelPhysics.nearest(
    projected,
    PanelCorner.values,
    (corner) => CornerPlacement(corner).resolve(viewport, panelSize),
  ),
);

PanelPlacement _nearestEdge(
  Offset projected,
  Size panelSize,
  PanelViewport viewport,
) {
  final travel = viewport.travelFor(panelSize);
  final centre = projected.dx + panelSize.width / 2;
  final toLeft = centre < viewport.bounds.center.dx;
  return PanelPlacement.free(
    Alignment(
      toLeft ? -1 : 1,
      _normalise(projected.dy, travel.top, travel.bottom),
    ),
  );
}

PanelPlacement _free(Offset projected, Size panelSize, PanelViewport viewport) {
  final travel = viewport.travelFor(panelSize);
  return PanelPlacement.free(
    Alignment(
      _normalise(projected.dx, travel.left, travel.right),
      _normalise(projected.dy, travel.top, travel.bottom),
    ),
  );
}

double _verticalAlignmentOf(
  Offset projected,
  Size panelSize,
  PanelViewport viewport,
) {
  final travel = viewport.travelFor(panelSize);
  return _normalise(projected.dy, travel.top, travel.bottom);
}

/// Maps a coordinate onto the `-1..1` alignment space of a travel range.
double _normalise(double value, double low, double high) {
  if (high <= low) return 0;
  return (((value - low) / (high - low)) * 2 - 1).clamp(-1.0, 1.0);
}

/// The directional edge that resolves to the requested physical side.
PanelEdge _edgeForSide({
  required bool isLeft,
  required PanelViewport viewport,
}) {
  final startIsLeft = PanelEdge.start.resolvesToLeft(viewport.direction);
  return isLeft == startIsLeft ? PanelEdge.start : PanelEdge.end;
}
