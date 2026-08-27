import 'package:draggable_panel/src/controller/draggable_panel_controller.dart';
import 'package:draggable_panel/src/core/draggable_panel.dart';
import 'package:draggable_panel/src/core/panel_semantics.dart';
import 'package:draggable_panel/src/model/panel_behavior.dart';
import 'package:draggable_panel/src/model/panel_placement.dart';
import 'package:draggable_panel/src/model/panel_status.dart';
import 'package:draggable_panel/src/presets/action_panel/action_grid.dart';
import 'package:draggable_panel/src/presets/action_panel/action_panel_theme_data.dart';
import 'package:draggable_panel/src/presets/action_panel/panel_action.dart';
import 'package:draggable_panel/src/theme/draggable_panel_theme_data.dart';
import 'package:flutter/material.dart';

/// A [DraggablePanel] preset that expands into a grid of icon actions above a
/// column of labelled buttons — the shape a debug or tools panel usually takes.
///
/// Built entirely on [DraggablePanel]'s public API. If this ever needed
/// privileged access to the core, that would be a sign the core's API is
/// missing something rather than a reason to add a back door.
///
/// ```dart
/// DraggableActionPanel(
///   actions: [
///     PanelAction(icon: Icons.bug_report, onPressed: openLogs),
///   ],
///   child: child,
/// )
/// ```
@immutable
final class DraggableActionPanel extends StatelessWidget {
  const DraggableActionPanel({
    super.key,
    this.actions = const [],
    this.buttons = const [],
    this.child,
    this.controller,
    this.icon = Icons.zoom_out_map_rounded,
    this.title,
    this.onClose,
    this.theme,
    this.actionTheme,
    this.behavior = const PanelBehavior(),
    this.semantics = const PanelSemantics(),
    this.collapsedBuilder,
    this.handleBuilder,
    this.headerBuilder,
    this.actionBuilder,
    this.buttonBuilder,
    this.expandedBuilder,
    this.onStatusChanged,
    this.onPlacementChanged,
  });

  /// Icon actions, laid out in a balanced grid.
  final List<PanelAction> actions;

  /// Full-width labelled buttons, below the grid.
  final List<PanelActionButton> buttons;

  final Widget? child;
  final DraggablePanelController? controller;

  /// Icon shown while collapsed. Ignored when [collapsedBuilder] is given.
  ///
  /// The default says what a tap does rather than what the panel holds, since
  /// the preset's contents are the caller's.
  final IconData icon;

  /// Title shown in the header. A header appears when this, [onClose], or
  /// [headerBuilder] is set.
  final String? title;

  /// Invoked by the header's close control.
  final VoidCallback? onClose;

  final DraggablePanelThemeData? theme;
  final DraggableActionPanelThemeData? actionTheme;
  final PanelBehavior behavior;
  final PanelSemantics semantics;

  /// Replaces the collapsed face entirely.
  final PanelChildBuilder? collapsedBuilder;

  /// Replaces the grab affordance shown while the panel is parked at an edge.
  final PanelHandleBuilder? handleBuilder;

  /// Replaces the header row.
  final WidgetBuilder? headerBuilder;

  /// Replaces one grid cell, keeping the grid's own layout.
  final PanelActionBuilder? actionBuilder;

  /// Replaces one button row.
  final PanelActionButtonBuilder? buttonBuilder;

  /// Replaces the expanded face entirely, ignoring every other content field.
  final PanelChildBuilder? expandedBuilder;

  final ValueChanged<PanelStatus>? onStatusChanged;
  final ValueChanged<PanelPlacement>? onPlacementChanged;

  @override
  Widget build(BuildContext context) => DraggablePanel(
    controller: controller,
    theme: theme,
    behavior: behavior,
    semantics: semantics,
    handleBuilder: handleBuilder,
    onStatusChanged: onStatusChanged,
    onPlacementChanged: onPlacementChanged,
    collapsedBuilder:
        collapsedBuilder ??
        (context, status) {
          final theme = DraggableActionPanelThemeData.resolve(
            context,
            actionTheme,
          );
          return Center(
            child: Icon(
              icon,
              color: theme.collapsedIconColor,
              size: theme.collapsedIconSize,
            ),
          );
        },
    expandedBuilder:
        expandedBuilder ??
        (context, status) => ActionPanelContent(
          actions: actions,
          buttons: buttons,
          title: title,
          onClose: onClose,
          headerBuilder: headerBuilder,
          actionBuilder: actionBuilder,
          buttonBuilder: buttonBuilder,
          theme: DraggableActionPanelThemeData.resolve(context, actionTheme),
        ),
    child: child,
  );
}
