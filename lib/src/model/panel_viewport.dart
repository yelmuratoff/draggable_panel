import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The resolved space a floating panel may occupy.
///
/// This is the single source of geometric truth for the panel. Rotation, a
/// window resize, split-screen, and the software keyboard all reduce to a
/// change in this value, so nothing downstream needs to special-case them.
@immutable
final class PanelViewport {
  const PanelViewport({
    required this.size,
    required this.safeArea,
    required this.viewInsets,
    required this.margin,
    required this.direction,
    required this.avoidKeyboard,
  });

  /// Reads the viewport from the ambient [MediaQuery].
  ///
  /// [safeArea] comes from [MediaQuery.viewPaddingOf] rather than
  /// `paddingOf` — `paddingOf` is already reduced by an open keyboard, which
  /// would make the panel jump as the keyboard animates.
  factory PanelViewport.of(
    BuildContext context, {
    required EdgeInsets margin,
    required bool avoidKeyboard,
  }) => PanelViewport(
    size: MediaQuery.sizeOf(context),
    safeArea: MediaQuery.viewPaddingOf(context),
    viewInsets: MediaQuery.viewInsetsOf(context),
    margin: margin,
    direction: Directionality.of(context),
    avoidKeyboard: avoidKeyboard,
  );

  /// The full size of the surface the panel floats above.
  final Size size;

  /// Padding taken by system chrome — notch, status bar, home indicator.
  final EdgeInsets safeArea;

  /// Insets taken by a system overlay that covers content, chiefly the
  /// software keyboard.
  final EdgeInsets viewInsets;

  /// Additional inset the panel keeps from the safe area.
  final EdgeInsets margin;

  /// Resolves the directional `start` and `end` of placements onto physical
  /// left and right.
  final TextDirection direction;

  /// Whether [bounds] shrinks to stay clear of the keyboard.
  final bool avoidKeyboard;

  /// The rect the panel's own rect must stay inside.
  ///
  /// May be empty when the viewport is smaller than its insets; callers that
  /// divide by a dimension must guard against that.
  Rect get bounds {
    final bottomInset = avoidKeyboard
        ? math.max(safeArea.bottom, viewInsets.bottom)
        : safeArea.bottom;
    final left = safeArea.left + margin.left;
    final top = safeArea.top + margin.top;
    return Rect.fromLTRB(
      left,
      top,
      math.max(left, size.width - safeArea.right - margin.right),
      math.max(top, size.height - bottomInset - margin.bottom),
    );
  }

  /// The rect of legal top-left positions for a panel of [panelSize].
  ///
  /// Returned inverted (`right < left` or `bottom < top`) when the panel is
  /// larger than [bounds] on that axis; the physics layer centres it in that
  /// case rather than clamping to a nonsensical edge.
  Rect travelFor(Size panelSize) {
    final area = bounds;
    return Rect.fromLTRB(
      area.left,
      area.top,
      area.right - panelSize.width,
      area.bottom - panelSize.height,
    );
  }

  PanelViewport copyWith({
    Size? size,
    EdgeInsets? safeArea,
    EdgeInsets? viewInsets,
    EdgeInsets? margin,
    TextDirection? direction,
    bool? avoidKeyboard,
  }) => PanelViewport(
    size: size ?? this.size,
    safeArea: safeArea ?? this.safeArea,
    viewInsets: viewInsets ?? this.viewInsets,
    margin: margin ?? this.margin,
    direction: direction ?? this.direction,
    avoidKeyboard: avoidKeyboard ?? this.avoidKeyboard,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PanelViewport &&
          other.size == size &&
          other.safeArea == safeArea &&
          other.viewInsets == viewInsets &&
          other.margin == margin &&
          other.direction == direction &&
          other.avoidKeyboard == avoidKeyboard;

  @override
  int get hashCode =>
      Object.hash(size, safeArea, viewInsets, margin, direction, avoidKeyboard);

  @override
  String toString() => 'PanelViewport(size: $size, bounds: $bounds)';
}
