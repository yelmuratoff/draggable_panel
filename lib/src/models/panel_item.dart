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
    this.color,
    this.foregroundColor,
    this.badgeColor,
    this.badgeLabel,
  });

  /// The icon to display for this item.
  final IconData icon;

  /// Whether to show a badge indicator on this item.
  final bool enableBadge;

  /// Optional description shown when long-pressing the item.
  final String? description;

  /// Background color of this cell. Falls back to the panel's item color.
  final Color? color;

  /// Foreground (icon) color of this cell. Falls back to the panel's foreground.
  final Color? foregroundColor;

  /// Badge color. Falls back to the Material default.
  final Color? badgeColor;

  /// Badge text. When set, the badge shows this label instead of a dot.
  final String? badgeLabel;

  /// Callback invoked when the item is tapped.
  final void Function(BuildContext context) onTap;

  /// Creates a copy of this item with the given fields replaced with new values.
  DraggablePanelItem copyWith({
    IconData? icon,
    bool? enableBadge,
    String? description,
    Color? color,
    Color? foregroundColor,
    Color? badgeColor,
    String? badgeLabel,
    void Function(BuildContext context)? onTap,
  }) =>
      DraggablePanelItem(
        icon: icon ?? this.icon,
        enableBadge: enableBadge ?? this.enableBadge,
        description: description ?? this.description,
        color: color ?? this.color,
        foregroundColor: foregroundColor ?? this.foregroundColor,
        badgeColor: badgeColor ?? this.badgeColor,
        badgeLabel: badgeLabel ?? this.badgeLabel,
        onTap: onTap ?? this.onTap,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DraggablePanelItem &&
        other.icon == icon &&
        other.enableBadge == enableBadge &&
        other.description == description &&
        other.color == color &&
        other.foregroundColor == foregroundColor &&
        other.badgeColor == badgeColor &&
        other.badgeLabel == badgeLabel &&
        other.onTap == onTap;
  }

  @override
  int get hashCode => Object.hash(
        icon,
        enableBadge,
        description,
        color,
        foregroundColor,
        badgeColor,
        badgeLabel,
        onTap,
      );
}
