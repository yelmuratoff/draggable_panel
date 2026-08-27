import 'package:draggable_panel/src/presets/action_panel/action_panel_theme_data.dart';
import 'package:draggable_panel/src/presets/action_panel/panel_action.dart';
import 'package:flutter/material.dart';

/// The expanded content of a `DraggableActionPanel`: a grid of icon actions
/// above a column of labelled buttons.
final class ActionPanelContent extends StatelessWidget {
  const ActionPanelContent({
    required this.actions,
    required this.buttons,
    required this.theme,
    super.key,
  });

  final List<PanelAction> actions;
  final List<PanelActionButton> buttons;
  final DraggableActionPanelThemeData theme;

  /// Balances the grid so the last row is not left nearly empty — five actions
  /// across a four-wide grid read better as `3 + 2` than as `4 + 1`.
  int get _columns {
    final maxColumns = theme.maxColumns ?? 4;
    if (actions.length <= maxColumns) return actions.length;
    final rows = (actions.length / maxColumns).ceil();
    return (actions.length / rows).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = theme.actionSpacing ?? 8;
    final rows = <List<PanelAction>>[];
    for (var start = 0; start < actions.length; start += _columns) {
      rows.add(
        actions.sublist(start, (start + _columns).clamp(0, actions.length)),
      );
    }

    return Padding(
      padding: theme.contentPadding ?? const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final row in rows) ...[
            if (row != rows.first) SizedBox(height: spacing),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final action in row) ...[
                  if (action != row.first) SizedBox(width: spacing),
                  ActionCell(action: action, theme: theme),
                ],
              ],
            ),
          ],
          if (actions.isNotEmpty && buttons.isNotEmpty)
            SizedBox(height: theme.sectionSpacing ?? 12),
          for (final button in buttons) ...[
            if (button != buttons.first)
              SizedBox(height: theme.buttonSpacing ?? 8),
            ActionButtonRow(button: button, theme: theme),
          ],
        ],
      ),
    );
  }
}

/// One icon action, with its optional badge.
final class ActionCell extends StatelessWidget {
  const ActionCell({required this.action, required this.theme, super.key});

  final PanelAction action;
  final DraggableActionPanelThemeData theme;

  @override
  Widget build(BuildContext context) {
    final size = theme.actionSize ?? 48;
    final shape =
        theme.actionShape ??
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        );
    final foreground =
        action.foregroundColor ??
        theme.actionForegroundColor ??
        Theme.of(context).colorScheme.onSecondaryContainer;

    Widget cell = SizedBox(
      width: size,
      height: size,
      child: Material(
        color:
            action.color ??
            theme.actionBackgroundColor ??
            Theme.of(context).colorScheme.secondaryContainer,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: action.onPressed,
          child: Icon(action.icon, color: foreground, size: size * 0.5),
        ),
      ),
    );

    if (action.badge case final badge?) {
      cell = Badge(
        label: badge.label == null ? null : Text(badge.label!),
        backgroundColor: badge.color ?? theme.badgeColor,
        child: cell,
      );
    }

    return Tooltip(
      message: action.tooltip ?? '',
      child: Semantics(button: true, label: action.tooltip, child: cell),
    );
  }
}

/// One labelled, full-width action button.
final class ActionButtonRow extends StatelessWidget {
  const ActionButtonRow({required this.button, required this.theme, super.key});

  final PanelActionButton button;
  final DraggableActionPanelThemeData theme;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: button.tooltip ?? '',
    child: FilledButton.tonalIcon(
      onPressed: button.onPressed,
      icon: Icon(button.icon),
      label: Text(
        button.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.buttonLabelStyle,
      ),
    ),
  );
}
