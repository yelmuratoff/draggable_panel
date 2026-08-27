import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:draggable_panel/src/model/panel_extent.dart';
import 'package:draggable_panel/src/motion/panel_motion_spec.dart';
import 'package:draggable_panel/src/theme/draggable_panel_theme_data.dart';
import 'package:flutter/material.dart';

/// A fully resolved [DraggablePanelThemeData], with no token left to inherit.
///
/// [DraggablePanelThemeData] is the authoring surface, where a null token means
/// "inherit". This is what the panel actually paints from, so nothing
/// downstream has to carry a fallback.
@immutable
final class PanelStyle {
  const PanelStyle({
    required this.collapsedShape,
    required this.shape,
    required this.clipBehavior,
    required this.surfaceColor,
    required this.surfaceFilter,
    required this.shadowColor,
    required this.elevation,
    required this.draggingElevation,
    required this.expandedElevation,
    required this.stashedElevation,
    required this.stashedOpacity,
    required this.collapsedSize,
    required this.expandedExtent,
    required this.margin,
    required this.stashedPeek,
    required this.stashedSize,
    required this.handleColor,
    required this.motion,
  });

  /// Resolves [override] over the app-wide extension over the built-in
  /// defaults, then applies the directional and minimum-size rules that need a
  /// [BuildContext].
  factory PanelStyle.resolve(
    BuildContext context, [
    DraggablePanelThemeData? override,
  ]) {
    final theme = Theme.of(context);
    final tokens = defaultPanelTheme(
      theme.colorScheme,
    ).merge(theme.extension<DraggablePanelThemeData>()).merge(override);

    final floor = tokens.minimumTapTarget ?? Size.zero;
    final collapsed = tokens.collapsedSize ?? Size.zero;

    return PanelStyle(
      collapsedShape: tokens.collapsedShape!,
      shape: tokens.shape!,
      clipBehavior: tokens.clipBehavior!,
      surfaceColor: tokens.surfaceColor!,
      surfaceFilter: tokens.surfaceFilter,
      shadowColor: tokens.shadowColor!,
      elevation: tokens.elevation!,
      draggingElevation: tokens.draggingElevation!,
      expandedElevation: tokens.expandedElevation!,
      stashedElevation: tokens.stashedElevation!,
      stashedOpacity: tokens.stashedOpacity!,
      collapsedSize: Size(
        math.max(collapsed.width, floor.width),
        math.max(collapsed.height, floor.height),
      ),
      expandedExtent: tokens.expandedExtent!,
      margin: tokens.margin!.resolve(Directionality.of(context)),
      stashedPeek: tokens.stashedPeek!,
      stashedSize: tokens.stashedSize!,
      handleColor: tokens.handleColor!,
      motion: tokens.motion!,
    );
  }

  final ShapeBorder collapsedShape;
  final ShapeBorder shape;
  final Clip clipBehavior;
  final Color surfaceColor;

  /// Filter applied behind the panel, clipped to its shape. Null for opaque.
  final ImageFilter? surfaceFilter;
  final Color shadowColor;
  final double elevation;
  final double draggingElevation;
  final double expandedElevation;

  /// Elevation while parked at an edge.
  final double stashedElevation;

  final double stashedOpacity;

  /// Collapsed size, already floored by the minimum tap target.
  final Size collapsedSize;

  final PanelExtent expandedExtent;
  final EdgeInsets margin;
  final double stashedPeek;

  /// Size the panel takes while parked at an edge.
  final Size stashedSize;
  final Color handleColor;
  final PanelMotionSpec motion;

  /// The shape at a given expansion progress.
  ShapeBorder shapeAt(double expansion) =>
      ShapeBorder.lerp(collapsedShape, shape, expansion.clamp(0.0, 1.0))!;

  /// The elevation at a given expansion progress.
  ///
  /// [isDragging] and [isStashed] each override the progress, returning
  /// [draggingElevation] and [stashedElevation]; dragging takes precedence.
  double elevationAt(
    double expansion, {
    required bool isDragging,
    bool isStashed = false,
  }) {
    if (isDragging) return draggingElevation;
    if (isStashed) return stashedElevation;
    return _lerp(elevation, expandedElevation, expansion.clamp(0.0, 1.0));
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PanelStyle &&
          other.collapsedShape == collapsedShape &&
          other.shape == shape &&
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
    stashedElevation,
    stashedOpacity,
    collapsedSize,
    expandedExtent,
    margin,
    stashedPeek,
    stashedSize,
    handleColor,
    motion,
  );
}

/// The built-in tokens, derived from [scheme] so the panel sits in the app's
/// Material 3 surface hierarchy rather than beside it.
///
/// Every token is populated, which is what lets [PanelStyle.resolve] finish
/// with no fallback of its own.
DraggablePanelThemeData defaultPanelTheme(ColorScheme scheme) =>
    DraggablePanelThemeData(
      collapsedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      surfaceColor: scheme.surfaceContainerHigh,
      shadowColor: scheme.shadow,
      elevation: 6,
      draggingElevation: 12,
      expandedElevation: 8,
      stashedElevation: 6,
      stashedOpacity: 1,
      collapsedSize: const Size(64, 64),
      expandedExtent: const PanelExtent.content(
        maxWidth: 360,
        maxHeightFraction: 0.6,
      ),
      margin: const EdgeInsetsDirectional.all(16),
      stashedPeek: 26,
      stashedSize: const Size(35, 70),
      handleColor: scheme.onSurface.withValues(alpha: 0.5),
      minimumTapTarget: const Size(48, 48),
      motion: PanelMotionSpec(),
    );
