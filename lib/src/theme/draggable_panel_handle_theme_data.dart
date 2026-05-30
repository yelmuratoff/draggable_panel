import 'package:flutter/material.dart';

/// Theme data for the draggable handle (the visual indicator on the button).
@immutable
class DraggablePanelHandleThemeData {
  const DraggablePanelHandleThemeData({
    this.animationDuration = const Duration(milliseconds: 200),
    this.curveLineSize = const Size(20, 65),
    this.curveStrokeWidth = 5.0,
    this.dragIndicatorIcon = Icons.drag_indicator_rounded,
    this.dragIndicatorSize,
  });

  /// Duration of the drag indicator / handle switch animation.
  final Duration animationDuration;

  /// Size of the curved line handle.
  final Size curveLineSize;

  /// Stroke width of the curved line.
  final double curveStrokeWidth;

  /// Icon shown on the button while it is being dragged.
  final IconData dragIndicatorIcon;

  /// Size of [dragIndicatorIcon]. Uses the icon's default when null.
  final double? dragIndicatorSize;

  DraggablePanelHandleThemeData copyWith({
    Duration? animationDuration,
    Size? curveLineSize,
    double? curveStrokeWidth,
    IconData? dragIndicatorIcon,
    double? dragIndicatorSize,
  }) =>
      DraggablePanelHandleThemeData(
        animationDuration: animationDuration ?? this.animationDuration,
        curveLineSize: curveLineSize ?? this.curveLineSize,
        curveStrokeWidth: curveStrokeWidth ?? this.curveStrokeWidth,
        dragIndicatorIcon: dragIndicatorIcon ?? this.dragIndicatorIcon,
        dragIndicatorSize: dragIndicatorSize ?? this.dragIndicatorSize,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DraggablePanelHandleThemeData &&
        other.animationDuration == animationDuration &&
        other.curveLineSize == curveLineSize &&
        other.curveStrokeWidth == curveStrokeWidth &&
        other.dragIndicatorIcon == dragIndicatorIcon &&
        other.dragIndicatorSize == dragIndicatorSize;
  }

  @override
  int get hashCode =>
      animationDuration.hashCode ^
      curveLineSize.hashCode ^
      curveStrokeWidth.hashCode ^
      dragIndicatorIcon.hashCode ^
      dragIndicatorSize.hashCode;
}
