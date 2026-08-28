import 'dart:math' as math;

import 'package:draggable_panel/src/controller/draggable_panel_controller.dart';
import 'package:draggable_panel/src/controller/panel_event.dart';
import 'package:draggable_panel/src/core/panel_haptics.dart';
import 'package:draggable_panel/src/core/panel_semantics.dart';
import 'package:draggable_panel/src/core/panel_surface.dart';
import 'package:draggable_panel/src/core/render_panel_surface.dart';
import 'package:draggable_panel/src/model/panel_behavior.dart';
import 'package:draggable_panel/src/model/panel_corner.dart';
import 'package:draggable_panel/src/model/panel_edge.dart';
import 'package:draggable_panel/src/model/panel_phase.dart';
import 'package:draggable_panel/src/model/panel_placement.dart';
import 'package:draggable_panel/src/model/panel_status.dart';
import 'package:draggable_panel/src/model/panel_viewport.dart';
import 'package:draggable_panel/src/motion/morph_controller.dart';
import 'package:draggable_panel/src/motion/offset_spring_driver.dart';
import 'package:draggable_panel/src/motion/panel_frame.dart';
import 'package:draggable_panel/src/motion/panel_motion_spec.dart';
import 'package:draggable_panel/src/motion/panel_physics.dart';
import 'package:draggable_panel/src/motion/panel_release.dart';
import 'package:draggable_panel/src/theme/panel_style.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

/// Drives one panel: owns its motion, reads its gestures, and keeps its
/// controller and the viewport in step.
///
/// Everything that moves per frame lives in the two motion objects here, which
/// the render layer reads directly. The widget itself rebuilds only when the
/// panel's phase or configuration changes — a handful of times per gesture.
final class PanelHost extends StatefulWidget {
  const PanelHost({
    required this.controller,
    required this.behavior,
    required this.style,
    required this.semantics,
    required this.collapsed,
    required this.expanded,
    required this.handle,
    required this.surfaceKey,
    super.key,
  });

  final DraggablePanelController controller;
  final PanelBehavior behavior;
  final PanelStyle style;
  final PanelSemantics semantics;
  final Widget collapsed;
  final Widget expanded;

  /// Builds the grab affordance for whichever edge the panel is parked at.
  final Widget Function(BuildContext context, PanelEdge edge) handle;

  /// Reaches the render object, so an ancestor can tell a touch on the panel
  /// from one that landed elsewhere.
  final GlobalKey surfaceKey;

  @override
  State<PanelHost> createState() => _PanelHostState();
}

class _PanelHostState extends State<PanelHost> with TickerProviderStateMixin {
  late final OffsetSpringDriver _driver;
  late final MorphController _morph;
  late final Listenable _repaint;

  PanelViewport? _viewport;
  Offset _raw = Offset.zero;
  Offset _grab = Offset.zero;
  Offset _carried = Offset.zero;
  Duration _carriedAt = Duration.zero;
  double _morphReleaseVelocity = 0;
  Offset _settleVelocity = Offset.zero;
  bool _placed = false;

  final PanelHaptics _haptics = PanelHaptics();
  PanelStatus? _previousStatus;

  PanelMotionSpec get _spec => widget.style.motion;

  Size get _panelSize => widget.style.collapsedSize;

  @override
  void initState() {
    super.initState();
    _driver = OffsetSpringDriver(
      vsync: this,
      spec: _spec,
      onSettled: () => _dispatch(const PanelSettleCompleted()),
    );
    _morph = MorphController(
      vsync: this,
      spec: _spec,
      initial: widget.controller.isExpanded ? 1 : 0,
      onCompleted: () => _dispatch(const PanelMorphCompleted()),
    );
    _repaint = Listenable.merge([_driver, _morph]);
    _previousStatus = widget.controller.value;
    widget.controller.addListener(_onStatusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncViewport();
  }

  @override
  void didUpdateWidget(PanelHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_onStatusChanged);
      widget.controller.addListener(_onStatusChanged);
    }
    _driver.spec = _spec;
    _morph.spec = _spec;
    widget.controller.behavior = widget.behavior;
    if (oldWidget.style != widget.style) _syncViewport();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStatusChanged);
    _driver.dispose();
    _morph.dispose();
    super.dispose();
  }

  void _dispatch(PanelEvent event) {
    if (!mounted) return;
    widget.controller.dispatch(event);
  }

  /// Recomputes the viewport and re-places the panel against it.
  ///
  /// Rotation, a resize, split-screen, and the keyboard all arrive here. Because
  /// a placement is resolution-independent the panel keeps its corner and simply
  /// springs to where that corner now is, carrying any velocity it already had.
  void _syncViewport() {
    final next = PanelViewport.of(
      context,
      margin: widget.style.margin,
      avoidKeyboard: widget.behavior.avoidKeyboard,
    );
    widget.controller
      ..behavior = widget.behavior
      ..textDirection = next.direction;

    final changed = _viewport != next;
    _viewport = next;
    _morph.travelPixels = math.max(
      widget.style.collapsedSize.height,
      next.bounds.height * _spec.expandTravelFraction,
    );

    if (!_placed) {
      _placed = true;
      _driver.jumpTo(_originOf(widget.controller.placement));
      return;
    }
    if (!changed) return;

    final target = _originOf(widget.controller.placement);
    if (widget.controller.isDragging) return;
    if (_driver.isAnimating) {
      _driver.retarget(target);
    } else {
      _driver.jumpTo(target);
    }
  }

  Offset _originOf(PanelPlacement placement) => placement.resolve(
    _viewport!,
    _panelSize,
    stashedPeek: widget.style.stashedPeek,
  );

  void _onStatusChanged() {
    final status = widget.controller.value;
    final previous = _previousStatus;
    _haptics.onTransition(
      previous,
      status,
      enabled: widget.behavior.hapticsEnabled,
    );
    _previousStatus = status;
    _followPlacement(previous, status);

    switch (status.phase) {
      case PanelPhase.settling:
        _driver.settle(
          target: _originOf(status.placement),
          velocity: _takeSettleVelocity(),
        );
        if (_morph.value != 0) _morph.settleTo(0);
      case PanelPhase.expanding:
        _morph.settleTo(1, pixelVelocity: _morphReleaseVelocity);
        _morphReleaseVelocity = 0;
      case PanelPhase.collapsing:
        _morph.settleTo(0, pixelVelocity: _morphReleaseVelocity);
        _morphReleaseVelocity = 0;
      case PanelPhase.hidden:
        _morph.jumpTo(0);
      case PanelPhase.collapsed:
      case PanelPhase.expanded:
      case PanelPhase.stashed:
      case PanelPhase.dragging:
        break;
    }
    setState(() {});
  }

  void _onTapUp(TapDragUpDetails details) {
    final controller = widget.controller;
    if (controller.isStashed) {
      controller.unstash();
      return;
    }
    if (widget.behavior.tapToExpand) controller.toggle();
  }

  /// Whether a drag is currently moving the panel.
  ///
  /// An expanded panel is dragged without entering [PanelPhase.dragging]: the
  /// window keeps showing its content while it travels, exactly as a system
  /// Picture-in-Picture window does, so the phase must not be disturbed. Set it
  /// through [_setMoving], which rebuilds — nothing else would.
  bool _isMoving = false;

  /// Where the panel sat when the current drag began.
  Offset _dragOrigin = Offset.zero;

  void _setMoving({required bool moving}) {
    if (_isMoving == moving) return;
    setState(() => _isMoving = moving);
  }

  void _onDragStart(TapDragStartDetails details) {
    if (!widget.behavior.draggable) return;

    _haptics.reset();
    _setMoving(moving: true);
    _carried = _driver.interrupt();
    _carriedAt = SchedulerBinding.instance.currentSystemFrameTimeStamp;
    _raw = _driver.value;
    _dragOrigin = _raw;
    _grab = details.globalPosition - _raw;
    if (!widget.controller.phase.isExpanding) {
      _dispatch(const PanelDragStarted());
    }
  }

  void _onDragUpdate(TapDragUpdateDetails details) {
    if (!_isMoving) return;

    _raw = details.globalPosition - _grab;
    _driver.drive(
      PanelPhysics.resist(
        _raw,
        _dragTravel(),
        _viewport!.size,
        coefficient: _spec.rubberBandCoefficient,
      ),
    );
  }

  /// The range a drag moves through freely, before the rubber band resists.
  ///
  /// A parked panel rests outside the inset bounds, so resisting straight to
  /// them would yank it inwards the moment a drag registers. Extending the
  /// range to wherever the drag began keeps pulling it out one-to-one.
  Rect _dragTravel() {
    final travel = _restingTravel();
    return Rect.fromLTRB(
      math.min(travel.left, _dragOrigin.dx),
      math.min(travel.top, _dragOrigin.dy),
      math.max(travel.right, _dragOrigin.dx),
      math.max(travel.bottom, _dragOrigin.dy),
    );
  }

  /// Where the driver's origin may sit while the panel stays inside its bounds.
  ///
  /// An expanded panel is much larger than the collapsed box the origin
  /// describes, so measuring against the collapsed size lets the finger carry it
  /// far past anywhere it can legally rest.
  Rect _restingTravel() {
    final collapsed = _viewport!.travelFor(_panelSize);
    if (!widget.controller.phase.isExpanding) return collapsed;

    final expanded = _expandedSize;
    if (expanded == null) return collapsed;

    final bounds = _viewport!.bounds;
    final anchor = _anchor();
    final lead = Offset(
      (anchor.x + 1) / 2 * (expanded.width - _panelSize.width),
      (anchor.y + 1) / 2 * (expanded.height - _panelSize.height),
    );
    final left = bounds.left + lead.dx;
    final top = bounds.top + lead.dy;
    return Rect.fromLTRB(
      left,
      top,
      math.max(left, bounds.right - expanded.width + lead.dx),
      math.max(top, bounds.bottom - expanded.height + lead.dy),
    );
  }

  Rect? get _paintedRect {
    final surface = widget.surfaceKey.currentContext?.findRenderObject();
    if (surface is! RenderPanelSurface) return null;
    final rect = surface.paintedRect;
    return rect.isEmpty ? null : rect;
  }

  Size? get _expandedSize {
    final surface = widget.surfaceKey.currentContext?.findRenderObject();
    return surface is RenderPanelSurface ? surface.expandedSize : null;
  }

  void _onDragEnd(TapDragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    if (!_isMoving) return;
    _setMoving(moving: false);

    _settleVelocity = _releaseVelocity(velocity);

    if (widget.behavior.dismissible && _projectsClearOfScreen()) {
      widget.controller.dispatch(const PanelDismissRequested());
      return;
    }

    final rect = _paintedRect ?? _driver.value & _panelSize;
    final target = resolvePanelRelease(
      topLeft: rect.topLeft,
      velocity: _settleVelocity,
      panelSize: rect.size,
      viewport: _viewport!,
      behavior: widget.behavior,
      motion: _spec,
    );

    if (widget.controller.phase.isExpanding) {
      if (target case StashedPlacement(:final edge)) {
        widget.controller.stash(edge);
      } else {
        widget.controller.moveTo(target);
      }
      return;
    }

    widget.controller.dispatch(PanelDragSettled(target));
  }

  /// Rebases the anchor for a new placement, and moves the panel there when
  /// nothing else will.
  ///
  /// Relocating an expanded panel keeps it open, so nothing drives the spring
  /// through [PanelPhase.settling]; this does it instead. A settle drives its
  /// own spring, but still needs the rebase before it starts.
  void _followPlacement(PanelStatus? previous, PanelStatus status) {
    if (previous == null) return;
    if (previous.placement == status.placement) return;
    if (status.isDragging) return;

    _rebaseForAnchor(previous.placement, status.placement);
    if (status.phase == PanelPhase.settling) return;

    final target = _originOf(status.placement);
    final velocity = _takeSettleVelocity();
    if (status.phase == PanelPhase.hidden) {
      _driver.jumpTo(target);
    } else {
      _driver.settle(target: target, velocity: velocity);
    }
  }

  /// Reads the velocity a release left behind, clearing it so one settle
  /// consumes it.
  Offset _takeSettleVelocity() {
    final velocity = _settleVelocity;
    _settleVelocity = Offset.zero;
    return velocity;
  }

  /// Whether the throw would carry the panel entirely off the viewport.
  ///
  /// Requires the whole panel to clear the screen, not merely its edge, so a
  /// hard flick towards a corner can never be mistaken for a dismissal.
  bool _projectsClearOfScreen() {
    final projected = PanelPhysics.projectOffset(
      _driver.value,
      _settleVelocity,
      _spec.decelerationRate,
    );
    return !(projected & _panelSize).overlaps(Offset.zero & _viewport!.size);
  }

  void _onCancel() {
    if (!_isMoving) return;
    _setMoving(moving: false);
    if (widget.controller.isDragging) {
      widget.controller.dispatch(const PanelDragCancelled());
    } else {
      _driver.settle(target: _originOf(widget.controller.placement));
    }
  }

  /// Corrects the raw finger velocity before it enters a spring.
  ///
  /// Momentum captured from an interrupted settle is folded back in with an
  /// exponential decay, and velocity outside the bounds is scaled by the
  /// rubber band's slope — without that the surface visibly changes speed at
  /// the moment the finger lets go.
  Offset _releaseVelocity(Offset finger) {
    final halfLife = _spec.momentumHalfLife.inMicroseconds;
    var combined = finger;
    if (halfLife > 0) {
      final age =
          (SchedulerBinding.instance.currentSystemFrameTimeStamp - _carriedAt)
              .inMicroseconds /
          halfLife;
      combined += _carried * math.exp(-age);
    }

    final over = PanelPhysics.overshootOf(_raw, _dragTravel());
    final size = _viewport!.size;
    return Offset(
      combined.dx *
          PanelPhysics.rubberBandSlope(
            over.dx,
            size.width,
            coefficient: _spec.rubberBandCoefficient,
          ),
      combined.dy *
          PanelPhysics.rubberBandSlope(
            over.dy,
            size.height,
            coefficient: _spec.rubberBandCoefficient,
          ),
    );
  }

  /// Shifts the driver so a change of anchor leaves the painted rect alone.
  ///
  /// The origin describes the collapsed box, and the expanded rect hangs off it
  /// by the anchor. Swapping the anchor therefore moves the rect by the whole
  /// difference in size the instant the placement changes — the panel jumps a
  /// window's width, then springs back over it.
  void _rebaseForAnchor(PanelPlacement from, PanelPlacement to) {
    final expansion = panelSizeProgress(
      _morph.value,
      reduceMotion: _spec.reduceMotion,
    ).clamp(0.0, 1.0);
    if (expansion <= 0) return;

    final expanded = _expandedSize;
    if (expanded == null) return;

    final before = _anchorOf(from);
    final after = _anchorOf(to);
    if (before == after) return;

    final shift = Offset(
      (after.x - before.x) / 2 * (expanded.width - _panelSize.width),
      (after.y - before.y) / 2 * (expanded.height - _panelSize.height),
    );
    _driver.jumpTo(_driver.value + shift * expansion);
  }

  Alignment _anchor() => _anchorOf(widget.controller.placement);

  Alignment _anchorOf(PanelPlacement placement) {
    final direction = _viewport!.direction;
    return switch (placement) {
      CornerPlacement(:final corner) => corner.resolve(direction),
      StashedPlacement(:final edge, :final verticalAlignment) => Alignment(
        edge.resolveX(direction),
        verticalAlignment.clamp(-1.0, 1.0),
      ),
      FreePlacement(:final alignment) => alignment.resolve(direction),
    };
  }

  /// Moves the panel one corner in [direction], if there is one that way.
  void _moveByKeyboard(AxisDirection direction) {
    final placement = widget.controller.placement;
    if (placement is! CornerPlacement) {
      widget.controller.moveTo(
        const PanelPlacement.corner(PanelCorner.bottomEnd),
      );
      return;
    }
    final next = placement.corner.neighbour(direction, _viewport!.direction);
    if (next != null) widget.controller.moveTo(PanelPlacement.corner(next));
  }

  void _dismissByKeyboard() {
    final controller = widget.controller;
    if (controller.phase.isExpanding) {
      controller.collapse();
    } else if (widget.behavior.stashable && !controller.isStashed) {
      controller.stash();
    }
  }

  /// Custom actions are the only way a four-corner drag model is operable
  /// without dragging; they surface in VoiceOver's rotor and TalkBack's menu.
  Map<CustomSemanticsAction, VoidCallback> _customActions() {
    final labels = widget.semantics;
    final actions = <CustomSemanticsAction, VoidCallback>{};

    if (widget.controller.isStashed) {
      actions[CustomSemanticsAction(label: labels.unstashAction)] =
          widget.controller.unstash;
    } else {
      if (widget.behavior.stashable) {
        actions[CustomSemanticsAction(label: labels.stashAction)] =
            widget.controller.stash;
      }
      for (final corner in PanelCorner.values) {
        if (widget.controller.placement == PanelPlacement.corner(corner)) {
          continue;
        }
        final name = labels.nameOf(corner);
        actions[CustomSemanticsAction(
          label: '${labels.moveActionPrefix} $name',
        )] = () =>
            widget.controller.moveTo(PanelPlacement.corner(corner));
      }
    }
    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    final settings = media?.gestureSettings;
    // Screen readers own drag gestures, so free dragging is unusable there.
    final assistive = media?.accessibleNavigation ?? false;

    // Not FocusableActionDetector: its MouseRegion is opaque to hit testing.
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowUp): _PanelMoveIntent(
          AxisDirection.up,
        ),
        SingleActivator(LogicalKeyboardKey.arrowDown): _PanelMoveIntent(
          AxisDirection.down,
        ),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _PanelMoveIntent(
          AxisDirection.left,
        ),
        SingleActivator(LogicalKeyboardKey.arrowRight): _PanelMoveIntent(
          AxisDirection.right,
        ),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => widget.controller.toggle(),
          ),
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) => _dismissByKeyboard(),
          ),
          _PanelMoveIntent: CallbackAction<_PanelMoveIntent>(
            onInvoke: (intent) => _moveByKeyboard(intent.direction),
          ),
        },
        child: Focus(
          debugLabel: 'DraggablePanel',
          child: _buildGestures(settings, assistive: assistive),
        ),
      ),
    );
  }

  /// Annotates whichever face is currently showing.
  ///
  /// The annotation sits on the content rather than on this full-screen host,
  /// so the semantics node reports the panel's own rect instead of claiming the
  /// whole screen. The face that is not showing is excluded outright.
  Widget _annotate(Widget child, {required bool active}) {
    if (!active) return ExcludeSemantics(child: child);

    final phase = widget.controller.phase;
    return Semantics(
      container: true,
      explicitChildNodes: phase.isExpanding,
      button: !phase.isExpanding,
      label: widget.semantics.label,
      hint: phase.isExpanding
          ? widget.semantics.collapseHint
          : widget.semantics.expandHint,
      onTap: widget.behavior.tapToExpand ? widget.controller.toggle : null,
      onDismiss: phase.isExpanding ? widget.controller.collapse : null,
      customSemanticsActions: _customActions(),
      child: child,
    );
  }

  /// Halves the platform slop for this panel.
  ///
  /// [DeviceGestureSettings.panSlop] derives from the touch slop at twice its
  /// value — 36 logical pixels by default, tuned for committing to a scroll
  /// axis. A parked panel has less travel than that between its tab and its
  /// resting place, so at the platform value the whole pull-out is spent before
  /// the drag registers.
  DeviceGestureSettings _panelGestureSettings(
    DeviceGestureSettings? settings,
  ) =>
      DeviceGestureSettings(touchSlop: (settings?.touchSlop ?? kTouchSlop) / 2);

  Widget _buildGestures(
    DeviceGestureSettings? settings, {
    required bool assistive,
  }) {
    if (assistive) return _buildSurface();

    return RawGestureDetector(
      behavior: HitTestBehavior.deferToChild,
      gestures: <Type, GestureRecognizerFactory>{
        TapAndPanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapAndPanGestureRecognizer>(
              TapAndPanGestureRecognizer.new,
              (instance) => instance
                // DragStartBehavior.start reports position at arena win.
                ..dragStartBehavior = DragStartBehavior.down
                ..gestureSettings = _panelGestureSettings(settings)
                ..onTapUp = _onTapUp
                ..onDragStart = _onDragStart
                ..onDragUpdate = _onDragUpdate
                ..onDragEnd = _onDragEnd
                ..onCancel = _onCancel,
            ),
      },
      child: _buildSurface(),
    );
  }

  Widget _buildSurface() {
    final phase = widget.controller.phase;
    return PanelSurface(
      key: widget.surfaceKey,
      repaint: _repaint,
      style: widget.style,
      originOf: () => _driver.value,
      expansionOf: () => _morph.value,
      anchor: _anchor(),
      bounds: _boundsInsets(),
      isDragging: _isMoving,
      isStashed: phase == PanelPhase.stashed,
      isParking: widget.controller.placement is StashedPlacement,
      reduceMotion: _spec.reduceMotion,
      opacity: _opacityFor(phase),
      collapsed: RepaintBoundary(
        child: _surfaceContent(
          _annotate(widget.collapsed, active: !phase.isExpanding),
        ),
      ),
      expanded: RepaintBoundary(
        child: _surfaceContent(
          _annotate(widget.expanded, active: phase.isExpanding),
        ),
      ),
      handle: RepaintBoundary(
        child: ExcludeSemantics(child: widget.handle(context, _handleEdge())),
      ),
    );
  }

  /// Which edge the panel is resting against, as a directional edge.
  ///
  /// Derived from the resolved anchor rather than read off the placement, so a
  /// panel dragged out of a park keeps pointing the way it came out.
  PanelEdge _handleEdge() {
    final onLeft = _anchor().x < 0;
    final startIsLeft = _viewport!.direction == TextDirection.ltr;
    return onLeft == startIsLeft ? PanelEdge.start : PanelEdge.end;
  }

  /// Gives caller-supplied content the Material context it expects.
  ///
  /// The panel paints its own surface, so without this a bare [Text] inside a
  /// builder falls back to [DefaultTextStyle.fallback] and renders as oversized
  /// debug type. Transparency keeps the painted surface visible while still
  /// providing a text style, an icon theme, and a target for ink.
  Widget _surfaceContent(Widget child) =>
      Material(type: MaterialType.transparency, child: child);

  /// Visibility alone. `stashedOpacity` is deliberately absent: a phase is a
  /// step, and stepping the alpha while the panel is still sliding into the
  /// edge reads as a flicker. The surface folds the parked fade in along the
  /// frame's emergence instead.
  double _opacityFor(PanelPhase phase) => phase == PanelPhase.hidden ? 0 : 1;

  /// The viewport's usable rect, expressed as insets from this widget's box.
  EdgeInsets _boundsInsets() {
    final viewport = _viewport!;
    final bounds = viewport.bounds;
    return EdgeInsets.fromLTRB(
      bounds.left,
      bounds.top,
      viewport.size.width - bounds.right,
      viewport.size.height - bounds.bottom,
    );
  }
}

/// Moves the panel one corner in a direction, from the keyboard.
@immutable
final class _PanelMoveIntent extends Intent {
  const _PanelMoveIntent(this.direction);

  final AxisDirection direction;
}
