import 'package:flutter/widgets.dart';

/// A vertical screen edge a collapsed panel can be stashed against.
///
/// Like [PanelCorner], edges are directional: `start` resolves to the physical
/// left edge under [TextDirection.ltr] and the right edge under
/// [TextDirection.rtl].
enum PanelEdge {
  start,
  end;

  /// The physical horizontal alignment of this edge for [direction]: `-1` for
  /// the left edge, `1` for the right.
  double resolveX(TextDirection direction) =>
      (this == start) == (direction == TextDirection.ltr) ? -1 : 1;

  /// Whether this edge resolves to the physical left edge under [direction].
  bool resolvesToLeft(TextDirection direction) => resolveX(direction) < 0;
}
