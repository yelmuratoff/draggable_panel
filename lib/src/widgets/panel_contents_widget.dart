import 'package:draggable_panel/draggable_panel.dart';
import 'package:draggable_panel/src/widgets/panel_button_widget.dart';
import 'package:flutter/material.dart';

/// Internal widget for panel contents including items and buttons.
@immutable
final class PanelContentsWidget extends StatelessWidget {
  const PanelContentsWidget({
    required this.items,
    required this.buttons,
    required this.itemColor,
    required this.itemForegroundColor,
    required this.onItemTap,
    required this.onItemLongPress,
    required this.onButtonTap,
    required this.onButtonLongPress,
    required this.theme,
    this.itemBuilder,
    this.buttonBuilder,
    this.itemFrameBuilder,
    this.buttonFrameBuilder,
    this.contentBuilder,
    super.key,
  });

  final List<DraggablePanelItem> items;
  final List<DraggablePanelButtonItem> buttons;
  final Color itemColor;
  final Color itemForegroundColor;
  final ValueChanged<DraggablePanelItem> onItemTap;
  final ValueChanged<DraggablePanelItem> onItemLongPress;
  final ValueChanged<DraggablePanelButtonItem> onButtonTap;
  final ValueChanged<DraggablePanelButtonItem> onButtonLongPress;
  final DraggablePanelTheme theme;
  final DraggablePanelItemBuilder? itemBuilder;
  final DraggablePanelButtonBuilder? buttonBuilder;
  final DraggablePanelItemFrameBuilder? itemFrameBuilder;
  final DraggablePanelButtonFrameBuilder? buttonFrameBuilder;
  final DraggablePanelContentBuilder? contentBuilder;

  @override
  Widget build(BuildContext context) {
    final hasButtons = buttons.isNotEmpty;
    final itemTheme = theme.effectiveItemTheme;
    final buttonTheme = theme.effectiveButtonTheme;

    final contentBuilder = this.contentBuilder;
    if (contentBuilder != null) {
      return contentBuilder(
        context,
        DraggablePanelContent(
          items: items,
          buttons: buttons,
          buildItem: (ctx, item) => _buildItem(ctx, item, itemTheme),
          buildButton: (ctx, button) => _buildButton(ctx, button, buttonTheme),
        ),
      );
    }

    // The surface gives this content an exact width (the panel hugs its items),
    // so a centered Wrap fills full rows edge-to-edge and balances the last row.
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (items.isNotEmpty)
            Wrap(
              alignment: WrapAlignment.center,
              runSpacing: theme.itemSpacing,
              spacing: theme.itemSpacing,
              children: [
                for (final item in items) _buildItem(context, item, itemTheme),
              ],
            ),
          if (hasButtons && items.isNotEmpty)
            SizedBox(height: theme.sectionSpacing),
          if (hasButtons)
            Wrap(
              runSpacing: theme.buttonSpacing,
              children: [
                for (final button in buttons)
                  _buildButton(context, button, buttonTheme),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    DraggablePanelItem item,
    DraggablePanelItemThemeData itemTheme,
  ) {
    final foreground = item.foregroundColor ?? itemForegroundColor;
    final background = item.color ?? itemColor;
    final content = itemBuilder?.call(context, item) ??
        Icon(item.icon, color: foreground, size: itemTheme.iconSize);
    void onTap() => onItemTap(item);
    final onLongPress = (item.description?.isNotEmpty ?? false)
        ? () => onItemLongPress(item)
        : null;

    if (itemFrameBuilder != null) {
      return itemFrameBuilder!(
        context,
        DraggablePanelItemRender(
          item: item,
          content: content,
          onTap: onTap,
          onLongPress: onLongPress,
          color: background,
          foregroundColor: foreground,
          itemTheme: itemTheme,
        ),
      );
    }

    return PanelItemBadge(
      item: item,
      itemColor: background,
      itemTheme: itemTheme,
      onPressed: onTap,
      onLongPress: onLongPress,
      child: content,
    );
  }

  Widget _buildButton(
    BuildContext context,
    DraggablePanelButtonItem button,
    DraggablePanelButtonThemeData buttonTheme,
  ) {
    final content = buttonBuilder?.call(context, button) ??
        PanelButtonContent(
          icon: button.icon,
          label: button.label,
          foregroundColor: itemForegroundColor,
          buttonTheme: buttonTheme,
        );
    void onTap() => onButtonTap(button);
    final onLongPress = (button.description?.isNotEmpty ?? false)
        ? () => onButtonLongPress(button)
        : null;

    if (buttonFrameBuilder != null) {
      return buttonFrameBuilder!(
        context,
        DraggablePanelButtonRender(
          button: button,
          content: content,
          onTap: onTap,
          onLongPress: onLongPress,
          backgroundColor: theme.panelButtonColor ?? itemColor,
          foregroundColor: itemForegroundColor,
          buttonTheme: buttonTheme,
        ),
      );
    }

    return PanelButtonWidget(
      itemColor: itemColor,
      backgroundColor: theme.panelButtonColor,
      buttonTheme: buttonTheme,
      onTap: onTap,
      onLongPress: onLongPress,
      child: content,
    );
  }
}

/// Internal shell for a single panel item badge.
@immutable
final class PanelItemBadge extends StatelessWidget {
  const PanelItemBadge({
    required this.item,
    required this.itemColor,
    required this.itemTheme,
    required this.onPressed,
    required this.child,
    this.onLongPress,
    super.key,
  });

  final DraggablePanelItem item;
  final Color itemColor;
  final DraggablePanelItemThemeData itemTheme;
  final Widget child;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) => Badge(
        isLabelVisible: item.enableBadge,
        backgroundColor: item.badgeColor,
        label: item.badgeLabel != null ? Text(item.badgeLabel!) : null,
        padding: item.badgeLabel != null ? null : EdgeInsets.zero,
        smallSize: item.badgeLabel != null ? null : itemTheme.badgeSize,
        child: ClipRRect(
          borderRadius:
              BorderRadius.all(Radius.circular(itemTheme.borderRadius)),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              onLongPress: onLongPress,
              child: Ink(
                color: itemColor,
                child: Padding(
                  padding: itemTheme.padding,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      );
}
