import 'package:flutter/material.dart';

/// Theme data for the draggable handle (the visual indicator on the button).
@immutable
class DraggablePanelHandleThemeData {
  const DraggablePanelHandleThemeData({
    this.animationDuration = const Duration(milliseconds: 200),
    this.curveLineSize = const Size(20, 65),
    this.curveStrokeWidth = 5.0,
  });

  /// Duration of the drag indicator / handle switch animation.
  final Duration animationDuration;

  /// Size of the curved line handle.
  final Size curveLineSize;

  /// Stroke width of the curved line.
  final double curveStrokeWidth;

  DraggablePanelHandleThemeData copyWith({
    Duration? animationDuration,
    Size? curveLineSize,
    double? curveStrokeWidth,
  }) =>
      DraggablePanelHandleThemeData(
        animationDuration: animationDuration ?? this.animationDuration,
        curveLineSize: curveLineSize ?? this.curveLineSize,
        curveStrokeWidth: curveStrokeWidth ?? this.curveStrokeWidth,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DraggablePanelHandleThemeData &&
        other.animationDuration == animationDuration &&
        other.curveLineSize == curveLineSize &&
        other.curveStrokeWidth == curveStrokeWidth;
  }

  @override
  int get hashCode =>
      animationDuration.hashCode ^
      curveLineSize.hashCode ^
      curveStrokeWidth.hashCode;
}
