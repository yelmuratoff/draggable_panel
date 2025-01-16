// ignore_for_file: inference_failure_on_function_return_type, prefer_int_literals, unnecessary_parenthesis, prefer_underscore_for_unused_callback_parameters, unnecessary_lambdas

import 'package:draggable_panel/src/enums/dock_type.dart';
import 'package:draggable_panel/src/enums/panel_state.dart';
import 'package:draggable_panel/src/utils/colors.dart';
import 'package:draggable_panel/src/widgets/curve_line_paint.dart';
import 'package:draggable_panel/src/widgets/multi_value_listenable.dart';
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
    this.initialPanelState,
    this.panelAnimDuration = 600,
    this.dockType = DockType.inside,
    this.dockOffset = 10.0,
    this.dockAnimDuration = 300,
    this.initialPosition,
    this.onPositionChanged,
    this.panelHeight,
  });

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

  /// The initial state of the panel.
  /// `PanelState.open` will open the panel when the widget is initialized.
  /// `PanelState.closed` will close the panel when the widget is initialized.
  final PanelState? initialPanelState;

  /// The duration of the panel animation when it's opened or closed.
  final int panelAnimDuration;

  /// The type of the dock.
  /// `DockType.inside` it will be located a little further from the edge of the screen.
  /// `DockType.outside` it will be located a little closer to the middle of the screen.
  final DockType? dockType;

  /// The offset of the dock.
  /// Default value is `10.0`.
  final double dockOffset;

  /// The duration of the dock animation.
  final int? dockAnimDuration;

  /// The list of items that will be displayed in the panel.
  final List<
      ({
        IconData icon,
        bool enableBadge,
        void Function(BuildContext context) onTap,
      })> items;

  /// The list of buttons that will be displayed in the panel.
  final List<
      ({
        IconData icon,
        String label,
        void Function(BuildContext context) onTap,
      })> buttons;

  /// The initial position of the panel.
  final ({double x, double y})? initialPosition;

  /// The callback that will be called when the position of the panel is changed.
  /// You can use local storage to save the position of the panel and restore it
  /// when the widget is initialized in `initialPosition`.
  final void Function(double x, double y)? onPositionChanged;

  @override
  State<DraggablePanel> createState() => _DraggablePanelState();
}

class _DraggablePanelState extends State<DraggablePanel> {
  // <-- Notifiers -->

// Required to set the default state to closed when the widget gets initialized;
  final ValueNotifier<PanelState> _panelState = ValueNotifier(PanelState.closed);

// Default positions for the panel;
  final ValueNotifier<double> _draggablePositionTop = ValueNotifier(0.0);
  final ValueNotifier<double> _draggablePositionLeft = ValueNotifier(0.0);
  final ValueNotifier<double> _panelPositionLeft = ValueNotifier(0.0);

  // ** PanOffset ** is used to calculate the distance from the edge of the panel
  // to the cursor, to calculate the position when being dragged;

  final ValueNotifier<double> _panOffsetTop = ValueNotifier(0.0);
  final ValueNotifier<double> _panOffsetLeft = ValueNotifier(0.0);

  // This is the animation duration for the panel movement, it's required to
  // dynamically change the speed depending on what the panel is being used for.
  // e.g: When panel opened or closed, the position should change in a different
  // speed than when the panel is being dragged;

  final ValueNotifier<int> _movementSpeed = ValueNotifier(0);

  final ValueNotifier<bool> _isDragging = ValueNotifier(false);

  final ValueNotifier<double> _buttonWidth = ValueNotifier(0.0);

  static const double _panelWidth = 200;

  @override
  void initState() {
    super.initState();
    _draggablePositionTop.value = widget.initialPosition?.y ?? 200;
    _draggablePositionLeft.value = widget.initialPosition?.x ?? 0;
    _buttonWidth.value = widget.buttonWidth;

    _toggle();
  }

  @override
  void didChangeDependencies() {
    _toggle();
    _isDragging.value = false;
    _panelState.value = PanelState.closed;
    super.didChangeDependencies();
  }

  void _toggle() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialPanelState == PanelState.open) {
        _toggleMainButton(MediaQuery.sizeOf(context).width);
        _togglePanel(MediaQuery.sizeOf(context).width);
      } else {
        _forceDock(MediaQuery.sizeOf(context).width);
        _hidePanel(MediaQuery.sizeOf(context).width);
      }
    });
  }

  @override
  void dispose() {
    _panelState.dispose();
    _draggablePositionTop.dispose();
    _draggablePositionLeft.dispose();
    _panOffsetTop.dispose();
    _panOffsetLeft.dispose();
    _movementSpeed.dispose();
    _isDragging.dispose();
    _buttonWidth.dispose();
    _panelPositionLeft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Width and height of page is required for the dragging the panel;
    final pageWidth = MediaQuery.sizeOf(context).width;
    final pageHeight = MediaQuery.sizeOf(context).height;

    return MultiValueListenableBuilder(
      key: const ValueKey('draggable_panel_builder'),
      valueListenables: [
        _panelState,
        _draggablePositionTop,
        _draggablePositionLeft,
        _panelPositionLeft,
        _movementSpeed,
        _isDragging,
        _buttonWidth,
        _panOffsetTop,
        _panOffsetLeft,
      ],
      builder: (context) {
        // Animated positioned widget can be moved to any part of the screen with
        // animation;
        final isInRightSide = _draggablePositionLeft.value > pageWidth / 2;
        return Stack(
          children: [
            if (widget.child != null) widget.child!,
            AnimatedPositioned(
              key: const ValueKey('draggable_panel_button'),
              duration: Duration(
                milliseconds: _movementSpeed.value,
              ),
              top: _draggablePositionTop.value,
              left: _draggablePositionLeft.value,
              curve: Curves.fastLinearToSlowEaseIn,
              child: GestureDetector(
                onPanEnd: (event) {
                  _isDragging.value = false;
                  _forceDock(pageWidth);
                  _hidePanel(pageWidth);
                  widget.onPositionChanged?.call(
                    _draggablePositionLeft.value,
                    _draggablePositionTop.value,
                  );
                },
                onPanStart: (event) {
                  // Detect the offset between the top and left side of the panel and
                  // x and y position of the touch(click) event;
                  _panOffsetTop.value = event.globalPosition.dy - _draggablePositionTop.value;
                  _panOffsetLeft.value = event.globalPosition.dx - _draggablePositionLeft.value;
                },
                onPanUpdate: (event) {
                  // Close Panel if opened;
                  _panelState.value = PanelState.closed;

                  _buttonWidth.value = widget.buttonWidth;

                  // Reset Movement Speed;
                  _movementSpeed.value = 0;
                  _isDragging.value = true;

                  // Calculate the top position of the panel according to pan;
                  final statusBarHeight = MediaQuery.paddingOf(context).top;
                  _draggablePositionTop.value = event.globalPosition.dy - _panOffsetTop.value;

                  // Check if the top position is exceeding the status bar or dock boundaries;
                  if (_draggablePositionTop.value < statusBarHeight + _dockBoundary) {
                    _draggablePositionTop.value = statusBarHeight + _dockBoundary;
                  }
                  if (_draggablePositionTop.value > (pageHeight - widget.buttonHeight - 10) - _dockBoundary) {
                    _draggablePositionTop.value = (pageHeight - widget.buttonHeight - 10) - _dockBoundary;
                  }

                  // Calculate the Left position of the panel according to pan;
                  _draggablePositionLeft.value = event.globalPosition.dx - _panOffsetLeft.value;

                  // Check if the left position is exceeding the dock boundaries;
                  if (_draggablePositionLeft.value < 0 + _dockBoundary) {
                    _draggablePositionLeft.value = 0 + _dockBoundary;
                  }
                  if (_draggablePositionLeft.value > (pageWidth - _buttonWidth.value) - _dockBoundary) {
                    _draggablePositionLeft.value = (pageWidth - _buttonWidth.value) - _dockBoundary;
                  }
                },
                onTap: () async {
                  await _toggleMainButton(pageWidth);
                  _togglePanel(pageWidth);
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: widget.panelAnimDuration),
                  width: widget.buttonWidth,
                  height: widget.buttonHeight,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: (widget.backgroundColor ?? Theme.of(context).primaryColor).withValues(alpha: 0.4),
                    borderRadius: widget.borderRadius ?? const BorderRadius.all(Radius.circular(16)),
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
                          child: _panelState.value == PanelState.open
                              ? const SizedBox()
                              : AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (child, animation) => ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                                  child: _isDragging.value
                                      ? Center(
                                          child: SizedBox(
                                            width: _buttonWidth.value,
                                            height: widget.buttonHeight,
                                            child: Icon(
                                              Icons.drag_indicator_rounded,
                                              color: Colors.white.withValues(alpha: 0.5),
                                            ),
                                          ),
                                        )
                                      : SizedBox(
                                          key: const ValueKey('drag_handle'),
                                          width: _buttonWidth.value,
                                          height: widget.buttonHeight,
                                          child: widget.icon ??
                                              Align(
                                                alignment: isInRightSide ? Alignment.centerLeft : Alignment.centerRight,
                                                child: CustomPaint(
                                                  willChange: true,
                                                  size: const Size(20, 65),
                                                  painter: LineWithCurvePainter(
                                                    isInRightSide: isInRightSide,
                                                    color: Colors.white.withValues(alpha: 0.5),
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
                milliseconds: widget.panelAnimDuration,
              ),
              top: _panelTopPosition(pageHeight),
              left: _panelPositionLeft.value,
              curve: Curves.linearToEaseOut,
              child: TapRegion(
                onTapOutside: (event) {
                  if (_panelState.value == PanelState.open) {
                    _panelState.value = PanelState.closed;

                    // Reset panel position, dock it to nearest edge;
                    _forceDock(pageWidth);
                    _togglePanel(pageWidth);
                  }
                },
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: widget.panelAnimDuration),
                  transitionBuilder: (child, animation) => Transform.translate(
                    offset: Offset.zero,
                    child: child,
                  ),
                  child: _panelState.value == PanelState.open
                      ? AnimatedContainer(
                          key: const ValueKey('panel_container'),
                          duration: Duration(milliseconds: widget.panelAnimDuration),
                          width: _panelWidth,
                          height: _panelHeight,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: widget.backgroundColor ?? Theme.of(context).primaryColor,
                            borderRadius: widget.borderRadius ?? const BorderRadius.all(Radius.circular(16)),
                            border: _panelBorder,
                          ),
                          curve: Curves.linearToEaseOut,
                          padding: const EdgeInsets.all(8),
                          child: Flex(
                            direction: Axis.vertical,
                            spacing: 8,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment:
                                (widget.buttons.isNotEmpty) ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
                            children: [
                              Wrap(
                                runSpacing: 8,
                                spacing: 8,
                                alignment: WrapAlignment.start,
                                children: List.generate(
                                  widget.items.length,
                                  (index) => Badge(
                                    isLabelVisible: widget.items[index].enableBadge,
                                    padding: EdgeInsets.zero,
                                    smallSize: 12,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
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
                                          onTap: () {
                                            widget.items[index].onTap.call(context);

                                            _panelState.value = PanelState.closed;
                                            _forceDock(pageWidth);
                                            _hidePanel(pageWidth);
                                          },
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
    if (_draggablePositionTop.value < 0) {
      return 0;
    } else if (_draggablePositionTop.value > pageHeight - _panelHeight) {
      return _draggablePositionTop.value - _panelHeight;
    } else {
      return _draggablePositionTop.value + widget.buttonHeight;
    }
  }

  void _hidePanel(double pageWidth) {
    if (_draggablePositionLeft.value > pageWidth / 2) {
      _panelPositionLeft.value = pageWidth + _panelWidth;
    } else {
      _panelPositionLeft.value = -_panelWidth;
    }
  }

  void _togglePanel(double pageWidth) {
    if (_panelState.value == PanelState.open) {
      if (_draggablePositionLeft.value > pageWidth / 2) {
        _panelPositionLeft.value = pageWidth - _panelWidth - widget.buttonWidth;
      } else {
        _panelPositionLeft.value = widget.buttonWidth;
      }
    } else {
      if (_draggablePositionLeft.value > pageWidth / 2) {
        _panelPositionLeft.value = pageWidth;
      } else {
        _panelPositionLeft.value = -_panelWidth;
      }
    }
  }

  Future<void> _toggleMainButton(double pageWidth) async {
    if (_panelState.value == PanelState.open) {
      // If panel state is "open", set it to "closed";
      _panelState.value = PanelState.closed;

      // Reset panel position, dock it to nearest edge;
      _forceDock(pageWidth);
    } else {
      // If panel state is "closed", set it to "open";
      _panelState.value = PanelState.open;

      if (_draggablePositionLeft.value > pageWidth / 2) {
        _draggablePositionLeft.value = pageWidth + _buttonWidth.value;
      } else {
        _draggablePositionLeft.value = -_buttonWidth.value;
      }
    }
  }

  double get _dockBoundary {
    if (widget.dockType != null && widget.dockType == DockType.inside) {
      // If it's an 'inside' type dock, dock offset will remain the same;
      return -widget.dockOffset;
    } else {
      // If it's an 'outside' type dock, dock offset will be inverted, hence
      // negative value;
      return widget.dockOffset;
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
    final totalHeight = itemsHeight + buttonsHeight + 16.0; // 16 for inner padding.

    // Restrict the height to minimum and maximum values.
    return totalHeight.clamp(100.0, 600.0);
  }

  // (_calculateRowCount(widget.items.length) * 45) +
  // ((widget.buttons.isNotEmpty) ? (50 * (widget.buttons.length) + 0) : 60);

  // Panel border is only enabled if the border width is greater than 0;
  Border? get _panelBorder {
    if (widget.borderWidth != null && widget.borderWidth! > 0 || widget.borderColor != null) {
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

  // Force dock will dock the panel to it's nearest edge of the screen;
  void _forceDock(double pageWidth) {
    // Calculate the center of the panel;
    final center = _draggablePositionLeft.value + (_buttonWidth.value / 2);

    // Set movement speed to the custom duration property or '300' default;
    _movementSpeed.value = widget.dockAnimDuration ?? 300;

    _buttonWidth.value = widget.buttonWidth;

    // Check if the position of center of the panel is less than half of the
    // page;
    if (center < pageWidth / 2) {
      // Dock to the left edge;
      _draggablePositionLeft.value = 0.0 + _dockBoundary;
      _panelPositionLeft.value = -_buttonWidth.value;
    } else {
      // Dock to the right edge;
      _draggablePositionLeft.value = (pageWidth - _buttonWidth.value) - _dockBoundary;
      _panelPositionLeft.value = pageWidth + _buttonWidth.value;
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
