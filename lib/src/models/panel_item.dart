import 'package:flutter/material.dart';

/// Represents an item in the draggable panel.
///
/// This model defines the properties and behavior of a panel item,
/// including its icon, badge state, and interaction handlers.
///
/// - Parameters:
///   - icon: The icon to display for this item
///   - enableBadge: Whether to show a badge indicator on this item
///   - onTap: Callback invoked when the item is tapped
///   - description: Optional description shown when long-pressing the item
/// - Usage example:
///   ```dart
///   DraggablePanelItem(
///     icon: Icons.settings,
///     enableBadge: true,
///     onTap: (context) => Navigator.push(...),
///     description: 'Open settings',
///   )
///   ```
@immutable
final class DraggablePanelItem {
  /// Creates a draggable panel item.
  const DraggablePanelItem({
    required this.icon,
    required this.enableBadge,
    required this.onTap,
    this.description,
  });

  /// The icon to display for this item.
  final IconData icon;

  /// Whether to show a badge indicator on this item.
  final bool enableBadge;

  /// Optional description shown when long-pressing the item.
  final String? description;

  /// Callback invoked when the item is tapped.
  final void Function(BuildContext context) onTap;

  /// Creates a copy of this item with the given fields replaced with new values.
  DraggablePanelItem copyWith({
    IconData? icon,
    bool? enableBadge,
    String? description,
    void Function(BuildContext context)? onTap,
  }) =>
      DraggablePanelItem(
        icon: icon ?? this.icon,
        enableBadge: enableBadge ?? this.enableBadge,
        description: description ?? this.description,
        onTap: onTap ?? this.onTap,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DraggablePanelItem &&
        other.icon == icon &&
        other.enableBadge == enableBadge &&
        other.description == description &&
        other.onTap == onTap;
  }

  @override
  int get hashCode => Object.hash(icon, enableBadge, description, onTap);
}
