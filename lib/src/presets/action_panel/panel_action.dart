import 'package:flutter/widgets.dart';

/// A small count or dot drawn over an action.
@immutable
final class PanelBadge {
  const PanelBadge({this.label, this.color, this.foregroundColor});

  /// A plain dot, for "something changed" without a count.
  const PanelBadge.dot({Color? color}) : this(color: color);

  /// Shown inside the badge. A dot is drawn when null.
  final String? label;

  final Color? color;

  /// Colour of [label]. Overrides whatever the theme resolves.
  final Color? foregroundColor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PanelBadge &&
          other.label == label &&
          other.color == color &&
          other.foregroundColor == foregroundColor;

  @override
  int get hashCode => Object.hash(label, color, foregroundColor);
}

/// One icon action in a `DraggableActionPanel` grid.
@immutable
final class PanelAction {
  const PanelAction({
    required this.icon,
    required this.onPressed,
    this.label,
    this.tooltip,
    this.badge,
    this.color,
    this.foregroundColor,
  });

  final IconData icon;

  /// Short caption shown under the icon.
  ///
  /// Without one the grid is a row of unlabelled glyphs, which is only
  /// readable to someone who already knows what they do.
  final String? label;

  /// Invoked when the action is chosen.
  final VoidCallback onPressed;

  /// Shown on long press, and used as the accessible label.
  final String? tooltip;

  final PanelBadge? badge;
  final Color? color;
  final Color? foregroundColor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PanelAction &&
          other.icon == icon &&
          other.onPressed == onPressed &&
          other.label == label &&
          other.tooltip == tooltip &&
          other.badge == badge &&
          other.color == color &&
          other.foregroundColor == foregroundColor;

  @override
  int get hashCode => Object.hash(
    icon,
    onPressed,
    label,
    tooltip,
    badge,
    color,
    foregroundColor,
  );
}

/// One full-width labelled button below the action grid.
@immutable
final class PanelActionButton {
  const PanelActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PanelActionButton &&
          other.icon == icon &&
          other.label == label &&
          other.onPressed == onPressed &&
          other.tooltip == tooltip;

  @override
  int get hashCode => Object.hash(icon, label, onPressed, tooltip);
}
