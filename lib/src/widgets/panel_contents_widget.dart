import 'package:draggable_panel/src/models/panel_button.dart';
import 'package:draggable_panel/src/models/panel_item.dart';
import 'package:draggable_panel/src/widgets/panel_button_widget.dart';
import 'package:flutter/material.dart';

/// Internal widget for panel contents including items and buttons.
@immutable
final class PanelContentsWidget extends StatelessWidget {
  const PanelContentsWidget({
    required this.items,
    required this.buttons,
    required this.itemColor,
    required this.onItemTap,
    required this.onItemLongPress,
    required this.onButtonTap,
    required this.onButtonLongPress,
    super.key,
  });

  final List<DraggablePanelItem> items;
  final List<DraggablePanelButtonItem> buttons;
  final Color itemColor;
  final ValueChanged<DraggablePanelItem> onItemTap;
  final ValueChanged<DraggablePanelItem> onItemLongPress;
  final ValueChanged<DraggablePanelButtonItem> onButtonTap;
  final ValueChanged<DraggablePanelButtonItem> onButtonLongPress;

  @override
  Widget build(BuildContext context) {
    final hasButtons = buttons.isNotEmpty;

    return Column(
      mainAxisAlignment: hasButtons
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          runSpacing: 8,
          spacing: 8,
          children: [
            for (final item in items)
              PanelItemBadge(
                item: item,
                itemColor: itemColor,
                onPressed: () => onItemTap(item),
                onLongPress: item.description?.isNotEmpty ?? false
                    ? () => onItemLongPress(item)
                    : null,
              ),
          ],
        ),
        if (hasButtons) const SizedBox(height: 8),
        if (hasButtons)
          Flexible(
            child: Wrap(
              runSpacing: 6,
              children: [
                for (final button in buttons)
                  PanelButtonWidget(
                    itemColor: itemColor,
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
    required this.onPressed,
    this.onLongPress,
    super.key,
  });

  final DraggablePanelItem item;
  final Color itemColor;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) => Badge(
        isLabelVisible: item.enableBadge,
        padding: EdgeInsets.zero,
        smallSize: 12,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              onLongPress: onLongPress,
              child: Ink(
                color: itemColor,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    item.icon,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
