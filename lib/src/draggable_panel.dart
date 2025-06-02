// ignore_for_file: inference_failure_on_function_return_type, prefer_int_literals, unnecessary_parenthesis, prefer_underscore_for_unused_callback_parameters, unnecessary_lambdas

import 'package:draggable_panel/src/controller/controller.dart';
import 'package:draggable_panel/src/enums/dock_type.dart';
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
    super.key,
    required this.child,
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

class _DraggablePanelState extends State<DraggablePanel> {
  late DraggablePanelController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? DraggablePanelController();
    _controller.draggablePositionTop = _controller.initialPosition?.y ?? 200;
    _controller.draggablePositionLeft = _controller.initialPosition?.x ?? 0;
    _controller.buttonWidth = widget.buttonWidth;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.toggle(context);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
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
        final isInRightSide = _controller.draggablePositionLeft > pageWidth / 2;
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
                  _controller.forceDock(pageWidth);
                  _controller.hidePanel(pageWidth);
                  widget.onPositionChanged?.call(
                    _controller.draggablePositionLeft,
                    _controller.draggablePositionTop,
                  );
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

                  _controller.buttonWidth = widget.buttonWidth;

                  // Reset Movement Speed;
                  _controller.movementSpeed = 0;
                  _controller.isDragging = true;

                  // Calculate the top position of the panel according to pan;
                  final statusBarHeight = MediaQuery.paddingOf(context).top;
                  _controller.draggablePositionTop =
                      event.globalPosition.dy - _controller.panOffsetTop;

                  // Check if the top position is exceeding the status bar or dock boundaries;
                  if (_controller.draggablePositionTop <
                      statusBarHeight + _dockBoundary) {
                    _controller.draggablePositionTop =
                        statusBarHeight + _dockBoundary;
                  }
                  if (_controller.draggablePositionTop >
                      (pageHeight - widget.buttonHeight - 10) - _dockBoundary) {
                    _controller.draggablePositionTop =
                        (pageHeight - widget.buttonHeight - 10) - _dockBoundary;
                  }

                  // Calculate the Left position of the panel according to pan;
                  _controller.draggablePositionLeft =
                      event.globalPosition.dx - _controller.panOffsetLeft;

                  // Check if the left position is exceeding the dock boundaries;
                  if (_controller.draggablePositionLeft < 0 + _dockBoundary) {
                    _controller.draggablePositionLeft = 0 + _dockBoundary;
                  }
                  if (_controller.draggablePositionLeft >
                      (pageWidth - _controller.buttonWidth) - _dockBoundary) {
                    _controller.draggablePositionLeft =
                        (pageWidth - _controller.buttonWidth) - _dockBoundary;
                  }
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
                    _controller.forceDock(pageWidth);
                    _controller.togglePanel(pageWidth);
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
                              milliseconds: _controller.panelAnimDuration),
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
                                alignment: WrapAlignment.start,
                                children: List.generate(
                                  widget.items.length,
                                  (index) => Badge(
                                    isLabelVisible:
                                        widget.items[index].enableBadge,
                                    padding: EdgeInsets.zero,
                                    smallSize: 12,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.all(
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
                                            _controller.forceDock(pageWidth);
                                            _controller.hidePanel(pageWidth);
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

  double _panelTopPosition(double pageHeight) {
    if (_controller.draggablePositionTop < 0) {
      return 0;
    } else if (_controller.draggablePositionTop > pageHeight - _panelHeight) {
      return _controller.draggablePositionTop - _panelHeight;
    } else {
      return _controller.draggablePositionTop + widget.buttonHeight;
    }
  }

  double get _dockBoundary {
    if (_controller.dockType != null &&
        _controller.dockType == DockType.inside) {
      // If it's an 'inside' type dock, dock offset will remain the same;
      return -_controller.dockOffset;
    } else {
      // If it's an 'outside' type dock, dock offset will be inverted, hence
      // negative value;
      return _controller.dockOffset;
    }
  }

// Height of the panel according to its state;
  double get _panelHeight {
    if (widget.panelHeight != null) {
      return widget.panelHeight!;
    }

    // Calculate the height based on the number of rows for `items`.
    final itemsHeight = (widget.items.length / 4).ceil() * 45.0;

    // Calculate the height for buttons, if present.
    final buttonsHeight = widget.buttons.isNotEmpty
        ? widget.buttons.length * 50.0 + 8.0 // Adding a small margin.
        : 0.0;

    // Calculate the total height of the panel.
    final totalHeight =
        itemsHeight + buttonsHeight + 16.0; // 16 for inner padding.

    // Restrict the height to minimum and maximum values.
    return totalHeight.clamp(100.0, 600.0);
  }

  // (_calculateRowCount(widget.items.length) * 45) +
  // ((widget.buttons.isNotEmpty) ? (50 * (widget.buttons.length) + 0) : 60);

  // Panel border is only enabled if the border width is greater than 0;
  Border? get _panelBorder {
    if (widget.borderWidth != null && widget.borderWidth! > 0 ||
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
