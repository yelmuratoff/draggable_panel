import 'package:draggable_panel/src/core/render_panel_surface.dart';
import 'package:draggable_panel/src/theme/panel_style.dart';
import 'package:flutter/widgets.dart';

/// Hosts the panel's two contents inside a single morphing surface.
///
/// Everything that changes per animation frame arrives through [repaint] rather
/// than through the constructor, so the widget itself is rebuilt only when the
/// panel's *configuration* changes — never because it moved.
final class PanelSurface
    extends SlottedMultiChildRenderObjectWidget<PanelSlot, RenderBox> {
  const PanelSurface({
    required this.repaint,
    required this.style,
    required this.originOf,
    required this.expansionOf,
    required this.anchor,
    required this.bounds,
    required this.isDragging,
    required this.isStashed,
    required this.isParking,
    required this.reduceMotion,
    required this.opacity,
    required this.collapsed,
    required this.expanded,
    required this.handle,
    super.key,
  });

  /// Notifies the render object that a frame needs repainting.
  final Listenable repaint;

  final PanelStyle style;

  /// Reads the panel's collapsed top-left at paint time.
  final ValueGetter<Offset> originOf;

  /// Reads the panel's expansion progress at paint time.
  final ValueGetter<double> expansionOf;

  /// Which corner stays pinned as the panel grows.
  final Alignment anchor;

  /// Insets from this widget's own box that the panel must stay within.
  final EdgeInsets bounds;

  final bool isDragging;
  final bool isStashed;

  /// Whether the panel is at, or on its way to, a parked placement.
  final bool isParking;

  final bool reduceMotion;

  /// Overall opacity, used to fade the panel out when hidden.
  final double opacity;

  final Widget collapsed;
  final Widget expanded;

  /// The grab affordance painted over the sliver a parked panel leaves showing.
  final Widget handle;

  @override
  Iterable<PanelSlot> get slots => PanelSlot.values;

  @override
  Widget? childForSlot(PanelSlot slot) => switch (slot) {
    PanelSlot.collapsed => collapsed,
    PanelSlot.expanded => expanded,
    PanelSlot.handle => handle,
  };

  @override
  RenderPanelSurface createRenderObject(BuildContext context) =>
      RenderPanelSurface(
        repaint: repaint,
        style: style,
        originOf: originOf,
        expansionOf: expansionOf,
        anchor: anchor,
        collapsedSize: style.collapsedSize,
        bounds: bounds,
        isDragging: isDragging,
        isStashed: isStashed,
        isParking: isParking,
        reduceMotion: reduceMotion,
        opacity: opacity,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderPanelSurface renderObject,
  ) {
    renderObject
      ..repaint = repaint
      ..style = style
      ..originOf = originOf
      ..expansionOf = expansionOf
      ..anchor = anchor
      ..collapsedSize = style.collapsedSize
      ..bounds = bounds
      ..isDragging = isDragging
      ..isStashed = isStashed
      ..isParking = isParking
      ..reduceMotion = reduceMotion
      ..opacity = opacity;
  }
}
