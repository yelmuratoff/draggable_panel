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
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final resolvedBackgroundColor = backgroundColor ??
        (isDark
            ? colorScheme.surfaceContainer.withValues(alpha: 0.95)
            : colorScheme.inverseSurface.withValues(alpha: 0.95));

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: _TooltipContent(
            message: message,
            icon: icon,
            backgroundColor: resolvedBackgroundColor,
            textColor: textColor ?? Colors.white,
          ),
          backgroundColor: Colors.transparent,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    this.icon,
  });

  final String message;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                _IconContainer(icon: icon!, textColor: textColor),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: _MessageText(message: message, textColor: textColor),
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
  });

  final IconData icon;
  final Color textColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Color.fromRGBO(255, 255, 255, 0.2),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: Icon(icon, color: textColor, size: 16),
      );
}

/// Private widget for the message text.
final class _MessageText extends StatelessWidget {
  const _MessageText({
    required this.message,
    required this.textColor,
  });

  final String message;
  final Color textColor;

  @override
  Widget build(BuildContext context) => Text(
        message,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
}
