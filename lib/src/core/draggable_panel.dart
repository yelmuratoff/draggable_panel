import 'package:draggable_panel/src/controller/draggable_panel_controller.dart';
import 'package:draggable_panel/src/core/draggable_panel_scope.dart';
import 'package:draggable_panel/src/core/panel_host.dart';
import 'package:draggable_panel/src/core/panel_semantics.dart';
import 'package:draggable_panel/src/model/panel_behavior.dart';
import 'package:draggable_panel/src/model/panel_placement.dart';
import 'package:draggable_panel/src/model/panel_status.dart';
import 'package:draggable_panel/src/motion/panel_motion_spec.dart';
import 'package:draggable_panel/src/theme/draggable_panel_theme_data.dart';
import 'package:draggable_panel/src/theme/panel_style.dart';
import 'package:flutter/widgets.dart';

/// Builds one of the panel's two faces.
typedef PanelChildBuilder =
    Widget Function(BuildContext context, PanelStatus status);

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

  @override
  void initState() {
    super.initState();
    _attach(widget.controller);
  }

  @override
  void didUpdateWidget(DraggablePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.controller, widget.controller)) return;
    _detach();
    _attach(widget.controller);
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
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

  void _onStatus() => widget.onStatusChanged?.call(_controller.value);

  void _onPlacement() =>
      widget.onPlacementChanged?.call(_controller.placementListenable.value);

  @override
  Widget build(BuildContext context) {
    final style = PanelStyle.resolve(context, _resolveTheme(context));

    return DraggablePanelScope(
      controller: _controller,
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
          ListenableBuilder(
            listenable: _controller.phaseListenable,
            builder: (context, _) => PanelHost(
              controller: _controller,
              behavior: widget.behavior,
              style: style,
              semantics: widget.semantics,
              collapsed: widget.collapsedBuilder(context, _controller.value),
              expanded: widget.expandedBuilder(context, _controller.value),
            ),
          ),
        ],
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
