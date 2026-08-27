import 'dart:math' as math;

import 'package:draggable_panel/src/presets/action_panel/action_panel_theme_data.dart';
import 'package:draggable_panel/src/presets/action_panel/panel_action.dart';
import 'package:flutter/material.dart';

/// Builds one action's cell, replacing [ActionCell].
typedef PanelActionBuilder =
    Widget Function(BuildContext context, PanelAction action);

/// Builds one button's row, replacing [ActionButtonRow].
typedef PanelActionButtonBuilder =
    Widget Function(BuildContext context, PanelActionButton button);

/// The expanded content of a `DraggableActionPanel`: an optional header, a grid
/// of icon actions, and a column of labelled buttons.
final class ActionPanelContent extends StatelessWidget {
  const ActionPanelContent({
    required this.actions,
    required this.buttons,
    required this.theme,
    super.key,
    this.title,
    this.onClose,
    this.headerBuilder,
    this.actionBuilder,
    this.buttonBuilder,
  });

  final List<PanelAction> actions;
  final List<PanelActionButton> buttons;
  final DraggableActionPanelThemeData theme;

  final String? title;
  final VoidCallback? onClose;

  final WidgetBuilder? headerBuilder;
  final PanelActionBuilder? actionBuilder;
  final PanelActionButtonBuilder? buttonBuilder;

  /// How many columns the grid uses.
  ///
  /// A row fills to [DraggableActionPanelThemeData.maxColumns] before the next
  /// one starts, and the count never exceeds the actions there are — so a panel
  /// holding two is two cells wide rather than a mostly empty four.
  int get _columns => math.min(actions.length, theme.maxColumns ?? 4);

  bool get _hasHeader =>
      headerBuilder != null || title != null || onClose != null;

  @override
  Widget build(BuildContext context) {
    final spacing = theme.actionSpacing ?? 8;
    final columns = _columns;

    return Padding(
      padding: theme.contentPadding ?? const EdgeInsets.all(12),
      // CrossAxisAlignment.stretch gives children the full offered width.
      child: IntrinsicWidth(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_hasHeader) ...[
                headerBuilder?.call(context) ??
                    ActionPanelHeader(
                      title: title,
                      onClose: onClose,
                      theme: theme,
                    ),
                SizedBox(height: theme.headerSpacing ?? 12),
              ],
              for (var start = 0; start < actions.length; start += columns) ...[
                if (start > 0) SizedBox(height: spacing),
                _GridRow(
                  row: actions.sublist(
                    start,
                    (start + columns).clamp(0, actions.length),
                  ),
                  columns: columns,
                  spacing: spacing,
                  theme: theme,
                  actionBuilder: actionBuilder,
                ),
              ],
              if (actions.isNotEmpty && buttons.isNotEmpty)
                SizedBox(height: theme.sectionSpacing ?? 12),
              for (final button in buttons) ...[
                if (button != buttons.first)
                  SizedBox(height: theme.buttonSpacing ?? 8),
                buttonBuilder?.call(context, button) ??
                    ActionButtonRow(button: button, theme: theme),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One grid row, split into [columns] equal shares.
///
/// Every cell takes the same fraction of the row whether or not the row is
/// full, so columns line up down the grid and a full row leaves no gap at its
/// trailing end.
final class _GridRow extends StatelessWidget {
  const _GridRow({
    required this.row,
    required this.columns,
    required this.spacing,
    required this.theme,
    required this.actionBuilder,
  });

  final List<PanelAction> row;
  final int columns;
  final double spacing;
  final DraggableActionPanelThemeData theme;
  final PanelActionBuilder? actionBuilder;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final action in row) ...[
        if (action != row.first) SizedBox(width: spacing),
        Expanded(
          child: Center(
            child:
                actionBuilder?.call(context, action) ??
                ActionCell(action: action, theme: theme),
          ),
        ),
      ],
      if (row.length < columns) ...[
        SizedBox(width: spacing),
        Spacer(flex: columns - row.length),
      ],
    ],
  );
}

/// The title row above the grid, with an optional close control.
final class ActionPanelHeader extends StatelessWidget {
  const ActionPanelHeader({
    required this.theme,
    super.key,
    this.title,
    this.onClose,
  });

  final DraggableActionPanelThemeData theme;
  final String? title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (title case final title?)
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  theme.headerStyle ??
                  Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: scheme.onSurface),
            ),
          )
        else
          const Spacer(),
        if (onClose case final onClose?)
          IconButton(
            onPressed: onClose,
            visualDensity: VisualDensity.compact,
            iconSize: 20,
            color: scheme.onSurfaceVariant,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(Icons.close_rounded),
          ),
      ],
    );
  }
}

/// One icon action: a tile, its optional badge, and its optional caption.
final class ActionCell extends StatelessWidget {
  const ActionCell({required this.action, required this.theme, super.key});

  final PanelAction action;
  final DraggableActionPanelThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = theme.actionSize ?? 48;
    final foreground =
        action.foregroundColor ??
        theme.actionForegroundColor ??
        scheme.onSurfaceVariant;

    final glyph = Icon(
      action.icon,
      color: foreground,
      size: theme.actionIconSize ?? size * 0.5,
    );

    Widget tile = SizedBox.square(
      dimension: size,
      child: Material(
        color:
            action.color ??
            theme.actionBackgroundColor ??
            scheme.surfaceContainerLowest,
        shape:
            theme.actionShape ??
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: action.onPressed,
          child: Center(child: glyph),
        ),
      ),
    );

    if (action.badge case final badge?) {
      tile = Stack(
        children: [
          tile,
          PositionedDirectional(
            top: 0,
            end: 0,
            child: IgnorePointer(
              child: Badge(
                label: badge.label == null ? null : Text(badge.label!),
                backgroundColor: badge.color ?? theme.badgeColor,
                largeSize: theme.badgeSize,
                smallSize: theme.badgeDotSize,
              ),
            ),
          ),
        ],
      );
    }

    return Tooltip(
      message: action.tooltip ?? action.label ?? '',
      child: Semantics(
        button: true,
        label: action.tooltip ?? action.label,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            tile,
            if (action.label case final label?) ...[
              SizedBox(height: theme.actionLabelSpacing ?? 6),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: theme.actionLabelMaxWidth ?? size * 2,
                ),
                child: Text(
                  label,
                  maxLines: theme.actionLabelMaxLines ?? 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style:
                      theme.actionLabelStyle ??
                      Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: foreground),
                ),
              ),
            ],
          ],
        ),
      ),
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
      style: theme.buttonStyle,
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
