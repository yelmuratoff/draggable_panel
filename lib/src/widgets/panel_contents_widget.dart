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

  @override
  Widget build(BuildContext context) {
    final hasButtons = buttons.isNotEmpty;
    final itemTheme = theme.effectiveItemTheme;
    final buttonTheme = theme.effectiveButtonTheme;

    return Column(
      mainAxisAlignment: hasButtons
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          runSpacing: theme.itemSpacing,
          spacing: theme.itemSpacing,
          children: [
            for (final item in items)
              PanelItemBadge(
                item: item,
                foregroundColor: itemForegroundColor,
                itemColor: itemColor,
                itemTheme: itemTheme,
                onPressed: () => onItemTap(item),
                onLongPress: item.description?.isNotEmpty ?? false
                    ? () => onItemLongPress(item)
                    : null,
              ),
          ],
        ),
        if (hasButtons) SizedBox(height: theme.sectionSpacing),
        if (hasButtons)
          Flexible(
            child: Wrap(
              runSpacing: theme.buttonSpacing,
              children: [
                for (final button in buttons)
                  PanelButtonWidget(
                    itemColor: itemColor,
                    foregroundColor: itemForegroundColor,
                    backgroundColor: theme.panelButtonColor,
                    buttonTheme: buttonTheme,
                    icon: button.icon,
                    label: button.label,
                    onTap: () => onButtonTap(button),
                    onLongPress: button.description?.isNotEmpty ?? false
                        ? () => onButtonLongPress(button)
                        : null,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Internal widget for a single panel item badge.
@immutable
final class PanelItemBadge extends StatelessWidget {
  const PanelItemBadge({
    required this.item,
    required this.itemColor,
    required this.foregroundColor,
    required this.itemTheme,
    required this.onPressed,
    this.onLongPress,
    super.key,
  });

  final DraggablePanelItem item;
  final Color itemColor;
  final Color foregroundColor;
  final DraggablePanelItemThemeData itemTheme;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) => Badge(
        isLabelVisible: item.enableBadge,
        padding: EdgeInsets.zero,
        smallSize: itemTheme.badgeSize,
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
                  child: Icon(
                    item.icon,
                    color: foregroundColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
