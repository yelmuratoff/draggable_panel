import 'dart:async';

import 'package:draggable_panel/src/controller/draggable_panel_controller.dart';
import 'package:draggable_panel/src/core/draggable_panel_scope.dart';
import 'package:draggable_panel/src/core/panel_edge_handle.dart';
import 'package:draggable_panel/src/core/panel_host.dart';
import 'package:draggable_panel/src/core/panel_semantics.dart';
import 'package:draggable_panel/src/core/render_panel_surface.dart';
import 'package:draggable_panel/src/model/panel_behavior.dart';
import 'package:draggable_panel/src/model/panel_edge.dart';
import 'package:draggable_panel/src/model/panel_phase.dart';
import 'package:draggable_panel/src/model/panel_placement.dart';
import 'package:draggable_panel/src/model/panel_status.dart';
import 'package:draggable_panel/src/motion/panel_motion_spec.dart';
import 'package:draggable_panel/src/theme/draggable_panel_theme_data.dart';
import 'package:draggable_panel/src/theme/panel_style.dart';
import 'package:flutter/widgets.dart';

/// Builds one of the panel's two faces.
typedef PanelChildBuilder =
    Widget Function(BuildContext context, PanelStatus status);

/// Builds the grab affordance shown on a panel parked against [edge].
typedef PanelHandleBuilder =
    Widget Function(BuildContext context, PanelEdge edge);

/// A floating panel that behaves like a system Picture-in-Picture window.
///
/// Collapsed, it is a small window that can be dragged anywhere and springs to
/// the nearest corner when released, chosen by where its momentum was heading.
/// Flung past a side edge it parks off-screen with a grab tab showing. Tapped,
/// it grows in place into the expanded panel, anchored at the corner it already
/// occupies; dragged down while expanded, it shrinks back.
///
/// Install it above the app's own content, typically through
/// `MaterialApp.builder`:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => DraggablePanel(
///     collapsedBuilder: (context, status) => const Icon(Icons.play_arrow),
///     expandedBuilder: (context, status) => const MiniPlayer(),
///     child: child,
///   ),
/// )
/// ```
///
/// The panel paints above [child] but within the same subtree, so a route
/// pushed on top of the app covers it.
@immutable
final class DraggablePanel extends StatefulWidget {
  const DraggablePanel({
    required this.collapsedBuilder,
    required this.expandedBuilder,
    super.key,
    this.child,
    this.controller,
    this.theme,
    this.handleBuilder,
    this.behavior = const PanelBehavior(),
    this.semantics = const PanelSemantics(),
    this.onStatusChanged,
    this.onPlacementChanged,
  });

  /// The application content the panel floats above.
  ///
  /// Never rebuilt by the panel's own motion.
  final Widget? child;

  /// Builds the small, collapsed face of the panel.
  final PanelChildBuilder collapsedBuilder;

  /// Builds the large, expanded face of the panel.
  final PanelChildBuilder expandedBuilder;

  /// Drives the panel from outside. One is created internally when omitted.
  final DraggablePanelController? controller;

  /// Call-site tokens, laid over any [DraggablePanelThemeData] in
  /// [ThemeData.extensions] and the built-in defaults.
  final DraggablePanelThemeData? theme;

  /// Builds the grab affordance on the sliver a parked panel leaves showing.
  ///
  /// It slides out through the edge as [collapsedBuilder]'s content arrives.
  /// Defaults to a [PanelEdgeHandle] tinted by
  /// `DraggablePanelThemeData.handleColor`.
  final PanelHandleBuilder? handleBuilder;

  /// Which interactions the panel accepts.
  final PanelBehavior behavior;

  /// What the panel announces to assistive technology. Localize these.
  final PanelSemantics semantics;

  /// Called when the panel's phase changes — a handful of times per gesture,
  /// never per frame.
  final ValueChanged<PanelStatus>? onStatusChanged;

  /// Called when the panel comes to rest somewhere new.
  ///
  /// Never fires mid-drag, and a [PanelPlacement] survives rotation, so this is
  /// safe to persist directly.
  final ValueChanged<PanelPlacement>? onPlacementChanged;

  @override
  State<DraggablePanel> createState() => _DraggablePanelState();
}

class _DraggablePanelState extends State<DraggablePanel> {
  late DraggablePanelController _controller;
  bool _ownsController = false;

  final GlobalKey _surfaceKey = GlobalKey();
  Timer? _idle;

  @override
  void initState() {
    super.initState();
    _attach(widget.controller);
    _restartIdle();
  }

  @override
  void didUpdateWidget(DraggablePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.behavior != widget.behavior) _restartIdle();
    if (identical(oldWidget.controller, widget.controller)) return;
    _detach();
    _attach(widget.controller);
    _restartIdle();
  }

  @override
  void dispose() {
    _idle?.cancel();
    _detach();
    super.dispose();
  }

  /// Arms the inactivity timer, or cancels it while the panel is not out.
  void _restartIdle() {
    _idle?.cancel();
    _idle = null;

    final delay = widget.behavior.idleStashDelay;
    if (delay == null || !widget.behavior.stashable) return;
    if (_controller.phase != PanelPhase.collapsed) return;

    _idle = Timer(delay, () {
      if (!mounted || _controller.phase != PanelPhase.collapsed) return;
      _controller.stash();
    });
  }

  /// Treats a touch anywhere as activity, and one off the panel as dismissal.
  ///
  /// A [Listener] never enters the gesture arena, so whatever was tapped still
  /// receives its own gesture.
  void _onPointerDown(PointerDownEvent event) {
    _restartIdle();

    if (!widget.behavior.stashOnTapOutside) return;
    if (!widget.behavior.stashable) return;
    if (_controller.phase != PanelPhase.collapsed) return;
    if (_panelRect()?.contains(event.position) ?? false) return;

    _controller.stash();
  }

  Rect? _panelRect() {
    final surface = _surfaceKey.currentContext?.findRenderObject();
    return surface is RenderPanelSurface ? surface.paintedRect : null;
  }

  void _attach(DraggablePanelController? controller) {
    _ownsController = controller == null;
    _controller = controller ?? DraggablePanelController();
    _controller
      ..behavior = widget.behavior
      ..addListener(_onStatus);
    _controller.placementListenable.addListener(_onPlacement);
  }

  void _detach() {
    _controller
      ..removeListener(_onStatus)
      ..placementListenable.removeListener(_onPlacement);
    if (_ownsController) _controller.dispose();
  }

  void _onStatus() {
    _restartIdle();
    widget.onStatusChanged?.call(_controller.value);
  }

  void _onPlacement() =>
      widget.onPlacementChanged?.call(_controller.placementListenable.value);

  @override
  Widget build(BuildContext context) {
    final style = PanelStyle.resolve(context, _resolveTheme(context));

    return DraggablePanelScope(
      controller: _controller,
      child: Listener(
        onPointerDown: _onPointerDown,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.child case final child?) child,
            if (widget.behavior.collapseOnTapOutside)
              ListenableBuilder(
                listenable: _controller.phaseListenable,
                builder: (context, _) => _controller.phase.isExpanding
                    ? GestureDetector(
                        onTap: _controller.collapse,
                        behavior: HitTestBehavior.opaque,
                      )
                    : const SizedBox.shrink(),
              ),
            // MaterialApp.builder wraps the Navigator that owns the Overlay.
            Overlay.wrap(
              clipBehavior: Clip.none,
              child: ListenableBuilder(
                listenable: _controller.phaseListenable,
                builder: (context, _) => PanelHost(
                  controller: _controller,
                  behavior: widget.behavior,
                  style: style,
                  semantics: widget.semantics,
                  collapsed: widget.collapsedBuilder(
                    context,
                    _controller.value,
                  ),
                  expanded: widget.expandedBuilder(context, _controller.value),
                  handle:
                      widget.handleBuilder ??
                      (context, edge) => PanelEdgeHandle(
                        color: style.handleColor,
                        curveSize: style.handleSize,
                        strokeWidth: style.handleStrokeWidth,
                        pointsTowardStart: !edge.resolvesToLeft(
                          Directionality.of(context),
                        ),
                      ),
                  surfaceKey: _surfaceKey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Folds the reduced-motion preference into the resolved motion spec.
  DraggablePanelThemeData? _resolveTheme(BuildContext context) {
    if (!MediaQuery.disableAnimationsOf(context)) return widget.theme;
    final base = widget.theme ?? const DraggablePanelThemeData();
    return base.copyWith(motion: PanelMotionSpec.reduced());
  }
}
