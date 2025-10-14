import 'package:draggable_panel/src/controller/controller.dart';
import 'package:draggable_panel/src/enums/panel_state.dart';
import 'package:draggable_panel/src/models/panel_button.dart';
import 'package:draggable_panel/src/models/panel_item.dart';
import 'package:draggable_panel/src/utils/colors.dart';
import 'package:draggable_panel/src/widgets/curve_line_paint.dart';
import 'package:draggable_panel/src/widgets/tooltip_snackbar.dart';
import 'package:flutter/material.dart';
part 'widgets/panel_button.dart';

/// `DraggablePanel` is a widget that can be dragged around the screen and can be
/// docked to the nearest edge of the screen. It can be used to create a floating
/// panel that can be used to show additional information or actions.
class DraggablePanel extends StatefulWidget {
  const DraggablePanel({
    required this.child,
    super.key,
    this.icon,
    this.backgroundColor,
    this.items = const [],
    this.buttons = const [],
    this.borderColor,
    this.borderWidth,
    this.buttonWidth = 35,
    this.buttonHeight = 70.0,
    this.borderRadius,
    this.controller,
    this.onPositionChanged,
    this.panelHeight,
  });

  final DraggablePanelController? controller;

  /// The child widget that will be used as the main content of the screen.
  final Widget? child;

  /// The icon in the draggable button that will be used to drag the panel around
  /// the screen.
  ///
  /// I recommend use it with `dockType` option.
  final Widget? icon;

  /// The color of the border of the panel.
  final Color? borderColor;

  /// The width of the border of the panel.
  final double? borderWidth;

  /// The width of the draggable button.
  final double buttonWidth;

  /// The height of the panel.
  final double? panelHeight;

  /// The height of the draggable button.
  final double buttonHeight;

  /// The border radius of the panel.
  final BorderRadius? borderRadius;

  /// The background color of the panel.
  final Color? backgroundColor;

  /// The list of items that will be displayed in the panel.
  final List<DraggablePanelItem> items;

  /// The list of buttons that will be displayed in the panel.
  final List<DraggablePanelButtonItem> buttons;

  /// The callback that will be called when the position of the panel is changed.
  /// You can use local storage to save the position of the panel and restore it
  /// when the widget is initialized in `initialPosition`.
  final void Function(double x, double y)? onPositionChanged;

  @override
  State<DraggablePanel> createState() => _DraggablePanelState();
}

class _DraggablePanelState extends State<DraggablePanel>
    with WidgetsBindingObserver {
  late DraggablePanelController _controller;
  PositionListener? _positionListener;
  bool _didInitLayout = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = widget.controller ?? DraggablePanelController();
    _controller.buttonWidth = widget.buttonWidth;

    // Propagate controller position changes to external callback if provided.
    _positionListener = (x, y) {
      if (!mounted) return;
      // Only forward when not dragging to avoid spamming during pan updates.
      if (!_controller.isDragging) {
        widget.onPositionChanged?.call(x, y);
      }
    };
    _controller.addPositionListener(_positionListener!);

    // Clamp into viewport after first frame (preserves state but prevents off-screen button).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didInitLayout) return;
      _clampIntoViewport();
      if (_controller.panelState == PanelState.closed) {
        final pageWidth = MediaQuery.sizeOf(context).width;
        _controller.isDragging = false;
        _controller
          ..forceDock(pageWidth)
          ..hidePanel(pageWidth);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitLayout) {
      _ensureInitialDock();
      _didInitLayout = true;
    }
  }

  @override
  void didUpdateWidget(covariant DraggablePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If external controller instance changed, rewire listeners safely.
    if (oldWidget.controller != widget.controller) {
      if (_positionListener != null) {
        _controller.removePositionListener(_positionListener!);
      }
      // If we owned the old controller (oldWidget.controller == null), we keep it;
      // otherwise, switch to the new external controller instance.
      if (widget.controller != null) {
        _controller = widget.controller!;
      }
      // Ensure width stays in sync when buttonWidth changes at runtime
      _controller.buttonWidth = widget.buttonWidth;
      if (_positionListener != null) {
        _controller.addPositionListener(_positionListener!);
      }
    } else if (oldWidget.buttonWidth != widget.buttonWidth) {
      // Keep controller's buttonWidth synchronized if only width changed.
      _controller.buttonWidth = widget.buttonWidth;
    }
  }

  @override
  void dispose() {
    if (_positionListener != null) {
      _controller.removePositionListener(_positionListener!);
      _positionListener = null;
    }
    if (widget.controller == null) {
      _controller.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Window size changed (desktop/web resize, rotation, etc.).
    // Re-clamp button into viewport and adjust panel position to the correct side.
    if (!mounted) return;
    // Debounce to the next frame (latest callback wins).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleWindowResize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pageWidth = MediaQuery.sizeOf(context).width;
    final pageHeight = MediaQuery.sizeOf(context).height;

    return AnimatedBuilder(
      key: const ValueKey('draggable_panel_builder'),
      animation: _controller,
      builder: (context, child) {
        // Animated positioned widget can be moved to any part of the screen with
        // animation;
        final isInRightSide = _controller.isDockedRight;
        return Stack(
          children: [
            if (widget.child != null) widget.child!,
            AnimatedPositioned(
              key: const ValueKey('draggable_panel_button'),
              duration: Duration(
                milliseconds: _controller.movementSpeed,
              ),
              top: _controller.draggablePositionTop,
              left: _controller.draggablePositionLeft,
              curve: Curves.fastLinearToSlowEaseIn,
              child: GestureDetector(
                onPanEnd: (event) {
                  _controller.isDragging = false;
                  _controller
                    ..forceDock(pageWidth)
                    ..hidePanel(pageWidth);
                },
                onPanStart: (event) {
                  // Detect the offset between the top and left side of the panel and
                  // x and y position of the touch(click) event;
                  _controller.panOffsetTop = event.globalPosition.dy -
                      _controller.draggablePositionTop;
                  _controller.panOffsetLeft = event.globalPosition.dx -
                      _controller.draggablePositionLeft;
                },
                onPanUpdate: (event) {
                  // Close Panel if opened;
                  _controller.panelState = PanelState.closed;

                  // Reset Movement Speed;
                  _controller.movementSpeed = 0;
                  _controller.isDragging = true;

                  // Calculate the top position of the panel according to pan;
                  final statusBarHeight = MediaQuery.paddingOf(context).top;
                  var newTop =
                      event.globalPosition.dy - _controller.panOffsetTop;

                  // Check if the top position is exceeding the status bar or dock boundaries;
                  final minTop = statusBarHeight + _controller.dockBoundary;
                  final maxTop = (pageHeight - widget.buttonHeight - 10) -
                      _controller.dockBoundary;
                  if (newTop < minTop) newTop = minTop;
                  if (newTop > maxTop) newTop = maxTop;

                  // Calculate the Left position of the panel according to pan;
                  var newLeft =
                      event.globalPosition.dx - _controller.panOffsetLeft;

                  // Check if the left position is exceeding the dock boundaries;
                  final minLeft = 0 + _controller.dockBoundary;
                  final maxLeft = (pageWidth - _controller.buttonWidth) -
                      _controller.dockBoundary;
                  if (newLeft < minLeft) newLeft = minLeft;
                  if (newLeft > maxLeft) newLeft = maxLeft;

                  // Apply batched position update to avoid extra rebuilds.
                  _controller.setPosition(x: newLeft, y: newTop);
                },
                onTap: () async {
                  await _controller.toggleMainButton(pageWidth);
                  _controller.togglePanel(pageWidth);
                },
                child: AnimatedContainer(
                  duration:
                      Duration(milliseconds: _controller.panelAnimDuration),
                  width: widget.buttonWidth,
                  height: widget.buttonHeight,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: (widget.backgroundColor ??
                            Theme.of(context).primaryColor)
                        .withValues(alpha: 0.4),
                    borderRadius: widget.borderRadius ??
                        const BorderRadius.all(Radius.circular(16)),
                    border: _panelBorder,
                  ),
                  curve: Curves.fastLinearToSlowEaseIn,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Gesture detector is required to detect the tap and drag on the panel;
                        Flexible(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                            child: _controller.isDragging
                                ? Center(
                                    child: SizedBox(
                                      width: _controller.buttonWidth,
                                      height: widget.buttonHeight,
                                      child: Icon(
                                        Icons.drag_indicator_rounded,
                                        color:
                                            Colors.white.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  )
                                : SizedBox(
                                    key: const ValueKey('drag_handle'),
                                    width: _controller.buttonWidth,
                                    height: widget.buttonHeight,
                                    child: widget.icon ??
                                        Align(
                                          alignment: isInRightSide
                                              ? Alignment.centerLeft
                                              : Alignment.centerRight,
                                          child: CustomPaint(
                                            willChange: true,
                                            size: const Size(20, 65),
                                            painter: LineWithCurvePainter(
                                              isInRightSide: isInRightSide,
                                              color: Colors.white
                                                  .withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              key: const ValueKey('draggable_panel'),
              duration: Duration(
                milliseconds: _controller.panelAnimDuration,
              ),
              top: _panelTopPosition(pageHeight),
              left: _controller.panelPositionLeft,
              curve: Curves.linearToEaseOut,
              child: TapRegion(
                onTapOutside: (event) {
                  if (_controller.panelState == PanelState.open) {
                    _controller.panelState = PanelState.closed;

                    // Reset panel position, dock it to nearest edge;
                    _controller
                      ..forceDock(pageWidth)
                      ..togglePanel(pageWidth);
                  }
                },
                child: AnimatedSwitcher(
                  duration:
                      Duration(milliseconds: _controller.panelAnimDuration),
                  transitionBuilder: (child, animation) => Transform.translate(
                    offset: Offset.zero,
                    child: child,
                  ),
                  child: _controller.panelState == PanelState.open
                      ? AnimatedContainer(
                          key: const ValueKey('panel_container'),
                          duration: Duration(
                            milliseconds: _controller.panelAnimDuration,
                          ),
                          width: _controller.panelWidth,
                          height: _panelHeight,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: widget.backgroundColor ??
                                Theme.of(context).primaryColor,
                            borderRadius: widget.borderRadius ??
                                const BorderRadius.all(Radius.circular(16)),
                            border: _panelBorder,
                          ),
                          curve: Curves.linearToEaseOut,
                          padding: const EdgeInsets.all(8),
                          child: Flex(
                            direction: Axis.vertical,
                            spacing: 8,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: (widget.buttons.isNotEmpty)
                                ? MainAxisAlignment.spaceBetween
                                : MainAxisAlignment.center,
                            children: [
                              Wrap(
                                runSpacing: 8,
                                spacing: 8,
                                children: List.generate(
                                  widget.items.length,
                                  (index) => Badge(
                                    isLabelVisible:
                                        widget.items[index].enableBadge,
                                    padding: EdgeInsets.zero,
                                    smallSize: 12,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            widget.items[index].onTap
                                                .call(context);

                                            _controller.panelState =
                                                PanelState.closed;
                                            _controller
                                              ..forceDock(pageWidth)
                                              ..hidePanel(pageWidth);
                                          },
                                          onLongPress:
                                              widget.items[index].description !=
                                                          null &&
                                                      widget
                                                          .items[index]
                                                          .description!
                                                          .isNotEmpty
                                                  ? () {
                                                      TooltipSnackBar.show(
                                                        context,
                                                        message: widget
                                                            .items[index]
                                                            .description!,
                                                        icon: widget
                                                            .items[index].icon,
                                                        backgroundColor: widget
                                                                .backgroundColor ??
                                                            Theme.of(context)
                                                                .primaryColor,
                                                      );
                                                    }
                                                  : null,
                                          child: Ink(
                                            color: _itemColor,
                                            child: Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Icon(
                                                widget.items[index].icon,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (widget.buttons.isNotEmpty)
                                Flexible(
                                  child: Wrap(
                                    runSpacing: 6,
                                    children: [
                                      ...widget.buttons.map(
                                        (button) => _PanelButton(
                                          itemColor: _itemColor,
                                          icon: button.icon,
                                          label: button.label,
                                          pageWidth: pageWidth,
                                          onTap: () {
                                            button.onTap.call(context);
                                          },
                                          onLongPress: button.description !=
                                                      null &&
                                                  button.description!.isNotEmpty
                                              ? () {
                                                  TooltipSnackBar.show(
                                                    context,
                                                    message:
                                                        button.description!,
                                                    icon: button.icon,
                                                    backgroundColor: widget
                                                            .backgroundColor ??
                                                        Theme.of(context)
                                                            .primaryColor,
                                                  );
                                                }
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        )
                      : const SizedBox(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // <-- Functions -->

  void _handleWindowResize() {
    final size = MediaQuery.sizeOf(context);
    final pageWidth = size.width;

    // Ensure the draggable button stays within the new viewport.
    _clampIntoViewport();

    // Auto-dock to nearest edge on resize to satisfy "перетягиваться в бока".
    _controller
      ..forceDock(pageWidth)
      ..movementSpeed = 0; // avoid long animations on resize

    if (_controller.panelState == PanelState.open) {
      // Keep the open panel aligned to its edge with new width.
      final isRight = _controller.isDockedRight;
      _controller.panelPositionLeft = isRight
          ? pageWidth - _controller.panelWidth - _controller.buttonWidth
          : _controller.buttonWidth;
    } else {
      // Keep hidden panel fully off-screen on the correct side.
      _controller.hidePanel(pageWidth);
    }

    // Panel's top is derived from button top via _panelTopPosition, which already
    // uses clamped draggablePositionTop; nothing else needed here.
  }

  void _ensureInitialDock() {
    // Ensure inside viewport first
    _clampIntoViewport();
    // If panel starts closed (default behavior), dock immediately without animation.
    if (_controller.panelState == PanelState.closed) {
      final pageWidth = MediaQuery.sizeOf(context).width;
      final isRight = _controller.draggablePositionLeft > pageWidth / 2;
      // Keep movement speed zero for first frame
      _controller.movementSpeed = 0;
      // Snap button to nearest edge
      final left = isRight
          ? (pageWidth - _controller.buttonWidth) - _controller.dockBoundary
          : 0.0 + _controller.dockBoundary;
      _controller
        ..setPosition(x: left, y: _controller.draggablePositionTop)
        ..recomputeDockSide(pageWidth)
        // Place panel off-screen on the corresponding side
        ..panelPositionLeft = isRight
            ? pageWidth + _controller.buttonWidth
            : -_controller.buttonWidth;
    }
  }

  void _clampIntoViewport() {
    final size = MediaQuery.sizeOf(context);
    final pageWidth = size.width;
    final pageHeight = size.height;
    final statusBarHeight = MediaQuery.paddingOf(context).top;

    var left = _controller.draggablePositionLeft;
    var top = _controller.draggablePositionTop;

    final minLeft = 0 + _controller.dockBoundary;
    final maxLeft =
        (pageWidth - _controller.buttonWidth) - _controller.dockBoundary;
    final minTop = statusBarHeight + _controller.dockBoundary;
    final maxTop =
        (pageHeight - widget.buttonHeight - 10) - _controller.dockBoundary;

    var changed = false;
    if (left < minLeft) {
      left = minLeft;
      changed = true;
    } else if (left > maxLeft) {
      left = maxLeft;
      changed = true;
    }

    if (top < minTop) {
      top = minTop;
      changed = true;
    } else if (top > maxTop) {
      top = maxTop;
      changed = true;
    }

    if (changed) {
      // Update both at once to avoid extra rebuilds.
      _controller.setPosition(x: left, y: top);
    }
  }

  double _panelTopPosition(double pageHeight) {
    final panelHeight = _panelHeight;
    final buttonTop = _controller.draggablePositionTop;
    final buttonBottom = buttonTop + widget.buttonHeight;
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final safeTop = viewPadding.top;
    final safeBottom = viewPadding.bottom;
    final minTop = safeTop;
    final rawMaxTop = pageHeight - safeBottom - panelHeight;
    final maxTop = rawMaxTop < minTop ? minTop : rawMaxTop;
    final aboveSpace = buttonTop - safeTop;
    final belowSpace = (pageHeight - safeBottom) - buttonBottom;
    double desiredTop;

    if (belowSpace >= panelHeight) {
      desiredTop = buttonBottom;
    } else if (aboveSpace >= panelHeight) {
      desiredTop = buttonTop - panelHeight;
    } else if (aboveSpace > belowSpace) {
      desiredTop = minTop;
    } else {
      desiredTop = maxTop;
    }

    if (minTop == maxTop) {
      return minTop;
    }
    if (desiredTop < minTop) {
      return minTop;
    }
    if (desiredTop > maxTop) {
      return maxTop;
    }

    return desiredTop;
  }

  // Dock boundary is provided via controller.dockBoundary
  // Height of the panel according to its state;
  double get _panelHeight {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final safeTop = viewPadding.top;
    final safeBottom = viewPadding.bottom;
    const minHeight = 60.0;
    final availableHeight = viewportHeight - safeTop - safeBottom;
    final maxHeight = availableHeight < minHeight ? minHeight : availableHeight;

    if (widget.panelHeight != null) {
      final requestedHeight = widget.panelHeight!;
      if (requestedHeight < minHeight) {
        return minHeight;
      }
      return requestedHeight > maxHeight ? maxHeight : requestedHeight;
    }

    final buttonsHeight =
        widget.buttons.isNotEmpty ? widget.buttons.length * 50.0 + 8.0 : 0.0;
    final itemsHeight = (widget.items.length / 4).ceil() * 45.0;
    final totalHeight = itemsHeight + buttonsHeight + 16.0;

    if (totalHeight < minHeight) {
      return minHeight;
    }
    return totalHeight > maxHeight ? maxHeight : totalHeight;
  }

  // (_calculateRowCount(widget.items.length) * 45) +
  // ((widget.buttons.isNotEmpty) ? (50 * (widget.buttons.length) + 0) : 60);

  // Panel border is only enabled if the border width is greater than 0;
  Border? get _panelBorder {
    if ((widget.borderWidth != null && widget.borderWidth! > 0) ||
        widget.borderColor != null) {
      return Border.fromBorderSide(
        BorderSide(
          color: widget.borderColor ?? const Color(0xFF333333),
          width: widget.borderWidth ?? 1,
        ),
      );
    } else {
      return null;
    }
  }

  Color get _itemColor => !(Theme.of(context).brightness == Brightness.dark)
      ? adjustColorBrightness(
          Theme.of(context).colorScheme.primary,
          0.8,
        )
      : adjustColorBrightness(
          Theme.of(context).colorScheme.primaryContainer,
          0.9,
        );
}
