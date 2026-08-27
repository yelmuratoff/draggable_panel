import 'package:draggable_panel/src/model/panel_corner.dart';
import 'package:draggable_panel/src/model/panel_edge.dart';
import 'package:draggable_panel/src/model/panel_viewport.dart';
import 'package:flutter/widgets.dart';

/// Where a panel comes to rest, expressed as an *intent* rather than pixels.
///
/// Absolute coordinates are derived through [resolve] at layout time and never
/// stored, so a placement stays correct across rotation, a window resize, and
/// being restored onto a device with a different screen.
@immutable
sealed class PanelPlacement {
  const PanelPlacement();

  /// Rests in one of the four corners of [PanelViewport.bounds].
  const factory PanelPlacement.corner(PanelCorner corner) = CornerPlacement;

  /// Rests at an arbitrary normalized position within [PanelViewport.bounds].
  const factory PanelPlacement.free(AlignmentGeometry alignment) =
      FreePlacement;

  /// Sits mostly off-screen against [edge], leaving a grab tab visible.
  const factory PanelPlacement.stashed(
    PanelEdge edge, {
    double verticalAlignment,
  }) = StashedPlacement;

  /// The top-left a panel of [panelSize] takes in [viewport].
  ///
  /// [stashedPeek] is how much of the panel stays on-screen when stashed; it is
  /// consulted only by [StashedPlacement] and ignored by the other variants.
  Offset resolve(
    PanelViewport viewport,
    Size panelSize, {
    double stashedPeek = 0,
  });

  /// A JSON-encodable snapshot suitable for persistence.
  Map<String, Object?> toJson();

  /// Reverses [toJson].
  ///
  /// Throws [FormatException] if [json] is missing its discriminator or names
  /// a variant, corner, or edge this version does not know.
  static PanelPlacement fromJson(Map<String, Object?> json) {
    final type = json['type'];
    return switch (type) {
      'corner' => CornerPlacement(
        _enumByName(PanelCorner.values, json['corner'], 'corner'),
      ),
      'free' => FreePlacement(
        (json['directional'] ?? false) == true
            ? AlignmentDirectional(
                _asDouble(json['x'], 'x'),
                _asDouble(json['y'], 'y'),
              )
            : Alignment(_asDouble(json['x'], 'x'), _asDouble(json['y'], 'y')),
      ),
      'stashed' => StashedPlacement(
        _enumByName(PanelEdge.values, json['edge'], 'edge'),
        verticalAlignment: _asDouble(json['y'], 'y'),
      ),
      _ => throw FormatException('Unknown placement type: $type', json),
    };
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    Object? name,
    String field,
  ) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw FormatException('Unknown $field: $name');
  }

  static double _asDouble(Object? value, String field) => switch (value) {
    final num number => number.toDouble(),
    _ => throw FormatException('Expected a number for $field, got $value'),
  };
}

/// A [PanelPlacement] anchored to one of the four corners.
@immutable
final class CornerPlacement extends PanelPlacement {
  const CornerPlacement(this.corner);

  final PanelCorner corner;

  @override
  Offset resolve(
    PanelViewport viewport,
    Size panelSize, {
    double stashedPeek = 0,
  }) {
    final travel = viewport.travelFor(panelSize);
    final alignment = corner.resolve(viewport.direction);
    return Offset(
      _pick(alignment.x, travel.left, travel.right),
      _pick(alignment.y, travel.top, travel.bottom),
    );
  }

  @override
  Map<String, Object?> toJson() => {'type': 'corner', 'corner': corner.name};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CornerPlacement && other.corner == corner;

  @override
  int get hashCode => corner.hashCode;

  @override
  String toString() => 'PanelPlacement.corner(${corner.name})';
}

/// A [PanelPlacement] at an arbitrary normalized position.
@immutable
final class FreePlacement extends PanelPlacement {
  const FreePlacement(this.alignment);

  /// Normalized position within [PanelViewport.bounds], in the same `-1..1`
  /// coordinate space as [Alignment].
  final AlignmentGeometry alignment;

  @override
  Offset resolve(
    PanelViewport viewport,
    Size panelSize, {
    double stashedPeek = 0,
  }) => alignment
      .resolve(viewport.direction)
      .inscribe(panelSize, viewport.bounds)
      .topLeft;

  @override
  Map<String, Object?> toJson() {
    final directional = alignment is AlignmentDirectional;
    final resolved = alignment.resolve(TextDirection.ltr);
    return {
      'type': 'free',
      'x': resolved.x,
      'y': resolved.y,
      'directional': directional,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FreePlacement && other.alignment == alignment;

  @override
  int get hashCode => alignment.hashCode;

  @override
  String toString() => 'PanelPlacement.free($alignment)';
}

/// A [PanelPlacement] parked off-screen against a vertical edge.
@immutable
final class StashedPlacement extends PanelPlacement {
  const StashedPlacement(this.edge, {this.verticalAlignment = 0});

  final PanelEdge edge;

  /// Vertical position within the travel range, from `-1` (top) to `1`
  /// (bottom). Preserved from wherever the panel was flung, because a stash is
  /// a horizontal gesture and moving vertically would break spatial continuity.
  final double verticalAlignment;

  @override
  Offset resolve(
    PanelViewport viewport,
    Size panelSize, {
    double stashedPeek = 0,
  }) {
    final travel = viewport.travelFor(panelSize);
    final hidden = (panelSize.width - stashedPeek).clamp(0.0, panelSize.width);
    final x = edge.resolvesToLeft(viewport.direction)
        ? travel.left - hidden
        : travel.right + hidden;
    return Offset(x, _pick(verticalAlignment, travel.top, travel.bottom));
  }

  @override
  Map<String, Object?> toJson() => {
    'type': 'stashed',
    'edge': edge.name,
    'y': verticalAlignment,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StashedPlacement &&
          other.edge == edge &&
          other.verticalAlignment == verticalAlignment;

  @override
  int get hashCode => Object.hash(edge, verticalAlignment);

  @override
  String toString() =>
      'PanelPlacement.stashed(${edge.name}, y: $verticalAlignment)';
}

/// Maps a `-1..1` alignment component onto a travel range, centring the panel
/// when the range is inverted because the panel is larger than its bounds.
double _pick(double alignment, double low, double high) {
  if (high < low) return (low + high) / 2;
  return low + (alignment + 1) / 2 * (high - low);
}
