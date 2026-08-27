import 'package:flutter/widgets.dart';

/// One of the four corners a collapsed panel can rest in.
///
/// Corners are *directional*: `start` and `end` resolve to the physical left or
/// right edge according to the ambient [TextDirection], so a panel configured
/// to rest in [PanelCorner.bottomStart] appears bottom-left under
/// [TextDirection.ltr] and bottom-right under [TextDirection.rtl].
///
/// A corner is resolution-independent, which is what lets a persisted resting
/// position survive rotation, a window resize, or restoring onto a different
/// device.
enum PanelCorner {
  topStart,
  topEnd,
  bottomStart,
  bottomEnd;

  /// Whether this corner sits against the top edge.
  bool get isTop => this == topStart || this == topEnd;

  /// Whether this corner sits against the directional start edge.
  bool get isStart => this == topStart || this == bottomStart;

  /// The physical alignment of this corner for [direction].
  ///
  /// `x` is `-1` for the physical left edge and `1` for the right; `y` is `-1`
  /// for the top edge and `1` for the bottom.
  Alignment resolve(TextDirection direction) => Alignment(
    isStart == (direction == TextDirection.ltr) ? -1 : 1,
    isTop ? -1 : 1,
  );

  /// The corner reached by moving one step in [direction] from this one, or
  /// `null` when this corner is already against that side.
  ///
  /// Used by keyboard navigation, where arrow keys move the panel between
  /// corners rather than by pixels. [textDirection] resolves the directional
  /// `start`/`end` naming onto physical left and right.
  PanelCorner? neighbour(AxisDirection direction, TextDirection textDirection) {
    final alignment = resolve(textDirection);
    final target = switch (direction) {
      AxisDirection.up => Alignment(alignment.x, -1),
      AxisDirection.down => Alignment(alignment.x, 1),
      AxisDirection.left => Alignment(-1, alignment.y),
      AxisDirection.right => Alignment(1, alignment.y),
    };
    return target == alignment ? null : fromAlignment(target, textDirection);
  }

  /// The corner whose [resolve] equals [alignment] under [direction].
  ///
  /// Throws [ArgumentError] if [alignment] is not one of the four corners.
  static PanelCorner fromAlignment(
    Alignment alignment,
    TextDirection direction,
  ) => PanelCorner.values.firstWhere(
    (corner) => corner.resolve(direction) == alignment,
    orElse: () => throw ArgumentError.value(
      alignment,
      'alignment',
      'is not a corner alignment',
    ),
  );
}
