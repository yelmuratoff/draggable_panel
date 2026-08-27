import 'package:draggable_panel/src/controller/panel_event.dart';
import 'package:draggable_panel/src/model/panel_behavior.dart';
import 'package:draggable_panel/src/model/panel_phase.dart';
import 'package:draggable_panel/src/model/panel_placement.dart';
import 'package:draggable_panel/src/model/panel_status.dart';

/// The panel's phase transitions, as a pure function.
///
/// Returns the status [from] unchanged when [event] is not legal in that phase,
/// so callers never have to check first and an unexpected event can never leave
/// the panel in an impossible state.
///
/// A viewport change is deliberately absent: because a [PanelPlacement] is
/// resolution-independent, rotation, a resize, and the keyboard change where the
/// panel *is* without changing what it is *doing*.
///
/// [PanelBehavior.draggable], [PanelBehavior.stashable], and
/// [PanelBehavior.dismissible] are enforced here because they gate whether a
/// transition exists at all. The remaining flags gate whether a gesture emits an
/// event, so they belong to the gesture layer.
PanelStatus panelTransition(
  PanelStatus from,
  PanelEvent event,
  PanelBehavior behavior,
) => switch (event) {
  PanelDragStarted() => _dragStarted(from, behavior),
  PanelDragSettled(:final target) =>
    from.phase == PanelPhase.dragging
        ? PanelStatus(phase: PanelPhase.settling, placement: target)
        : from,
  PanelDragCancelled() =>
    from.phase == PanelPhase.dragging
        ? from.copyWith(phase: PanelPhase.settling)
        : from,
  PanelSettleCompleted() => _settleCompleted(from),
  PanelMorphCompleted() => _morphCompleted(from),
  PanelExpandRequested() => _expand(from),
  PanelCollapseRequested() => _collapse(from),
  PanelToggleRequested() =>
    from.phase.isExpanding ? _collapse(from) : _expand(from),
  PanelMoveRequested(:final target) => _moveTo(from, target),
  PanelStashRequested(:final edge, :final verticalAlignment) => _stash(
    from,
    behavior,
    PanelPlacement.stashed(edge, verticalAlignment: verticalAlignment),
  ),
  PanelUnstashRequested(:final target) =>
    from.phase == PanelPhase.stashed
        ? PanelStatus(phase: PanelPhase.settling, placement: target)
        : from,
  PanelHideRequested() => from.copyWith(phase: PanelPhase.hidden),
  PanelShowRequested() =>
    from.phase == PanelPhase.hidden
        ? from.copyWith(phase: PanelPhase.settling)
        : from,
  PanelDismissRequested() =>
    behavior.dismissible ? from.copyWith(phase: PanelPhase.hidden) : from,
};

PanelStatus _dragStarted(PanelStatus from, PanelBehavior behavior) {
  if (!behavior.draggable) return from;
  return switch (from.phase) {
    PanelPhase.collapsed ||
    PanelPhase.settling ||
    PanelPhase.stashed => from.copyWith(phase: PanelPhase.dragging),
    _ => from,
  };
}

PanelStatus _settleCompleted(PanelStatus from) {
  if (from.phase != PanelPhase.settling) return from;
  final resting = from.placement is StashedPlacement
      ? PanelPhase.stashed
      : PanelPhase.collapsed;
  return from.copyWith(phase: resting);
}

PanelStatus _morphCompleted(PanelStatus from) => switch (from.phase) {
  PanelPhase.expanding => from.copyWith(phase: PanelPhase.expanded),
  PanelPhase.collapsing => from.copyWith(phase: PanelPhase.collapsed),
  _ => from,
};

PanelStatus _expand(PanelStatus from) => switch (from.phase) {
  PanelPhase.collapsed ||
  PanelPhase.settling ||
  PanelPhase.collapsing => from.copyWith(phase: PanelPhase.expanding),
  _ => from,
};

PanelStatus _collapse(PanelStatus from) => switch (from.phase) {
  PanelPhase.expanded ||
  PanelPhase.expanding => from.copyWith(phase: PanelPhase.collapsing),
  _ => from,
};

PanelStatus _moveTo(PanelStatus from, PanelPlacement target) =>
    switch (from.phase) {
      PanelPhase.hidden ||
      PanelPhase.expanding ||
      PanelPhase.expanded ||
      PanelPhase.collapsing => from.copyWith(placement: target),
      PanelPhase.dragging => from,
      _ => PanelStatus(phase: PanelPhase.settling, placement: target),
    };

PanelStatus _stash(
  PanelStatus from,
  PanelBehavior behavior,
  PanelPlacement target,
) {
  if (!behavior.stashable) return from;
  return switch (from.phase) {
    PanelPhase.collapsed || PanelPhase.settling || PanelPhase.dragging =>
      PanelStatus(phase: PanelPhase.settling, placement: target),
    _ => from,
  };
}
