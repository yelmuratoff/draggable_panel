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
    this.stashedShape,
    this.clipBehavior,
    this.surfaceColor,
    this.surfaceFilter,
    this.shadowColor,
    this.elevation,
    this.draggingElevation,
    this.expandedElevation,
    this.stashedElevation,
    this.stashedOpacity,
    this.collapsedSize,
    this.expandedExtent,
    this.margin,
    this.stashedPeek,
    this.stashedSize,
    this.handleColor,
    this.handleSize,
    this.handleStrokeWidth,
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

  /// Shape of the panel while parked at an edge, interpolated towards
  /// [collapsedShape] as it is drawn out.
  ///
  /// A tab tucked into the screen usually wants its outer corners flattened,
  /// which the collapsed shape has no way to express.
  final ShapeBorder? stashedShape;

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

  /// Elevation while parked at an edge, where the panel is tucked into the
  /// screen rather than hovering over the page.
  final double? stashedElevation;

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

  /// Size the panel takes while parked at an edge.
  ///
  /// A tab is taller than it is wide, so it reads as something to pull rather
  /// than as the panel with most of it missing. Interpolated towards
  /// [collapsedSize] as the panel is drawn out.
  final Size? stashedSize;

  /// Colour of the grab affordance drawn on that tab.
  final Color? handleColor;

  /// Box the grab affordance's curve is drawn in, centred on the tab.
  final Size? handleSize;

  /// Stroke width of that curve.
  final double? handleStrokeWidth;

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
      stashedShape: other.stashedShape,
      clipBehavior: other.clipBehavior,
      surfaceColor: other.surfaceColor,
      surfaceFilter: other.surfaceFilter,
      shadowColor: other.shadowColor,
      elevation: other.elevation,
      draggingElevation: other.draggingElevation,
      expandedElevation: other.expandedElevation,
      stashedElevation: other.stashedElevation,
      stashedOpacity: other.stashedOpacity,
      collapsedSize: other.collapsedSize,
      expandedExtent: other.expandedExtent,
      margin: other.margin,
      stashedPeek: other.stashedPeek,
      stashedSize: other.stashedSize,
      handleColor: other.handleColor,
      handleSize: other.handleSize,
      handleStrokeWidth: other.handleStrokeWidth,
      minimumTapTarget: other.minimumTapTarget,
      motion: other.motion,
    );
  }

  @override
  DraggablePanelThemeData copyWith({
    ShapeBorder? collapsedShape,
    ShapeBorder? shape,
    ShapeBorder? stashedShape,
    Clip? clipBehavior,
    Color? surfaceColor,
    ImageFilter? surfaceFilter,
    Color? shadowColor,
    double? elevation,
    double? draggingElevation,
    double? expandedElevation,
    double? stashedElevation,
    double? stashedOpacity,
    Size? collapsedSize,
    PanelExtent? expandedExtent,
    EdgeInsetsGeometry? margin,
    double? stashedPeek,
    Size? stashedSize,
    Color? handleColor,
    Size? handleSize,
    double? handleStrokeWidth,
    Size? minimumTapTarget,
    PanelMotionSpec? motion,
  }) => DraggablePanelThemeData(
    collapsedShape: collapsedShape ?? this.collapsedShape,
    shape: shape ?? this.shape,
    stashedShape: stashedShape ?? this.stashedShape,
    clipBehavior: clipBehavior ?? this.clipBehavior,
    surfaceColor: surfaceColor ?? this.surfaceColor,
    surfaceFilter: surfaceFilter ?? this.surfaceFilter,
    shadowColor: shadowColor ?? this.shadowColor,
    elevation: elevation ?? this.elevation,
    draggingElevation: draggingElevation ?? this.draggingElevation,
    expandedElevation: expandedElevation ?? this.expandedElevation,
    stashedElevation: stashedElevation ?? this.stashedElevation,
    stashedOpacity: stashedOpacity ?? this.stashedOpacity,
    collapsedSize: collapsedSize ?? this.collapsedSize,
    expandedExtent: expandedExtent ?? this.expandedExtent,
    margin: margin ?? this.margin,
    stashedPeek: stashedPeek ?? this.stashedPeek,
    stashedSize: stashedSize ?? this.stashedSize,
    handleColor: handleColor ?? this.handleColor,
    handleSize: handleSize ?? this.handleSize,
    handleStrokeWidth: handleStrokeWidth ?? this.handleStrokeWidth,
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
      stashedShape: ShapeBorder.lerp(stashedShape, other.stashedShape, t),
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
      stashedElevation: lerpDouble(stashedElevation, other.stashedElevation, t),
      stashedOpacity: lerpDouble(stashedOpacity, other.stashedOpacity, t),
      collapsedSize: Size.lerp(collapsedSize, other.collapsedSize, t),
      expandedExtent: t < 0.5 ? expandedExtent : other.expandedExtent,
      margin: EdgeInsetsGeometry.lerp(margin, other.margin, t),
      stashedPeek: lerpDouble(stashedPeek, other.stashedPeek, t),
      stashedSize: Size.lerp(stashedSize, other.stashedSize, t),
      handleColor: Color.lerp(handleColor, other.handleColor, t),
      handleSize: Size.lerp(handleSize, other.handleSize, t),
      handleStrokeWidth: lerpDouble(
        handleStrokeWidth,
        other.handleStrokeWidth,
        t,
      ),
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
        DiagnosticsProperty<ShapeBorder>(
          'stashedShape',
          stashedShape,
          defaultValue: null,
        ),
      )
      ..add(
        EnumProperty<Clip>('clipBehavior', clipBehavior, defaultValue: null),
      )
      ..add(ColorProperty('surfaceColor', surfaceColor, defaultValue: null))
      ..add(
        DiagnosticsProperty<ImageFilter>(
          'surfaceFilter',
          surfaceFilter,
          defaultValue: null,
        ),
      )
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
        DoubleProperty(
          'stashedElevation',
          stashedElevation,
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
          'stashedSize',
          stashedSize,
          defaultValue: null,
        ),
      )
      ..add(ColorProperty('handleColor', handleColor, defaultValue: null))
      ..add(
        DiagnosticsProperty<Size>('handleSize', handleSize, defaultValue: null),
      )
      ..add(
        DoubleProperty(
          'handleStrokeWidth',
          handleStrokeWidth,
          defaultValue: null,
        ),
      )
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
          other.stashedShape == stashedShape &&
          other.clipBehavior == clipBehavior &&
          other.surfaceColor == surfaceColor &&
          other.surfaceFilter == surfaceFilter &&
          other.shadowColor == shadowColor &&
          other.elevation == elevation &&
          other.draggingElevation == draggingElevation &&
          other.expandedElevation == expandedElevation &&
          other.stashedElevation == stashedElevation &&
          other.stashedOpacity == stashedOpacity &&
          other.collapsedSize == collapsedSize &&
          other.expandedExtent == expandedExtent &&
          other.margin == margin &&
          other.stashedPeek == stashedPeek &&
          other.stashedSize == stashedSize &&
          other.handleColor == handleColor &&
          other.handleSize == handleSize &&
          other.handleStrokeWidth == handleStrokeWidth &&
          other.minimumTapTarget == minimumTapTarget &&
          other.motion == motion;

  @override
  int get hashCode => Object.hashAll([
    collapsedShape,
    shape,
    stashedShape,
    clipBehavior,
    surfaceColor,
    surfaceFilter,
    shadowColor,
    elevation,
    draggingElevation,
    expandedElevation,
    stashedElevation,
    stashedOpacity,
    collapsedSize,
    expandedExtent,
    margin,
    stashedPeek,
    stashedSize,
    handleColor,
    handleSize,
    handleStrokeWidth,
    minimumTapTarget,
    motion,
  ]);
}
