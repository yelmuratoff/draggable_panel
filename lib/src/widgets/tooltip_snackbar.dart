import 'package:flutter/material.dart';

/// Custom SnackBar widget for showing tooltips in DraggablePanel.
class TooltipSnackBar {
  const TooltipSnackBar._();

  // Constants for consistent styling
  static const _kDefaultDuration = Duration(seconds: 4);
  static const _kContentPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  static const _kMargin = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const _kContentBorderRadius = BorderRadius.all(Radius.circular(16));
  static const _kSnackBarBorderRadius = BorderRadius.all(Radius.circular(12));
  static const _kIconBorderRadius = BorderRadius.all(Radius.circular(8));
  static const _kIconPadding = EdgeInsets.all(4);
  static const _kIconSpacing = SizedBox(width: 12);
  static const _kIconSize = 16.0;
  static const _kFontSize = 14.0;
  static const _kFontWeight = FontWeight.w500;
  static const _kLineHeight = 1.2;
  static const _kMaxLines = 2;
  static const _kAlphaBackground = 0.95;
  static const _kAlphaIconBackground = 0.2;

  /// Shows a tooltip snackbar with the given [message] and optional customization.
  ///
  /// The snackbar automatically adapts to the current theme and provides
  /// a clean, modern appearance with optional icon support.
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = _kDefaultDuration,
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    final Color resolvedBackgroundColor =
        backgroundColor ?? _getDefaultBackgroundColor(colorScheme, isDark);
    final Color resolvedTextColor = textColor ?? Colors.white;

    final SnackBar snackBar = SnackBar(
      content: _TooltipContent(
        message: message,
        icon: icon,
        backgroundColor: resolvedBackgroundColor,
        textColor: resolvedTextColor,
      ),
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: _kSnackBarBorderRadius),
      margin: _kMargin,
      padding: _kContentPadding,
      duration: duration,
      elevation: 0,
      dismissDirection: DismissDirection.horizontal,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  /// Gets the default background color based on theme brightness.
  static Color _getDefaultBackgroundColor(
      ColorScheme colorScheme, bool isDark) {
    return isDark
        ? colorScheme.surfaceContainer.withValues(alpha: _kAlphaBackground)
        : colorScheme.inverseSurface.withValues(alpha: _kAlphaBackground);
  }
}

/// Private widget for the snackbar content.
class _TooltipContent extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: TooltipSnackBar._kContentBorderRadius,
      ),
      child: Padding(
        padding: TooltipSnackBar._kContentPadding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              _IconContainer(
                icon: icon!,
                textColor: textColor,
              ),
              TooltipSnackBar._kIconSpacing,
            ],
            Flexible(
              child: _MessageText(
                message: message,
                textColor: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Private widget for the icon container.
class _IconContainer extends StatelessWidget {
  const _IconContainer({
    required this.icon,
    required this.textColor,
  });

  final IconData icon;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: TooltipSnackBar._kIconPadding,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(
            255, 255, 255, TooltipSnackBar._kAlphaIconBackground),
        borderRadius: TooltipSnackBar._kIconBorderRadius,
      ),
      child: Icon(
        icon,
        color: textColor,
        size: TooltipSnackBar._kIconSize,
      ),
    );
  }
}

/// Private widget for the message text.
class _MessageText extends StatelessWidget {
  const _MessageText({
    required this.message,
    required this.textColor,
  });

  final String message;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(
        color: textColor,
        fontSize: TooltipSnackBar._kFontSize,
        fontWeight: TooltipSnackBar._kFontWeight,
        height: TooltipSnackBar._kLineHeight,
      ),
      maxLines: TooltipSnackBar._kMaxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
