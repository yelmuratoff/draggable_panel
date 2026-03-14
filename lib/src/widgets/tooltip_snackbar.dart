import 'package:draggable_panel/src/theme/draggable_panel_tooltip_theme_data.dart';
import 'package:flutter/material.dart';

/// Custom SnackBar widget for showing tooltips in DraggablePanel.
///
/// This is a utility class that provides a static method to show
/// clean, modern tooltips with automatic theme adaptation.
///
/// - Usage example:
///   ```dart
///   TooltipSnackBar.show(
///     context,
///     message: 'Settings updated',
///     icon: Icons.check_circle,
///     duration: Duration(seconds: 2),
///   );
///   ```
final class TooltipSnackBar {
  const TooltipSnackBar._();

  /// Shows a tooltip snackbar with the given [message] and optional customization.
  ///
  /// The snackbar automatically adapts to the current theme and provides
  /// a clean, modern appearance with optional icon support.
  ///
  /// - [context]: The build context.
  /// - [message]: The message to display.
  /// - [duration]: How long to show the snackbar (default: 3 seconds).
  /// - [backgroundColor]: Optional custom background color.
  /// - [textColor]: Optional custom text color.
  /// - [icon]: Optional icon to display.
  /// - [tooltipTheme]: Optional theme data for fine-grained control.
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
    DraggablePanelTooltipThemeData? tooltipTheme,
  }) {
    final tt = tooltipTheme ?? const DraggablePanelTooltipThemeData();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final resolvedBgColor = backgroundColor ??
        tt.backgroundColor ??
        (isDark
            ? colorScheme.surfaceContainer
                .withValues(alpha: tt.backgroundOpacity)
            : colorScheme.inverseSurface
                .withValues(alpha: tt.backgroundOpacity));

    final resolvedTextColor = textColor ?? tt.textColor ?? Colors.white;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: _TooltipContent(
            message: message,
            icon: icon,
            backgroundColor: resolvedBgColor,
            textColor: resolvedTextColor,
            tooltipTheme: tt,
          ),
          backgroundColor: Colors.transparent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(tt.borderRadius)),
          ),
          margin: tt.margin,
          padding: tt.padding,
          duration: duration,
          elevation: 0,
          dismissDirection: DismissDirection.horizontal,
        ),
      );
  }
}

/// Private widget for the snackbar content.
final class _TooltipContent extends StatelessWidget {
  const _TooltipContent({
    required this.message,
    required this.backgroundColor,
    required this.textColor,
    required this.tooltipTheme,
    this.icon,
  });

  final String message;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final DraggablePanelTooltipThemeData tooltipTheme;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.all(
            Radius.circular(tooltipTheme.contentBorderRadius),
          ),
        ),
        child: Padding(
          padding: tooltipTheme.padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                _IconContainer(
                  icon: icon!,
                  textColor: textColor,
                  tooltipTheme: tooltipTheme,
                ),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: _MessageText(
                  message: message,
                  textColor: textColor,
                  fontSize: tooltipTheme.fontSize,
                ),
              ),
            ],
          ),
        ),
      );
}

/// Private widget for the icon container.
final class _IconContainer extends StatelessWidget {
  const _IconContainer({
    required this.icon,
    required this.textColor,
    required this.tooltipTheme,
  });

  final IconData icon;
  final Color textColor;
  final DraggablePanelTooltipThemeData tooltipTheme;

  @override
  Widget build(BuildContext context) => Container(
        padding: tooltipTheme.iconPadding,
        decoration: BoxDecoration(
          color: tooltipTheme.iconBackgroundColor ??
              const Color.fromRGBO(255, 255, 255, 0.2),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: Icon(icon, color: textColor, size: tooltipTheme.iconSize),
      );
}

/// Private widget for the message text.
final class _MessageText extends StatelessWidget {
  const _MessageText({
    required this.message,
    required this.textColor,
    required this.fontSize,
  });

  final String message;
  final Color textColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Text(
        message,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
}
