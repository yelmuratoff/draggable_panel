import 'package:draggable_panel/src/theme/draggable_panel_button_theme_data.dart';
import 'package:flutter/material.dart';

/// Internal shell for a panel action button.
///
/// Provides the [FilledButton] frame and gesture handling; the visible content
/// is supplied via [child] (default content or a custom builder result).
@immutable
final class PanelButtonWidget extends StatelessWidget {
  const PanelButtonWidget({
    required this.itemColor,
    required this.buttonTheme,
    required this.onTap,
    required this.child,
    this.onLongPress,
    this.backgroundColor,
    super.key,
  });

  final Color itemColor;
  final DraggablePanelButtonThemeData buttonTheme;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: buttonTheme.height,
        width: double.infinity,
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
          child: child,
        ),
      );
}

/// Default content for a panel action button: an icon followed by a label.
@immutable
final class PanelButtonContent extends StatelessWidget {
  const PanelButtonContent({
    required this.icon,
    required this.label,
    required this.foregroundColor,
    required this.buttonTheme,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color foregroundColor;
  final DraggablePanelButtonThemeData buttonTheme;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foregroundColor, size: buttonTheme.iconSize),
          SizedBox(width: buttonTheme.iconSpacing),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (buttonTheme.labelStyle ?? const TextStyle())
                  .copyWith(color: foregroundColor),
            ),
          ),
        ],
      );
}
