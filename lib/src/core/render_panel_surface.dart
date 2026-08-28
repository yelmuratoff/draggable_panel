import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:draggable_panel/src/motion/panel_frame.dart';
import 'package:draggable_panel/src/theme/panel_style.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Which piece of panel content a child provides.
enum PanelSlot { collapsed, expanded, handle }

/// Paints the panel as one surface that grows between its two contents.
///
/// The whole animation lives in [paint]: position, size, corner radius,
/// elevation, and the cross-fade are all painting concerns here, so an
/// animation frame costs one `markNeedsPaint` and no layout or rebuild at all.
/// Children are laid out once at their natural sizes and revealed by a growing
/// clip, which is why arbitrary content never stretches.
final class RenderPanelSurface extends RenderBox
    with SlottedContainerRenderObjectMixin<PanelSlot, RenderBox> {
  RenderPanelSurface({
    required Listenable repaint,
    required PanelStyle style,
    required this.originOf,
    required this.expansionOf,
    required Alignment anchor,
    required Size collapsedSize,
    required EdgeInsets bounds,
    required bool isDragging,
    required bool isStashed,
    required bool reduceMotion,
    required double opacity,
  }) : _repaint = repaint,
       _style = style,
       _anchor = anchor,
       _collapsedSize = collapsedSize,
       _bounds = bounds,
       _isDragging = isDragging,
       _isStashed = isStashed,
       _reduceMotion = reduceMotion,
       _opacity = opacity;

  Listenable _repaint;
  PanelStyle _style;

  /// Reads the panel's collapsed top-left, called afresh on every paint.
  ValueGetter<Offset> originOf;

  /// Reads the panel's expansion progress, called afresh on every paint.
  ValueGetter<double> expansionOf;

  Alignment _anchor;
  Size _collapsedSize;
  EdgeInsets _bounds;
  bool _isDragging;
  bool _isStashed;
  bool _reduceMotion;
  double _opacity;

  Size _expandedSize = Size.zero;
  Rect _paintedRect = Rect.zero;
  double _paintOpacity = 1;

  final LayerHandle<ClipPathLayer> _clipLayer = LayerHandle<ClipPathLayer>();
  final LayerHandle<OpacityLayer> _collapsedLayer = LayerHandle<OpacityLayer>();
  final LayerHandle<OpacityLayer> _expandedLayer = LayerHandle<OpacityLayer>();
  final LayerHandle<OpacityLayer> _handleLayer = LayerHandle<OpacityLayer>();
  final LayerHandle<OpacityLayer> _borderLayer = LayerHandle<OpacityLayer>();
  final LayerHandle<BackdropFilterLayer> _backdropLayer =
      LayerHandle<BackdropFilterLayer>();

  /// The size the expanded content was laid out at.
  Size get expandedSize => _expandedSize;

  /// The rect the panel occupied when it was last painted.
  ///
  /// Hit testing and the gesture layer both work from this, so a tap outside
  /// the visible panel reaches the application behind it.
  Rect get paintedRect => _paintedRect;

  Listenable get repaint => _repaint;

  set repaint(Listenable value) {
    if (identical(_repaint, value)) return;
    if (attached) _repaint.removeListener(markNeedsPaint);
    _repaint = value;
    if (attached) _repaint.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  PanelStyle get style => _style;

  set style(PanelStyle value) {
    if (_style == value) return;
    final resize =
        _style.expandedExtent != value.expandedExtent ||
        _style.stashedPeek != value.stashedPeek ||
        _style.stashedSize != value.stashedSize;
    _style = value;
    if (resize) {
      markNeedsLayout();
    } else {
      markNeedsPaint();
    }
  }

  Alignment get anchor => _anchor;

  set anchor(Alignment value) =>
      _setPaintField(value, _anchor, () => _anchor = value);

  bool get isDragging => _isDragging;

  set isDragging(bool value) =>
      _setPaintField(value, _isDragging, () => _isDragging = value);

  bool get isStashed => _isStashed;

  set isStashed(bool value) =>
      _setPaintField(value, _isStashed, () => _isStashed = value);

  /// The alpha the panel was last painted at: [opacity] folded together with
  /// the parked fade.
  ///
  /// Separate from [opacity], which is visibility alone — a parked panel is
  /// drawn back into the page but still takes a tap.
  double get paintOpacity => _paintOpacity;

  double get opacity => _opacity;

  set opacity(double value) =>
      _setPaintField(value, _opacity, () => _opacity = value);

  bool get reduceMotion => _reduceMotion;

  set reduceMotion(bool value) =>
      _setPaintField(value, _reduceMotion, () => _reduceMotion = value);

  Size get collapsedSize => _collapsedSize;

  set collapsedSize(Size value) {
    if (_collapsedSize == value) return;
    _collapsedSize = value;
    markNeedsLayout();
  }

  EdgeInsets get bounds => _bounds;

  set bounds(EdgeInsets value) {
    if (_bounds == value) return;
    _bounds = value;
    markNeedsLayout();
  }

  void _setPaintField<T>(T next, T current, VoidCallback apply) {
    if (next == current) return;
    apply();
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _repaint.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _repaint.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void dispose() {
    _clipLayer.layer = null;
    _borderLayer.layer = null;
    _backdropLayer.layer = null;
    _collapsedLayer.layer = null;
    _expandedLayer.layer = null;
    _handleLayer.layer = null;
    super.dispose();
  }

  @override
  bool get sizedByParent => true;

  /// Keeps a repaint of the moving panel off the application behind it.
  ///
  /// Without this, `markNeedsPaint` walks up to the nearest ancestor boundary —
  /// often the root — and every frame of motion repaints the whole app.
  @override
  bool get isRepaintBoundary => true;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  /// The rect the panel must stay within, in this render object's coordinates.
  Rect get _freeRect => _bounds.deflateRect(Offset.zero & size);

  /// The handle fills the tab a parked panel shows.
  Size get _handleSize => handleSizeFor(_style.stashedSize, _style.stashedPeek);

  @override
  void performLayout() {
    childForSlot(
      PanelSlot.collapsed,
    )?.layout(BoxConstraints.tight(_collapsedSize));
    childForSlot(PanelSlot.handle)?.layout(BoxConstraints.tight(_handleSize));

    final expanded = childForSlot(PanelSlot.expanded);
    if (expanded == null) {
      _expandedSize = _collapsedSize;
      return;
    }

    final available = _freeRect;
    final requested = _style.expandedExtent.resolve(
      available,
      expanded.getDryLayout(BoxConstraints.loose(available.size)),
    );

    final target = Size(
      math.max(requested.width, _collapsedSize.width),
      math.max(requested.height, _collapsedSize.height),
    );

    expanded.layout(BoxConstraints.tight(target), parentUsesSize: true);
    _expandedSize = expanded.size;
  }

  PanelFrame _frame() => computePanelFrame(
    origin: originOf(),
    collapsedSize: _collapsedSize,
    expandedSize: _expandedSize,
    stashedSize: _style.stashedSize,
    anchor: _anchor,
    bounds: _freeRect,
    viewport: Offset.zero & size,
    stashedPeek: _style.stashedPeek,
    isDragging: _isDragging,
    expansion: expansionOf(),
    reduceMotion: _reduceMotion,
  );

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_opacity <= 0) {
      _paintedRect = Rect.zero;
      _clipLayer.layer = null;
      _borderLayer.layer = null;
      _backdropLayer.layer = null;
      _collapsedLayer.layer = null;
      _expandedLayer.layer = null;
      _handleLayer.layer = null;
      return;
    }

    final frame = _frame();
    _paintedRect = frame.rect;
    _paintOpacity =
        _opacity * lerpDouble(1, _style.stashedOpacity, frame.parkedFade)!;

    final shape = _style.shapeAt(frame.expansion, emergence: frame.emergence);
    final outline = _outlineOf(shape, frame.rect.shift(offset));

    _paintShadow(context, outline, frame);

    _clipLayer.layer = context.pushClipPath(
      needsCompositing,
      offset,
      frame.rect,
      _outlineOf(shape, frame.rect),
      (innerContext, innerOffset) =>
          _paintContents(innerContext, innerOffset, frame, shape),
      clipBehavior: _style.clipBehavior,
      oldLayer: _clipLayer.layer,
    );

    _borderLayer.layer = _paintBorder(context, offset, frame, shape);
  }

  Path _outlineOf(ShapeBorder shape, Rect rect) =>
      shape.getOuterPath(rect, textDirection: _style.textDirection);

  /// Strokes whatever the shape draws through its side, over the clipped
  /// contents — a stroke centred on the outline is half outside it.
  OpacityLayer? _paintBorder(
    PaintingContext context,
    Offset offset,
    PanelFrame frame,
    ShapeBorder shape,
  ) {
    void paintBorder(PaintingContext innerContext, Offset innerOffset) =>
        shape.paint(
          innerContext.canvas,
          frame.rect.shift(innerOffset),
          textDirection: _style.textDirection,
        );

    if (_paintOpacity >= 1) {
      paintBorder(context, offset);
      return null;
    }
    return context.pushOpacity(
      offset,
      (_paintOpacity * 255).round(),
      paintBorder,
      oldLayer: _borderLayer.layer,
    );
  }

  void _paintShadow(PaintingContext context, Path outline, PanelFrame frame) {
    final elevation = _style.elevationAt(
      frame.expansion,
      isDragging: _isDragging,
      isStashed: _isStashed,
    );
    if (elevation <= 0) return;

    context.canvas.drawShadow(
      outline,
      _style.shadowColor.withValues(alpha: _paintOpacity),
      elevation,
      false,
    );
  }

  void _paintContents(
    PaintingContext context,
    Offset offset,
    PanelFrame frame,
    ShapeBorder shape,
  ) {
    _paintFill(context, offset, frame, shape);

    _expandedLayer.layer = _paintSlot(
      context,
      childForSlot(PanelSlot.expanded),
      offset + frame.expandedOrigin,
      frame.expandedOpacity * _paintOpacity,
      _expandedLayer.layer,
    );
    _collapsedLayer.layer = _paintSlot(
      context,
      childForSlot(PanelSlot.collapsed),
      offset + frame.collapsedOrigin,
      frame.collapsedOpacity * _paintOpacity,
      _collapsedLayer.layer,
    );
    _handleLayer.layer = _paintSlot(
      context,
      childForSlot(PanelSlot.handle),
      offset + frame.handleOrigin,
      frame.handleOpacity * _paintOpacity,
      _handleLayer.layer,
    );
  }

  /// Fills the panel, blurring what is behind it first when a filter is set.
  ///
  /// Runs inside the shape clip, so the filter reaches only the panel's own
  /// footprint rather than the whole screen.
  void _paintFill(
    PaintingContext context,
    Offset offset,
    PanelFrame frame,
    ShapeBorder shape,
  ) {
    final fill = Paint()
      ..color = _style.surfaceColor.withValues(
        alpha: _style.surfaceColor.a * _paintOpacity,
      );

    void paintFill(PaintingContext innerContext, Offset innerOffset) {
      innerContext.canvas.drawPath(
        _outlineOf(shape, frame.rect.shift(innerOffset)),
        fill,
      );
    }

    final filter = _style.surfaceFilter;
    if (filter == null) {
      paintFill(context, offset);
      return;
    }

    final layer = (_backdropLayer.layer ?? BackdropFilterLayer())
      ..filter = filter;
    _backdropLayer.layer = layer;
    context.pushLayer(layer, paintFill, offset);
  }

  OpacityLayer? _paintSlot(
    PaintingContext context,
    RenderBox? child,
    Offset origin,
    double opacity,
    OpacityLayer? oldLayer,
  ) {
    if (child == null || opacity <= 0) return null;
    if (opacity >= 1) {
      context.paintChild(child, origin);
      return null;
    }
    return context.pushOpacity(
      origin,
      (opacity * 255).round(),
      (innerContext, innerOffset) =>
          innerContext.paintChild(child, innerOffset),
      oldLayer: oldLayer,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (_opacity <= 0 || !_paintedRect.contains(position)) return false;
    return super.hitTest(result, position: position);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final frame = _frame();
    return _hitSlot(
          result,
          childForSlot(PanelSlot.collapsed),
          frame.collapsedOrigin,
          position,
          frame.collapsedOpacity,
        ) ||
        _hitSlot(
          result,
          childForSlot(PanelSlot.expanded),
          frame.expandedOrigin,
          position,
          frame.expandedOpacity,
        );
  }

  bool _hitSlot(
    BoxHitTestResult result,
    RenderBox? child,
    Offset origin,
    Offset position,
    double opacity,
  ) {
    if (child == null || opacity <= 0) return false;
    return result.addWithPaintOffset(
      offset: origin,
      position: position,
      hitTest: (innerResult, transformed) =>
          child.hitTest(innerResult, position: transformed),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final frame = _frame();
    final origin = switch (child) {
      _ when identical(child, childForSlot(PanelSlot.collapsed)) =>
        frame.collapsedOrigin,
      _ when identical(child, childForSlot(PanelSlot.handle)) =>
        frame.handleOrigin,
      _ => frame.expandedOrigin,
    };
    transform.translateByDouble(origin.dx, origin.dy, 0, 1);
  }

  @override
  Iterable<RenderBox> get children => <RenderBox>[
    if (childForSlot(PanelSlot.expanded) case final expanded?) expanded,
    if (childForSlot(PanelSlot.collapsed) case final collapsed?) collapsed,
    if (childForSlot(PanelSlot.handle) case final handle?) handle,
  ];
}
