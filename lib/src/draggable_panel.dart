import 'package:draggable_panel/src/controller/controller.dart';
import 'package:draggable_panel/src/enums/panel_state.dart';
import 'package:draggable_panel/src/models/panel_button.dart';
import 'package:draggable_panel/src/models/panel_item.dart';
import 'package:draggable_panel/src/utils/colors.dart';
import 'package:draggable_panel/src/widgets/curve_line_paint.dart';
import 'package:draggable_panel/src/widgets/tooltip_snackbar.dart';
import 'package:flutter/material.dart';

part 'widgets/panel_button.dart';
part 'widgets/draggable_button_content.dart';

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
  late final PositionListener _positionListener;
  bool _didInitLayout = false;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsController = widget.controller == null;
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
    _controller.addPositionListener(_positionListener);

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
      _controller.removePositionListener(_positionListener);
      if (_ownsController &&
          oldWidget.controller == null &&
          widget.controller != null) {
        _controller.dispose();
      }
      if (widget.controller != null) {
        _controller = widget.controller!;
        _ownsController = false;
      } else {
        _ownsController = true;
      }
      // Ensure width stays in sync when buttonWidth changes at runtime
      _controller.buttonWidth = widget.buttonWidth;
      _controller.addPositionListener(_positionListener);
    } else if (oldWidget.buttonWidth != widget.buttonWidth) {
      // Keep controller's buttonWidth synchronized if only width changed.
      _controller.buttonWidth = widget.buttonWidth;
    }
  }

  @override
  void dispose() {
    _controller.removePositionListener(_positionListener);
    if (_ownsController) {
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
    final pageSize = MediaQuery.sizeOf(context);
    final pageWidth = pageSize.width;
    final pageHeight = pageSize.height;

    return AnimatedBuilder(
      key: const ValueKey('draggable_panel_builder'),
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final isDockedRight = _controller.isDockedRight;
        return Stack(
          children: [
            if (child != null) child,
            _buildDraggableButton(
              context: context,
              pageWidth: pageWidth,
              pageHeight: pageHeight,
              isDockedRight: isDockedRight,
            ),
            _buildPanel(
              context: context,
              pageWidth: pageWidth,
              pageHeight: pageHeight,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDraggableButton({
    required BuildContext context,
    required double pageWidth,
    required double pageHeight,
    required bool isDockedRight,
  }) {
    final buttonDuration = Duration(milliseconds: _controller.movementSpeed);
    final resolvedBorderRadius =
        widget.borderRadius ?? const BorderRadius.all(Radius.circular(16));
    final resolvedBackground =
        (widget.backgroundColor ?? Theme.of(context).primaryColor)
            .withValues(alpha: 0.4);
    final buttonWidth = _controller.buttonWidth;
    final buttonHeight = widget.buttonHeight;
    final isDragging = _controller.isDragging;

    return AnimatedPositioned(
      key: const ValueKey('draggable_panel_button'),
      duration: buttonDuration,
      top: _controller.draggablePositionTop,
      left: _controller.draggablePositionLeft,
      curve: Curves.fastLinearToSlowEaseIn,
      child: GestureDetector(
        onPanEnd: (_) => _handlePanEnd(pageWidth),
        onPanStart: _handlePanStart,
        onPanUpdate: (details) => _handlePanUpdate(
          context: context,
          details: details,
          pageWidth: pageWidth,
          pageHeight: pageHeight,
        ),
        onTap: () async {
          await _controller.toggleMainButton(pageWidth);
          _controller.togglePanel(pageWidth);
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: _controller.panelAnimDuration),
          width: buttonWidth,
          height: buttonHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: resolvedBackground,
            borderRadius: resolvedBorderRadius,
            border: _panelBorder,
          ),
          curve: Curves.fastLinearToSlowEaseIn,
          child: Center(
            child: _DraggableButtonContent(
              isDragging: isDragging,
              isDockedRight: isDockedRight,
              icon: widget.icon,
              buttonWidth: buttonWidth,
              buttonHeight: buttonHeight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel({
    required BuildContext context,
    required double pageWidth,
    required double pageHeight,
  }) {
    final panelDuration = Duration(milliseconds: _controller.panelAnimDuration);
    final isPanelOpen = _controller.panelState == PanelState.open;
    final resolvedBackgroundColor =
        widget.backgroundColor ?? Theme.of(context).primaryColor;
    final resolvedBorderRadius =
        widget.borderRadius ?? const BorderRadius.all(Radius.circular(16));

    return AnimatedPositioned(
      key: const ValueKey('draggable_panel'),
      duration: panelDuration,
      top: _panelTopPosition(pageHeight),
      left: _controller.panelPositionLeft,
      curve: Curves.linearToEaseOut,
      child: TapRegion(
        onTapOutside: (_) {
          if (isPanelOpen) {
            _closePanelAndDock(pageWidth);
          }
        },
        child: AnimatedSwitcher(
          duration: panelDuration,
          transitionBuilder: (child, animation) => Transform.translate(
            offset: Offset.zero,
            child: child,
          ),
          child: isPanelOpen
              ? AnimatedContainer(
                  key: const ValueKey('panel_container'),
                  duration: panelDuration,
                  width: _controller.panelWidth,
                  height: _panelHeight,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: resolvedBackgroundColor,
                    borderRadius: resolvedBorderRadius,
                    border: _panelBorder,
                  ),
                  curve: Curves.linearToEaseOut,
                  padding: const EdgeInsets.all(8),
                  child: _PanelContents(
                    items: widget.items,
                    buttons: widget.buttons,
                    itemColor: _itemColor,
                    onItemTap: (item) {
                      item.onTap(context);
                      _closePanelAndDock(pageWidth);
                    },
                    onItemLongPress: (item) {
                      TooltipSnackBar.show(
                        context,
                        message: item.description!,
                        icon: item.icon,
                        backgroundColor: resolvedBackgroundColor,
                      );
                    },
                    onButtonTap: (button) {
                      button.onTap(context);
                    },
                    onButtonLongPress: (button) {
                      TooltipSnackBar.show(
                        context,
                        message: button.description!,
                        icon: button.icon,
                        backgroundColor: resolvedBackgroundColor,
                      );
                    },
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  // <-- Functions -->

  void _closePanelAndDock(double pageWidth) {
    _controller.panelState = PanelState.closed;
    _controller
      ..forceDock(pageWidth)
      ..hidePanel(pageWidth);
  }

  void _handlePanStart(DragStartDetails details) {
    _controller
      ..panOffsetTop =
          details.globalPosition.dy - _controller.draggablePositionTop
      ..panOffsetLeft =
          details.globalPosition.dx - _controller.draggablePositionLeft;
  }

  void _handlePanEnd(double pageWidth) {
    _controller.isDragging = false;
    _closePanelAndDock(pageWidth);
  }

  void _handlePanUpdate({
    required BuildContext context,
    required DragUpdateDetails details,
    required double pageWidth,
    required double pageHeight,
  }) {
    _controller
      ..panelState = PanelState.closed
      ..movementSpeed = 0
      ..isDragging = true;

    final viewPadding = MediaQuery.paddingOf(context);
    final dockBoundary = _controller.dockBoundary;
    final minTop = viewPadding.top + dockBoundary;
    final maxTop = (pageHeight - widget.buttonHeight - 10) - dockBoundary;
    final minLeft = dockBoundary;
    final maxLeft = (pageWidth - _controller.buttonWidth) - dockBoundary;
    final globalPosition = details.globalPosition;

    final newTop =
        (globalPosition.dy - _controller.panOffsetTop).clamp(minTop, maxTop);
    final newLeft =
        (globalPosition.dx - _controller.panOffsetLeft).clamp(minLeft, maxLeft);

    _controller.setPosition(x: newLeft, y: newTop);
  }

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
    final statusBarHeight = MediaQuery.paddingOf(context).top;

    final minLeft = 0 + _controller.dockBoundary;
    final maxLeft =
        (size.width - _controller.buttonWidth) - _controller.dockBoundary;
    final minTop = statusBarHeight + _controller.dockBoundary;
    final maxTop =
        (size.height - widget.buttonHeight - 10) - _controller.dockBoundary;

    final clampedLeft =
        _controller.draggablePositionLeft.clamp(minLeft, maxLeft);
    final clampedTop = _controller.draggablePositionTop.clamp(minTop, maxTop);

    if (_controller.draggablePositionLeft != clampedLeft ||
        _controller.draggablePositionTop != clampedTop) {
      _controller.setPosition(x: clampedLeft, y: clampedTop);
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

    if (minTop == maxTop) return minTop;

    final aboveSpace = buttonTop - safeTop;
    final belowSpace = (pageHeight - safeBottom) - buttonBottom;

    final desiredTop = belowSpace >= panelHeight
        ? buttonBottom
        : aboveSpace >= panelHeight
            ? buttonTop - panelHeight
            : aboveSpace > belowSpace
                ? minTop
                : maxTop;

    return desiredTop.clamp(minTop, maxTop);
  }

  double get _panelHeight {
    const minHeight = 60.0;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final availableHeight =
        viewportHeight - viewPadding.top - viewPadding.bottom;
    final maxHeight = availableHeight < minHeight ? minHeight : availableHeight;

    if (widget.panelHeight != null) {
      return widget.panelHeight!.clamp(minHeight, maxHeight);
    }

    final buttonsHeight =
        widget.buttons.isNotEmpty ? widget.buttons.length * 50.0 + 8.0 : 0.0;
    final itemsHeight = (widget.items.length / 4).ceil() * 45.0;
    final totalHeight = itemsHeight + buttonsHeight + 16.0;

    return totalHeight.clamp(minHeight, maxHeight);
  }

  Border? get _panelBorder {
    final width = widget.borderWidth;
    final color = widget.borderColor;

    if ((width != null && width > 0) || color != null) {
      return Border.fromBorderSide(
        BorderSide(
          color: color ?? const Color(0xFF333333),
          width: width ?? 1,
        ),
      );
    }
    return null;
  }

  Color get _itemColor => Theme.of(context).brightness == Brightness.dark
      ? adjustColorBrightness(
          Theme.of(context).colorScheme.primaryContainer,
          0.9,
        )
      : adjustColorBrightness(
          Theme.of(context).colorScheme.primary,
          0.8,
        );
}

class _PanelContents extends StatelessWidget {
  const _PanelContents({
    required this.items,
    required this.buttons,
    required this.itemColor,
    required this.onItemTap,
    required this.onItemLongPress,
    required this.onButtonTap,
    required this.onButtonLongPress,
  });

  final List<DraggablePanelItem> items;
  final List<DraggablePanelButtonItem> buttons;
  final Color itemColor;
  final ValueChanged<DraggablePanelItem> onItemTap;
  final ValueChanged<DraggablePanelItem> onItemLongPress;
  final ValueChanged<DraggablePanelButtonItem> onButtonTap;
  final ValueChanged<DraggablePanelButtonItem> onButtonLongPress;

  @override
  Widget build(BuildContext context) {
    final hasButtons = buttons.isNotEmpty;

    return Column(
      mainAxisAlignment: hasButtons
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          runSpacing: 8,
          spacing: 8,
          children: [
            for (final item in items)
              _PanelItemBadge(
                item: item,
                itemColor: itemColor,
                onPressed: () => onItemTap(item),
                onLongPress: item.description?.isNotEmpty ?? false
                    ? () => onItemLongPress(item)
                    : null,
              ),
          ],
        ),
        if (hasButtons) const SizedBox(height: 8),
        if (hasButtons)
          Flexible(
            child: Wrap(
              runSpacing: 6,
              children: [
                for (final button in buttons)
                  _PanelButton(
                    itemColor: itemColor,
                    icon: button.icon,
                    label: button.label,
                    onTap: () => onButtonTap(button),
                    onLongPress: button.description?.isNotEmpty ?? false
                        ? () => onButtonLongPress(button)
                        : null,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PanelItemBadge extends StatelessWidget {
  const _PanelItemBadge({
    required this.item,
    required this.itemColor,
    required this.onPressed,
    this.onLongPress,
  });

  final DraggablePanelItem item;
  final Color itemColor;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) => Badge(
        isLabelVisible: item.enableBadge,
        padding: EdgeInsets.zero,
        smallSize: 12,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              onLongPress: onLongPress,
              child: Ink(
                color: itemColor,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    item.icon,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
