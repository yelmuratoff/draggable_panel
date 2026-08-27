import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// How large the panel becomes when expanded.
@immutable
sealed class PanelExtent {
  const PanelExtent();

  /// Always exactly [size], capped at the available bounds.
  const factory PanelExtent.fixed(Size size) = FixedExtent;

  /// A fraction of the available bounds on each axis.
  const factory PanelExtent.fraction({double width, double height}) =
      FractionExtent;

  /// As large as the content needs, capped by [ContentExtent.maxWidth] and
  /// [ContentExtent.maxHeightFraction].
  const factory PanelExtent.content({
    double? maxWidth,
    double? maxHeightFraction,
  }) = ContentExtent;

  /// The expanded size inside [bounds].
  ///
  /// [intrinsicContent] is the size the expanded content measured itself at,
  /// and is consulted only by [ContentExtent].
  Size resolve(Rect bounds, Size intrinsicContent);
}

/// A [PanelExtent] of a constant size.
@immutable
final class FixedExtent extends PanelExtent {
  const FixedExtent(this.size);

  final Size size;

  @override
  Size resolve(Rect bounds, Size intrinsicContent) => Size(
    math.min(size.width, bounds.width),
    math.min(size.height, bounds.height),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FixedExtent && other.size == size;

  @override
  int get hashCode => size.hashCode;

  @override
  String toString() => 'PanelExtent.fixed($size)';
}

/// A [PanelExtent] expressed as a fraction of the available bounds.
@immutable
final class FractionExtent extends PanelExtent {
  const FractionExtent({this.width = 0.9, this.height = 0.5})
    : assert(width > 0 && width <= 1, 'width must be in the range (0, 1]'),
      assert(height > 0 && height <= 1, 'height must be in the range (0, 1]');

  final double width;
  final double height;

  @override
  Size resolve(Rect bounds, Size intrinsicContent) =>
      Size(bounds.width * width, bounds.height * height);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FractionExtent && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'PanelExtent.fraction(width: $width, height: $height)';
}

/// A [PanelExtent] driven by the measured size of the expanded content.
@immutable
final class ContentExtent extends PanelExtent {
  const ContentExtent({this.maxWidth, this.maxHeightFraction})
    : assert(maxWidth == null || maxWidth > 0, 'maxWidth must be positive'),
      assert(
        maxHeightFraction == null ||
            (maxHeightFraction > 0 && maxHeightFraction <= 1),
        'maxHeightFraction must be in the range (0, 1]',
      );

  /// Upper bound on the resolved width, before the bounds cap.
  final double? maxWidth;

  /// Upper bound on the resolved height as a fraction of the bounds height.
  final double? maxHeightFraction;

  @override
  Size resolve(Rect bounds, Size intrinsicContent) {
    final widthCap = math.min(maxWidth ?? bounds.width, bounds.width);
    final heightCap = math.min(
      bounds.height * (maxHeightFraction ?? 1),
      bounds.height,
    );
    return Size(
      math.min(intrinsicContent.width, widthCap),
      math.min(intrinsicContent.height, heightCap),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentExtent &&
          other.maxWidth == maxWidth &&
          other.maxHeightFraction == maxHeightFraction;

  @override
  int get hashCode => Object.hash(maxWidth, maxHeightFraction);

  @override
  String toString() =>
      'PanelExtent.content(maxWidth: $maxWidth, '
      'maxHeightFraction: $maxHeightFraction)';
}
