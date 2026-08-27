import 'package:draggable_panel/src/model/panel_corner.dart';
import 'package:flutter/foundation.dart';

/// The strings a panel announces to assistive technology.
///
/// Kept on the widget rather than in the theme because these are user-facing
/// copy: they need localizing, and a `ThemeExtension` cannot lerp a string.
@immutable
final class PanelSemantics {
  const PanelSemantics({
    this.label = 'Floating panel',
    this.expandHint = 'Expand the panel',
    this.collapseHint = 'Collapse the panel',
    this.stashAction = 'Park at the edge',
    this.unstashAction = 'Bring back on screen',
    this.moveActionPrefix = 'Move to',
    this.topStartName = 'top start',
    this.topEndName = 'top end',
    this.bottomStartName = 'bottom start',
    this.bottomEndName = 'bottom end',
  });

  /// Names the panel itself.
  final String label;

  final String expandHint;
  final String collapseHint;

  /// Label for the custom action that parks the panel off-screen.
  final String stashAction;

  /// Label for the custom action that brings a stashed panel back.
  final String unstashAction;

  /// Prefixes each move-to-corner custom action, as `"$moveActionPrefix $corner"`.
  final String moveActionPrefix;

  final String topStartName;
  final String topEndName;
  final String bottomStartName;
  final String bottomEndName;

  /// The spoken name of [corner].
  String nameOf(PanelCorner corner) => switch (corner) {
    PanelCorner.topStart => topStartName,
    PanelCorner.topEnd => topEndName,
    PanelCorner.bottomStart => bottomStartName,
    PanelCorner.bottomEnd => bottomEndName,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PanelSemantics &&
          other.label == label &&
          other.expandHint == expandHint &&
          other.collapseHint == collapseHint &&
          other.stashAction == stashAction &&
          other.unstashAction == unstashAction &&
          other.moveActionPrefix == moveActionPrefix &&
          other.topStartName == topStartName &&
          other.topEndName == topEndName &&
          other.bottomStartName == bottomStartName &&
          other.bottomEndName == bottomEndName;

  @override
  int get hashCode => Object.hash(
    label,
    expandHint,
    collapseHint,
    stashAction,
    unstashAction,
    moveActionPrefix,
    topStartName,
    topEndName,
    bottomStartName,
    bottomEndName,
  );
}
