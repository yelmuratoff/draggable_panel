import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:draggable_panel/src/model/panel_extent.dart';
import 'package:draggable_panel/src/motion/panel_motion_spec.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Visual and motion tokens for a `DraggablePanel`.
///
/// Every token is nullable, meaning "inherit". Values resolve in three layers:
/// built-in defaults derived from the ambient [ColorScheme], then any
/// [DraggablePanelThemeData] registered in [ThemeData.extensions], then the
/// `theme` passed to the widget itself.
///
/// Register it app-wide like any other extension:
///
/// ```dart
/// ThemeData(extensions: [DraggablePanelThemeData(elevation: 10)])
/// ```
@immutable
final class DraggablePanelThemeData
    extends ThemeExtension<DraggablePanelThemeData>
    with Diagnosticable {
  const DraggablePanelThemeData({
    this.collapsedShape,
    this.shape,
    this.clipBehavior,
    this.surfaceColor,
    this.surfaceFilter,
    this.shadowColor,
    this.elevation,
    this.draggingElevation,
    this.expandedElevation,
    this.stashedOpacity,
    this.collapsedSize,
    this.expandedExtent,
    this.margin,
    this.stashedPeek,
    this.minimumTapTarget,
    this.motion,
  });

  /// Shape of the panel while collapsed.
  ///
  /// Pass a `RoundedSuperellipseBorder` here for iOS-style continuous corners;
  /// the default stays a plain rounded rectangle to match Material 3.
  final ShapeBorder? collapsedShape;

  /// Shape of the panel while expanded, interpolated towards from
  /// [collapsedShape] as the panel grows.
  final ShapeBorder? shape;

  final Clip? clipBehavior;

  final Color? surfaceColor;

  /// Filter applied to whatever is behind the panel, clipped to its shape.
  ///
  /// This is the seam for a frosted-glass surface. Pair it with a translucent
  /// [surfaceColor], or the fill will hide the blur:
  ///
  /// ```dart
  /// DraggablePanelThemeData(
  ///   surfaceFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
  ///   surfaceColor: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
  /// )
  /// ```
  ///
  /// Costs a backdrop pass every frame the panel moves; leave it null for the
  /// opaque Material default.
  final ImageFilter? surfaceFilter;

  final Color? shadowColor;

  /// Elevation while collapsed and at rest.
  final double? elevation;

  /// Elevation while a pointer is dragging the panel, lifting it off the page.
  final double? draggingElevation;

  /// Elevation while expanded.
  final double? expandedElevation;

  /// Opacity applied while the panel is stashed against an edge.
  final double? stashedOpacity;

  /// Size of the collapsed panel, floored by [minimumTapTarget].
  final Size? collapsedSize;

  /// How large the panel becomes when expanded.
  final PanelExtent? expandedExtent;

  /// Inset kept between the panel and the safe area.
  final EdgeInsetsGeometry? margin;

  /// How much of a stashed panel stays on-screen as a grab tab.
  final double? stashedPeek;

  /// Lower bound applied to [collapsedSize] so the panel stays tappable.
  final Size? minimumTapTarget;

  /// Springs and thresholds governing how the panel moves.
  final PanelMotionSpec? motion;

  /// Returns a copy with every non-null token of [other] laid over this one.
  DraggablePanelThemeData merge(DraggablePanelThemeData? other) {
    if (other == null) return this;
    return copyWith(
      collapsedShape: other.collapsedShape,
      shape: other.shape,
      clipBehavior: other.clipBehavior,
      surfaceColor: other.surfaceColor,
      surfaceFilter: other.surfaceFilter,
      shadowColor: other.shadowColor,
      elevation: other.elevation,
      draggingElevation: other.draggingElevation,
      expandedElevation: other.expandedElevation,
      stashedOpacity: other.stashedOpacity,
      collapsedSize: other.collapsedSize,
      expandedExtent: other.expandedExtent,
      margin: other.margin,
      stashedPeek: other.stashedPeek,
      minimumTapTarget: other.minimumTapTarget,
      motion: other.motion,
    );
  }

  @override
  DraggablePanelThemeData copyWith({
    ShapeBorder? collapsedShape,
    ShapeBorder? shape,
    Clip? clipBehavior,
    Color? surfaceColor,
    ImageFilter? surfaceFilter,
    Color? shadowColor,
    double? elevation,
    double? draggingElevation,
    double? expandedElevation,
    double? stashedOpacity,
    Size? collapsedSize,
    PanelExtent? expandedExtent,
    EdgeInsetsGeometry? margin,
    double? stashedPeek,
    Size? minimumTapTarget,
    PanelMotionSpec? motion,
  }) => DraggablePanelThemeData(
    collapsedShape: collapsedShape ?? this.collapsedShape,
    shape: shape ?? this.shape,
    clipBehavior: clipBehavior ?? this.clipBehavior,
    surfaceColor: surfaceColor ?? this.surfaceColor,
    surfaceFilter: surfaceFilter ?? this.surfaceFilter,
    shadowColor: shadowColor ?? this.shadowColor,
    elevation: elevation ?? this.elevation,
    draggingElevation: draggingElevation ?? this.draggingElevation,
    expandedElevation: expandedElevation ?? this.expandedElevation,
    stashedOpacity: stashedOpacity ?? this.stashedOpacity,
    collapsedSize: collapsedSize ?? this.collapsedSize,
    expandedExtent: expandedExtent ?? this.expandedExtent,
    margin: margin ?? this.margin,
    stashedPeek: stashedPeek ?? this.stashedPeek,
    minimumTapTarget: minimumTapTarget ?? this.minimumTapTarget,
    motion: motion ?? this.motion,
  );

  /// Interpolates towards [other], so a theme swap crossfades rather than snaps.
  ///
  /// Discrete tokens — the clip, the expanded extent, and the motion spec —
  /// switch over at the midpoint instead of blending, because a spring halfway
  /// between two stiffnesses is not a spring anyone asked for.
  @override
  DraggablePanelThemeData lerp(DraggablePanelThemeData? other, double t) {
    if (other == null) return this;
    return DraggablePanelThemeData(
      collapsedShape: ShapeBorder.lerp(collapsedShape, other.collapsedShape, t),
      shape: ShapeBorder.lerp(shape, other.shape, t),
      clipBehavior: t < 0.5 ? clipBehavior : other.clipBehavior,
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t),
      surfaceFilter: t < 0.5 ? surfaceFilter : other.surfaceFilter,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t),
      elevation: lerpDouble(elevation, other.elevation, t),
      draggingElevation: lerpDouble(
        draggingElevation,
        other.draggingElevation,
        t,
      ),
      expandedElevation: lerpDouble(
        expandedElevation,
        other.expandedElevation,
        t,
      ),
      stashedOpacity: lerpDouble(stashedOpacity, other.stashedOpacity, t),
      collapsedSize: Size.lerp(collapsedSize, other.collapsedSize, t),
      expandedExtent: t < 0.5 ? expandedExtent : other.expandedExtent,
      margin: EdgeInsetsGeometry.lerp(margin, other.margin, t),
      stashedPeek: lerpDouble(stashedPeek, other.stashedPeek, t),
      minimumTapTarget: Size.lerp(minimumTapTarget, other.minimumTapTarget, t),
      motion: PanelMotionSpec.lerp(motion, other.motion, t),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<ShapeBorder>(
          'collapsedShape',
          collapsedShape,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null),
      )
      ..add(
        EnumProperty<Clip>('clipBehavior', clipBehavior, defaultValue: null),
      )
      ..add(ColorProperty('surfaceColor', surfaceColor, defaultValue: null))
      ..add(ColorProperty('shadowColor', shadowColor, defaultValue: null))
      ..add(DoubleProperty('elevation', elevation, defaultValue: null))
      ..add(
        DoubleProperty(
          'draggingElevation',
          draggingElevation,
          defaultValue: null,
        ),
      )
      ..add(
        DoubleProperty(
          'expandedElevation',
          expandedElevation,
          defaultValue: null,
        ),
      )
      ..add(
        DoubleProperty('stashedOpacity', stashedOpacity, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<Size>(
          'collapsedSize',
          collapsedSize,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<PanelExtent>(
          'expandedExtent',
          expandedExtent,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'margin',
          margin,
          defaultValue: null,
        ),
      )
      ..add(DoubleProperty('stashedPeek', stashedPeek, defaultValue: null))
      ..add(
        DiagnosticsProperty<Size>(
          'minimumTapTarget',
          minimumTapTarget,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<PanelMotionSpec>(
          'motion',
          motion,
          defaultValue: null,
        ),
      );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DraggablePanelThemeData &&
          other.collapsedShape == collapsedShape &&
          other.shape == shape &&
          other.clipBehavior == clipBehavior &&
          other.surfaceColor == surfaceColor &&
          other.surfaceFilter == surfaceFilter &&
          other.shadowColor == shadowColor &&
          other.elevation == elevation &&
          other.draggingElevation == draggingElevation &&
          other.expandedElevation == expandedElevation &&
          other.stashedOpacity == stashedOpacity &&
          other.collapsedSize == collapsedSize &&
          other.expandedExtent == expandedExtent &&
          other.margin == margin &&
          other.stashedPeek == stashedPeek &&
          other.minimumTapTarget == minimumTapTarget &&
          other.motion == motion;

  @override
  int get hashCode => Object.hash(
    collapsedShape,
    shape,
    clipBehavior,
    surfaceColor,
    surfaceFilter,
    shadowColor,
    elevation,
    draggingElevation,
    expandedElevation,
    stashedOpacity,
    collapsedSize,
    expandedExtent,
    margin,
    stashedPeek,
    minimumTapTarget,
    motion,
  );
}
