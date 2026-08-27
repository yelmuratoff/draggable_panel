import 'package:draggable_panel/src/model/panel_phase.dart';
import 'package:draggable_panel/src/model/panel_placement.dart';
import 'package:flutter/foundation.dart';

/// A complete, settled description of what the panel is doing.
///
/// Carries no per-frame data on purpose. The panel's live offset and expansion
/// progress belong to the motion layer, so a whole drag gesture produces only a
/// handful of statuses rather than one per frame.
@immutable
final class PanelStatus {
  const PanelStatus({required this.phase, required this.placement});

  /// The stage the panel is in.
  final PanelPhase phase;

  /// Where the panel rests, or will rest once the current motion finishes.
  ///
  /// While [PanelPhase.dragging] this is the placement the panel returns to if
  /// the gesture is cancelled.
  final PanelPlacement placement;

  bool get isExpanded => phase == PanelPhase.expanded;
  bool get isStashed => phase == PanelPhase.stashed;
  bool get isDragging => phase == PanelPhase.dragging;

  PanelStatus copyWith({PanelPhase? phase, PanelPlacement? placement}) =>
      PanelStatus(
        phase: phase ?? this.phase,
        placement: placement ?? this.placement,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PanelStatus &&
          other.phase == phase &&
          other.placement == placement;

  @override
  int get hashCode => Object.hash(phase, placement);

  @override
  String toString() => 'PanelStatus(${phase.name}, $placement)';
}
