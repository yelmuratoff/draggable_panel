import 'package:flutter/material.dart';

/// Theme data for panel item badges (icon cells in the grid).
@immutable
class DraggablePanelItemThemeData {
  const DraggablePanelItemThemeData({
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.all(8),
    this.badgeSize = 12.0,
    this.iconSize = 24.0,
  });

  /// Border radius of each item cell.
  final double borderRadius;

  /// Padding inside each item cell around the icon.
  final EdgeInsets padding;

  /// Size of the notification badge dot.
  final double badgeSize;

  /// Size of the item icon. Also drives the panel height calculation.
  final double iconSize;

  DraggablePanelItemThemeData copyWith({
    double? borderRadius,
    EdgeInsets? padding,
    double? badgeSize,
    double? iconSize,
  }) =>
      DraggablePanelItemThemeData(
        borderRadius: borderRadius ?? this.borderRadius,
        padding: padding ?? this.padding,
        badgeSize: badgeSize ?? this.badgeSize,
        iconSize: iconSize ?? this.iconSize,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DraggablePanelItemThemeData &&
        other.borderRadius == borderRadius &&
        other.padding == padding &&
        other.badgeSize == badgeSize &&
        other.iconSize == iconSize;
  }

  @override
  int get hashCode =>
      borderRadius.hashCode ^
      padding.hashCode ^
      badgeSize.hashCode ^
      iconSize.hashCode;
}
