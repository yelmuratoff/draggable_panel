import 'package:flutter/material.dart';

/// Theme data for tooltip snackbars shown on long-press.
@immutable
class DraggablePanelTooltipThemeData {
  const DraggablePanelTooltipThemeData({
    this.backgroundOpacity = 0.95,
    this.borderRadius = 12.0,
    this.contentBorderRadius = 16.0,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.textColor,
    this.backgroundColor,
    this.iconSize = 16.0,
    this.fontSize = 14.0,
    this.iconPadding = const EdgeInsets.all(4),
    this.iconBackgroundColor,
    this.iconBorderRadius = 8.0,
    this.iconSpacing = 12.0,
    this.maxLines = 2,
    this.textStyle,
  });

  /// Opacity applied to the background color.
  final double backgroundOpacity;

  /// Border radius of the snackbar shape.
  final double borderRadius;

  /// Border radius of the inner content container.
  final double contentBorderRadius;

  /// Outer margin of the snackbar.
  final EdgeInsets margin;

  /// Inner padding of the content container.
  final EdgeInsets padding;

  /// Text color. Defaults to [Colors.white].
  final Color? textColor;

  /// Background color. Defaults to the theme's color scheme.
  final Color? backgroundColor;

  /// Size of the icon in the tooltip.
  final double iconSize;

  /// Font size of the message text.
  final double fontSize;

  /// Padding around the icon container.
  final EdgeInsets iconPadding;

  /// Background color of the icon container.
  /// Defaults to white with 20% opacity.
  final Color? iconBackgroundColor;

  /// Border radius of the icon container.
  final double iconBorderRadius;

  /// Spacing between the icon container and the message text.
  final double iconSpacing;

  /// Maximum number of lines for the message text.
  final int maxLines;

  /// Text style of the message. When set it overrides [fontSize]; the resolved
  /// text color is always applied on top.
  final TextStyle? textStyle;

  DraggablePanelTooltipThemeData copyWith({
    double? backgroundOpacity,
    double? borderRadius,
    double? contentBorderRadius,
    EdgeInsets? margin,
    EdgeInsets? padding,
    Color? textColor,
    Color? backgroundColor,
    double? iconSize,
    double? fontSize,
    EdgeInsets? iconPadding,
    Color? iconBackgroundColor,
    double? iconBorderRadius,
    double? iconSpacing,
    int? maxLines,
    TextStyle? textStyle,
  }) =>
      DraggablePanelTooltipThemeData(
        backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
        borderRadius: borderRadius ?? this.borderRadius,
        contentBorderRadius: contentBorderRadius ?? this.contentBorderRadius,
        margin: margin ?? this.margin,
        padding: padding ?? this.padding,
        textColor: textColor ?? this.textColor,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        iconSize: iconSize ?? this.iconSize,
        fontSize: fontSize ?? this.fontSize,
        iconPadding: iconPadding ?? this.iconPadding,
        iconBackgroundColor: iconBackgroundColor ?? this.iconBackgroundColor,
        iconBorderRadius: iconBorderRadius ?? this.iconBorderRadius,
        iconSpacing: iconSpacing ?? this.iconSpacing,
        maxLines: maxLines ?? this.maxLines,
        textStyle: textStyle ?? this.textStyle,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DraggablePanelTooltipThemeData &&
        other.backgroundOpacity == backgroundOpacity &&
        other.borderRadius == borderRadius &&
        other.contentBorderRadius == contentBorderRadius &&
        other.margin == margin &&
        other.padding == padding &&
        other.textColor == textColor &&
        other.backgroundColor == backgroundColor &&
        other.iconSize == iconSize &&
        other.fontSize == fontSize &&
        other.iconPadding == iconPadding &&
        other.iconBackgroundColor == iconBackgroundColor &&
        other.iconBorderRadius == iconBorderRadius &&
        other.iconSpacing == iconSpacing &&
        other.maxLines == maxLines &&
        other.textStyle == textStyle;
  }

  @override
  int get hashCode =>
      backgroundOpacity.hashCode ^
      borderRadius.hashCode ^
      contentBorderRadius.hashCode ^
      margin.hashCode ^
      padding.hashCode ^
      textColor.hashCode ^
      backgroundColor.hashCode ^
      iconSize.hashCode ^
      fontSize.hashCode ^
      iconPadding.hashCode ^
      iconBackgroundColor.hashCode ^
      iconBorderRadius.hashCode ^
      iconSpacing.hashCode ^
      maxLines.hashCode ^
      textStyle.hashCode;
}
