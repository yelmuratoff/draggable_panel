import 'package:draggable_panel/src/controller/derived_notifier.dart';
import 'package:draggable_panel/src/controller/panel_event.dart';
import 'package:draggable_panel/src/controller/panel_state_machine.dart';
import 'package:draggable_panel/src/model/panel_behavior.dart';
import 'package:draggable_panel/src/model/panel_corner.dart';
import 'package:draggable_panel/src/model/panel_edge.dart';
import 'package:draggable_panel/src/model/panel_phase.dart';
import 'package:draggable_panel/src/model/panel_placement.dart';
import 'package:draggable_panel/src/model/panel_status.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Reads and commands a [PanelStatus].
///
/// Commands take no layout arguments: a controller describes *intent*, and the
/// widget layer resolves that intent against the current viewport. That split is
/// what lets a placement survive rotation, a resize, or being restored onto a
/// different device.
///
/// The panel's live offset and expansion progress are deliberately absent. They
/// belong to the motion layer, so dragging the panel across the screen produces
/// roughly three notifications rather than one per frame.
final class DraggablePanelController extends ChangeNotifier
    implements ValueListenable<PanelStatus> {
  DraggablePanelController({
    PanelPlacement initialPlacement = const PanelPlacement.corner(
      PanelCorner.bottomEnd,
    ),
    bool initiallyExpanded = false,
    bool initiallyHidden = false,
  }) : _status = PanelStatus(
         phase: switch ((
           initiallyHidden,
           initiallyExpanded,
           initialPlacement is StashedPlacement,
         )) {
           (true, _, _) => PanelPhase.hidden,
           (false, true, _) => PanelPhase.expanded,
           (false, false, true) => PanelPhase.stashed,
           (false, false, false) => PanelPhase.collapsed,
         },
         placement: initialPlacement,
       ) {
    _phase = DerivedNotifier<PanelPhase>(this, () => phase);
    _placement = DerivedNotifier<PanelPlacement>(this, () => placement);
  }

  PanelStatus _status;
  PanelBehavior _behavior = const PanelBehavior();
  bool _expandAfterSettling = false;

  late final DerivedNotifier<PanelPhase> _phase;
  late final DerivedNotifier<PanelPlacement> _placement;

  /// Notifies when the [phase] changes, ignoring pure placement changes.
  ValueListenable<PanelPhase> get phaseListenable => _phase;

  /// Notifies when the resting [placement] changes.
  ///
  /// Suitable for persistence: it never reports a transient position, because
  /// dragging does not change the placement until the release resolves.
  ValueListenable<PanelPlacement> get placementListenable => _placement;

  @override
  PanelStatus get value => _status;

  PanelPhase get phase => _status.phase;

  PanelPlacement get placement => _status.placement;

  bool get isExpanded => _status.isExpanded;

  bool get isStashed => _status.isStashed;

  bool get isDragging => _status.isDragging;

  /// Which interactions the attached panel accepts.
  ///
  /// Owned by the `DraggablePanel` widget and mirrored here so that programmatic
  /// commands honour the same gates as gestures. Defaults to
  /// [PanelBehavior.new] while no panel is attached.
  PanelBehavior get behavior => _behavior;

  @internal
  set behavior(PanelBehavior value) => _behavior = value;

  /// The attached panel's reading direction, mirrored from the widget.
  ///
  /// A free placement stores a physical alignment, so turning one into a
  /// directional [PanelEdge] needs to know which side is the start. Defaults to
  /// [TextDirection.ltr] while no panel is attached.
  TextDirection get textDirection => _textDirection;

  @internal
  set textDirection(TextDirection value) => _textDirection = value;

  TextDirection _textDirection = TextDirection.ltr;

  /// Grows the panel to its expanded size.
  ///
  /// A stashed panel returns to the nearest corner first and expands once it
  /// arrives, because growing out of the edge of the screen has nowhere to go.
  void expand() {
    if (phase == PanelPhase.stashed) {
      _expandAfterSettling = true;
      unstash();
      return;
    }
    dispatch(const PanelExpandRequested());
  }

  /// Shrinks the panel back to its collapsed size.
  void collapse() => dispatch(const PanelCollapseRequested());

  /// Expands a collapsed panel, collapses an expanded one.
  void toggle() => dispatch(const PanelToggleRequested());

  /// Parks the panel off-screen against [edge], keeping its vertical position.
  ///
  /// When [edge] is omitted the panel stashes towards the side it already sits
  /// on. Does nothing when [PanelBehavior.stashable] is `false`.
  void stash([PanelEdge? edge]) => dispatch(
    PanelStashRequested(
      edge ?? _nearestEdge(),
      verticalAlignment: _verticalAlignment(),
    ),
  );

  /// Slides a stashed panel back on screen, keeping the side and height it was
  /// parked at.
  ///
  /// It returns to where it was pulled from rather than to a corner, so the
  /// panel appears to come out of its own tab.
  void unstash() {
    final current = placement;
    if (current is! StashedPlacement) return;
    dispatch(PanelUnstashRequested(restingPlacementFor(current)));
  }

  /// Where a stashed panel sits once it is fully on screen.
  @internal
  static PanelPlacement restingPlacementFor(StashedPlacement stashed) =>
      PanelPlacement.free(
        AlignmentDirectional(
          stashed.edge == PanelEdge.start ? -1 : 1,
          stashed.verticalAlignment.clamp(-1.0, 1.0),
        ),
      );

  /// Moves the panel to [target] without changing whether it is expanded.
  void moveTo(PanelPlacement target) => dispatch(PanelMoveRequested(target));

  /// Takes the panel off-stage, keeping its placement for the next [show].
  void hide() => dispatch(const PanelHideRequested());

  /// Brings a hidden panel back to its last placement.
  void show() => dispatch(const PanelShowRequested());

  /// Applies [event] to the current status.
  ///
  /// Called by the panel widget for gesture and animation events. Prefer the
  /// named commands above; this is the seam the widget layer drives.
  @internal
  void dispatch(PanelEvent event) {
    assert(ChangeNotifier.debugAssertNotDisposed(this), '');
    var next = panelTransition(_status, event, _behavior);

    if (_expandAfterSettling && next.phase == PanelPhase.collapsed) {
      _expandAfterSettling = false;
      next = panelTransition(next, const PanelExpandRequested(), _behavior);
    }
    if (event is PanelDragStarted || event is PanelHideRequested) {
      _expandAfterSettling = false;
    }

    if (next == _status) return;
    _status = next;
    notifyListeners();
  }

  PanelEdge _nearestEdge() => switch (placement) {
    CornerPlacement(:final corner) =>
      corner.isStart ? PanelEdge.start : PanelEdge.end,
    StashedPlacement(:final edge) => edge,
    FreePlacement(:final alignment) => _edgeFacing(
      alignment.resolve(_textDirection).x,
    ),
  };

  /// The edge on the side [x] points at, where `x` is physical.
  PanelEdge _edgeFacing(double x) {
    final onLeft = x < 0;
    final startIsLeft = _textDirection == TextDirection.ltr;
    return onLeft == startIsLeft ? PanelEdge.start : PanelEdge.end;
  }

  double _verticalAlignment() => switch (placement) {
    CornerPlacement(:final corner) => corner.isTop ? -1.0 : 1.0,
    StashedPlacement(:final verticalAlignment) => verticalAlignment,
    FreePlacement(:final alignment) => alignment.resolve(TextDirection.ltr).y,
  };

  @override
  void dispose() {
    _phase.dispose();
    _placement.dispose();
    super.dispose();
  }
}
