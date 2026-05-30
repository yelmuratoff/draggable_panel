import 'package:flutter/material.dart';

/// Theme data for panel action buttons.
@immutable
class DraggablePanelButtonThemeData {
  const DraggablePanelButtonThemeData({
    this.height = 45.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.borderRadius = 16.0,
    this.iconSize = 18.0,
    this.iconSpacing = 12.0,
    this.labelStyle,
  });

  /// Height of each button.
  final double height;

  /// Padding inside each button.
  final EdgeInsets padding;

  /// Border radius of each button.
  final double borderRadius;

  /// Size of the button icon.
  final double iconSize;

  /// Spacing between icon and label text.
  final double iconSpacing;

  /// Text style of the button label. The foreground color is applied on top,
  /// so leave [TextStyle.color] unset unless you want to override it.
  final TextStyle? labelStyle;

  DraggablePanelButtonThemeData copyWith({
    double? height,
    EdgeInsets? padding,
    double? borderRadius,
    double? iconSize,
    double? iconSpacing,
    TextStyle? labelStyle,
  }) =>
      DraggablePanelButtonThemeData(
        height: height ?? this.height,
        padding: padding ?? this.padding,
        borderRadius: borderRadius ?? this.borderRadius,
        iconSize: iconSize ?? this.iconSize,
        iconSpacing: iconSpacing ?? this.iconSpacing,
        labelStyle: labelStyle ?? this.labelStyle,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DraggablePanelButtonThemeData &&
        other.height == height &&
        other.padding == padding &&
        other.borderRadius == borderRadius &&
        other.iconSize == iconSize &&
        other.iconSpacing == iconSpacing &&
        other.labelStyle == labelStyle;
  }

  @override
  int get hashCode =>
      height.hashCode ^
      padding.hashCode ^
      borderRadius.hashCode ^
      iconSize.hashCode ^
      iconSpacing.hashCode ^
      labelStyle.hashCode;
}
