import 'package:draggable_panel/src/model/panel_edge.dart';
import 'package:draggable_panel/src/model/panel_placement.dart';
import 'package:flutter/foundation.dart';

/// Something that can change a panel's phase.
///
/// Events carry resolved *intents*, never pixels: the widget layer turns a
/// release position and velocity into a [PanelPlacement] before dispatching, so
/// the state machine stays free of geometry.
@immutable
sealed class PanelEvent {
  const PanelEvent();
}

/// A pointer took ownership of the panel.
final class PanelDragStarted extends PanelEvent {
  const PanelDragStarted();
}

/// The pointer released, and the release resolved to [target].
final class PanelDragSettled extends PanelEvent {
  const PanelDragSettled(this.target);

  final PanelPlacement target;
}

/// The gesture was cancelled; the panel returns to where it started.
final class PanelDragCancelled extends PanelEvent {
  const PanelDragCancelled();
}

/// The positional spring reached its target.
final class PanelSettleCompleted extends PanelEvent {
  const PanelSettleCompleted();
}

/// The expansion spring reached either end of its range.
final class PanelMorphCompleted extends PanelEvent {
  const PanelMorphCompleted();
}

/// Grow to the expanded size.
final class PanelExpandRequested extends PanelEvent {
  const PanelExpandRequested();
}

/// Shrink back to the collapsed size.
final class PanelCollapseRequested extends PanelEvent {
  const PanelCollapseRequested();
}

/// Move to [target] without changing whether the panel is expanded.
final class PanelMoveRequested extends PanelEvent {
  const PanelMoveRequested(this.target);

  final PanelPlacement target;
}

/// Park off-screen against [edge], keeping the current vertical position.
final class PanelStashRequested extends PanelEvent {
  const PanelStashRequested(this.edge, {this.verticalAlignment = 0});

  final PanelEdge edge;
  final double verticalAlignment;
}

/// Return from a stash to [target].
final class PanelUnstashRequested extends PanelEvent {
  const PanelUnstashRequested(this.target);

  final PanelPlacement target;
}

/// Take the panel off-stage entirely.
final class PanelHideRequested extends PanelEvent {
  const PanelHideRequested();
}

/// Bring a hidden panel back to its last placement.
final class PanelShowRequested extends PanelEvent {
  const PanelShowRequested();
}

/// Dismiss the panel by flinging it clear of the viewport.
final class PanelDismissRequested extends PanelEvent {
  const PanelDismissRequested();
}
