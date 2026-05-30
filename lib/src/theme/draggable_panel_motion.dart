import 'package:flutter/widgets.dart';

/// Defines the motion (durations and curves) of a [DraggablePanel].
///
/// Every animated transition in the panel reads its timing from here, so the
/// default mechanics can be fully retuned without touching the widgets:
/// - the draggable button sliding off/onto the screen and docking,
/// - the panel sliding in and resizing,
/// - the panel content fading in and out.
@immutable
class DraggablePanelMotion {
  const DraggablePanelMotion({
    this.buttonMoveDuration = const Duration(milliseconds: 300),
    this.buttonMoveCurve = Curves.fastLinearToSlowEaseIn,
    this.panelMoveDuration = const Duration(milliseconds: 300),
    this.panelMoveCurve = Curves.linearToEaseOut,
    this.panelSwitchDuration = const Duration(milliseconds: 300),
    this.panelSwitchInCurve = Curves.linear,
    this.panelSwitchOutCurve = Curves.linear,
  });

  /// Duration of the draggable button sliding (docking, hiding, revealing).
  ///
  /// While the button is being dragged the motion is instant regardless of this
  /// value, so the button tracks the finger without lag.
  final Duration buttonMoveDuration;

  /// Curve applied to the button slide and to its decoration changes.
  final Curve buttonMoveCurve;

  /// Duration of the panel sliding into place and resizing.
  final Duration panelMoveDuration;

  /// Curve applied to the panel slide and resize.
  final Curve panelMoveCurve;

  /// Duration of the panel content fade handled by the internal
  /// [AnimatedSwitcher] when the panel opens or closes.
  final Duration panelSwitchDuration;

  /// Curve for the incoming panel content fade.
  final Curve panelSwitchInCurve;

  /// Curve for the outgoing panel content fade.
  final Curve panelSwitchOutCurve;

  DraggablePanelMotion copyWith({
    Duration? buttonMoveDuration,
    Curve? buttonMoveCurve,
    Duration? panelMoveDuration,
    Curve? panelMoveCurve,
    Duration? panelSwitchDuration,
    Curve? panelSwitchInCurve,
    Curve? panelSwitchOutCurve,
  }) =>
      DraggablePanelMotion(
        buttonMoveDuration: buttonMoveDuration ?? this.buttonMoveDuration,
        buttonMoveCurve: buttonMoveCurve ?? this.buttonMoveCurve,
        panelMoveDuration: panelMoveDuration ?? this.panelMoveDuration,
        panelMoveCurve: panelMoveCurve ?? this.panelMoveCurve,
        panelSwitchDuration: panelSwitchDuration ?? this.panelSwitchDuration,
        panelSwitchInCurve: panelSwitchInCurve ?? this.panelSwitchInCurve,
        panelSwitchOutCurve: panelSwitchOutCurve ?? this.panelSwitchOutCurve,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DraggablePanelMotion &&
        other.buttonMoveDuration == buttonMoveDuration &&
        other.buttonMoveCurve == buttonMoveCurve &&
        other.panelMoveDuration == panelMoveDuration &&
        other.panelMoveCurve == panelMoveCurve &&
        other.panelSwitchDuration == panelSwitchDuration &&
        other.panelSwitchInCurve == panelSwitchInCurve &&
        other.panelSwitchOutCurve == panelSwitchOutCurve;
  }

  @override
  int get hashCode => Object.hash(
        buttonMoveDuration,
        buttonMoveCurve,
        panelMoveDuration,
        panelMoveCurve,
        panelSwitchDuration,
        panelSwitchInCurve,
        panelSwitchOutCurve,
      );
}
