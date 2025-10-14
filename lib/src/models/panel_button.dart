import 'package:flutter/material.dart';

/// Represents a button item in the draggable panel.
///
/// This model defines the properties and behavior of a button that can be
/// displayed in the panel, including its appearance and interaction handlers.
@immutable
final class DraggablePanelButtonItem {
  /// Creates a draggable panel button item.
  ///
  /// The [icon], [label], and [onTap] parameters are required.
  /// The [description] is optional and used for tooltips.
  const DraggablePanelButtonItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.description,
  });

  /// The icon to display on the button.
  final IconData icon;

  /// The text label for the button.
  final String label;

  /// Optional description shown when long-pressing the button.
  final String? description;

  /// Callback invoked when the button is tapped.
  final void Function(BuildContext context) onTap;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DraggablePanelButtonItem &&
        other.icon == icon &&
        other.label == label &&
        other.description == description &&
        other.onTap == onTap;
  }

  @override
  int get hashCode => Object.hash(icon, label, description, onTap);
}
