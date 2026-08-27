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
    this.icon = Icons.apps,
    this.theme,
    this.actionTheme,
    this.behavior = const PanelBehavior(),
    this.semantics = const PanelSemantics(),
    this.collapsedBuilder,
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
  final IconData icon;

  final DraggablePanelThemeData? theme;
  final DraggableActionPanelThemeData? actionTheme;
  final PanelBehavior behavior;
  final PanelSemantics semantics;

  /// Replaces the collapsed face entirely.
  final PanelChildBuilder? collapsedBuilder;

  final ValueChanged<PanelStatus>? onStatusChanged;
  final ValueChanged<PanelPlacement>? onPlacementChanged;

  @override
  Widget build(BuildContext context) => DraggablePanel(
    controller: controller,
    theme: theme,
    behavior: behavior,
    semantics: semantics,
    onStatusChanged: onStatusChanged,
    onPlacementChanged: onPlacementChanged,
    collapsedBuilder:
        collapsedBuilder ??
        (context, status) => Center(
          child: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
        ),
    expandedBuilder: (context, status) => ActionPanelContent(
      actions: actions,
      buttons: buttons,
      theme: DraggableActionPanelThemeData.resolve(context, actionTheme),
    ),
    child: child,
  );
}
