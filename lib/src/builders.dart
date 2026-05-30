import 'package:draggable_panel/src/models/panel_button.dart';
import 'package:draggable_panel/src/models/panel_item.dart';
import 'package:draggable_panel/src/theme/draggable_panel_button_theme_data.dart';
import 'package:draggable_panel/src/theme/draggable_panel_item_theme_data.dart';
import 'package:draggable_panel/src/theme/draggable_panel_theme.dart';
import 'package:draggable_panel/src/theme/draggable_panel_tooltip_theme_data.dart';
import 'package:flutter/widgets.dart';

/// Builds custom content for a panel item, replacing the default icon.
///
/// The cell shell, tap/long-press handling, and badge are still provided by the
/// panel. Use [DraggablePanelItemFrameBuilder] to replace the shell as well.
typedef DraggablePanelItemBuilder = Widget Function(
  BuildContext context,
  DraggablePanelItem item,
);

/// Builds custom content for a panel action button, replacing the default
/// icon + label row. The button shell is still provided by the panel.
typedef DraggablePanelButtonBuilder = Widget Function(
  BuildContext context,
  DraggablePanelButtonItem button,
);

/// Builds the entire draggable button content, replacing the default handle /
/// drag indicator.
typedef DraggablePanelHandleBuilder = Widget Function(
  BuildContext context, {
  required bool isDragging,
  required bool isDockedRight,
});

/// Everything needed to render a fully custom item cell, including its shell.
@immutable
class DraggablePanelItemRender {
  const DraggablePanelItemRender({
    required this.item,
    required this.content,
    required this.onTap,
    required this.color,
    required this.foregroundColor,
    required this.itemTheme,
    this.onLongPress,
  });

  /// The item being rendered.
  final DraggablePanelItem item;

  /// The resolved content (custom item content or the default icon).
  final Widget content;

  /// Tap handler that runs the item's `onTap` and closes the panel.
  final VoidCallback onTap;

  /// Long-press handler (shows the tooltip), or null when there is none.
  final VoidCallback? onLongPress;

  /// Resolved cell background color (per-item override or panel default).
  final Color color;

  /// Resolved foreground color (per-item override or panel default).
  final Color foregroundColor;

  /// Resolved item theme.
  final DraggablePanelItemThemeData itemTheme;
}

/// Builds a fully custom item cell from a [DraggablePanelItemRender].
typedef DraggablePanelItemFrameBuilder = Widget Function(
  BuildContext context,
  DraggablePanelItemRender render,
);

/// Everything needed to render a fully custom action button, including its shell.
@immutable
class DraggablePanelButtonRender {
  const DraggablePanelButtonRender({
    required this.button,
    required this.content,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.buttonTheme,
    this.onLongPress,
  });

  /// The button being rendered.
  final DraggablePanelButtonItem button;

  /// The resolved content (custom button content or the default icon + label).
  final Widget content;

  /// Tap handler that runs the button's `onTap`.
  final VoidCallback onTap;

  /// Long-press handler (shows the tooltip), or null when there is none.
  final VoidCallback? onLongPress;

  /// Resolved button background color.
  final Color backgroundColor;

  /// Resolved foreground color.
  final Color foregroundColor;

  /// Resolved button theme.
  final DraggablePanelButtonThemeData buttonTheme;
}

/// Builds a fully custom action button from a [DraggablePanelButtonRender].
typedef DraggablePanelButtonFrameBuilder = Widget Function(
  BuildContext context,
  DraggablePanelButtonRender render,
);

/// Payload for presenting a tooltip on long-press.
@immutable
class DraggablePanelTooltipData {
  const DraggablePanelTooltipData({
    required this.message,
    required this.backgroundColor,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.tooltipTheme,
    this.icon,
  });

  /// The tooltip message.
  final String message;

  /// Optional leading icon.
  final IconData? icon;

  /// Background color (the panel color).
  final Color backgroundColor;

  /// Icon foreground color.
  final Color iconColor;

  /// Icon container background color.
  final Color iconBackgroundColor;

  /// Resolved tooltip theme.
  final DraggablePanelTooltipThemeData tooltipTheme;
}

/// Presents a tooltip. Replaces the built-in SnackBar mechanism when provided.
typedef DraggablePanelTooltipPresenter = void Function(
  BuildContext context,
  DraggablePanelTooltipData data,
);

/// Everything needed to render a fully custom panel surface (the visible sheet).
///
/// The slide/dock positioning, fade, and tap-to-close are still provided by the
/// panel; this only replaces the decorated container around [content].
@immutable
class DraggablePanelSurface {
  const DraggablePanelSurface({
    required this.content,
    required this.width,
    required this.maxHeight,
    required this.color,
    required this.theme,
    required this.isOpen,
  });

  /// The panel contents (the default layout or a custom content builder).
  ///
  /// The content sizes itself to fit; constrain it to [maxHeight] and make it
  /// scrollable if it can overflow. Apply your own padding around it — the
  /// default [theme.panelContentPadding] is only applied by the built-in
  /// surface.
  final Widget content;

  /// Resolved panel width, including any border. Keep your surface at this
  /// width so the docking position stays aligned with the button.
  final double width;

  /// Maximum height available to the panel on its chosen side of the button.
  /// Cap your surface to this and scroll beyond it so it never overflows.
  final double maxHeight;

  /// Resolved panel background color.
  final Color color;

  /// The full panel theme.
  final DraggablePanelTheme theme;

  /// Whether the panel is open (always `true` while the surface is shown).
  final bool isOpen;
}

/// Builds a fully custom panel surface from a [DraggablePanelSurface].
typedef DraggablePanelSurfaceBuilder = Widget Function(
  BuildContext context,
  DraggablePanelSurface surface,
);

/// Building blocks for laying out the panel contents yourself.
///
/// Use [buildItem]/[buildButton] to get fully wired widgets (content, shell,
/// interactions, badges) and arrange them in any layout you want.
@immutable
class DraggablePanelContent {
  const DraggablePanelContent({
    required this.items,
    required this.buttons,
    required this.buildItem,
    required this.buildButton,
  });

  /// The item models.
  final List<DraggablePanelItem> items;

  /// The action button models.
  final List<DraggablePanelButtonItem> buttons;

  /// Builds a fully wired item widget for the given item.
  final Widget Function(BuildContext context, DraggablePanelItem item)
      buildItem;

  /// Builds a fully wired action button widget for the given button.
  final Widget Function(BuildContext context, DraggablePanelButtonItem button)
      buildButton;
}

/// Builds the panel's content layout, replacing the default `Wrap` + `Column`.
typedef DraggablePanelContentBuilder = Widget Function(
  BuildContext context,
  DraggablePanelContent content,
);
