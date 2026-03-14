import 'package:draggable_panel/src/theme/draggable_panel_button_theme_data.dart';
import 'package:flutter/material.dart';

/// Internal widget for rendering a button in the draggable panel.
///
/// This widget displays a filled button with an icon and label,
/// supporting both tap and long-press gestures.
@immutable
final class PanelButtonWidget extends StatelessWidget {
  const PanelButtonWidget({
    required this.itemColor,
    required this.foregroundColor,
    required this.buttonTheme,
    required this.onTap,
    required this.icon,
    required this.label,
    this.onLongPress,
    this.backgroundColor,
    super.key,
  });

  final Color itemColor;
  final Color foregroundColor;
  final DraggablePanelButtonThemeData buttonTheme;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final IconData icon;
  final String label;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: buttonTheme.height,
        width: double.maxFinite,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: backgroundColor ?? itemColor,
            padding: buttonTheme.padding,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(buttonTheme.borderRadius)),
            ),
            elevation: 0,
          ),
          onPressed: onTap,
          onLongPress: onLongPress,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: foregroundColor,
                size: buttonTheme.iconSize,
              ),
              SizedBox(width: buttonTheme.iconSpacing),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foregroundColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
