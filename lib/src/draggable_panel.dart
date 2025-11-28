import 'package:draggable_panel/src/controller/controller.dart';
import 'package:draggable_panel/src/enums/panel_state.dart';
import 'package:draggable_panel/src/models/panel_button.dart';
import 'package:draggable_panel/src/models/panel_item.dart';
import 'package:draggable_panel/src/theme/theme.dart';
import 'package:draggable_panel/src/utils/colors.dart';
import 'package:draggable_panel/src/widgets/draggable_button_content_widget.dart';
import 'package:draggable_panel/src/widgets/panel_contents_widget.dart';
import 'package:draggable_panel/src/widgets/tooltip_snackbar.dart';
import 'package:flutter/material.dart';

/// `DraggablePanel` is a widget that can be dragged around the screen and can be
/// docked to the nearest edge of the screen. It can be used to create a floating
/// panel that can be used to show additional information or actions.
///
/// - Parameters:
///   - child: The child widget that will be used as the main content of the screen
///   - icon: The icon in the draggable button (optional, works with dockType)
///   - items: The list of items that will be displayed in the panel
///   - buttons: The list of buttons that will be displayed in the panel
///   - controller: Optional controller to manage panel state
///   - onPositionChanged: Callback when position changes (useful for persistence)
///   - panelHeight: Optional fixed height for the panel
///   - theme: The theme of the panel (default: DraggablePanelTheme())
/// - Usage example:
///   ```dart
///   DraggablePanel(
///     items: [
///       DraggablePanelItem(
///         icon: Icons.settings,
///         enableBadge: false,
///         onTap: (context) => Navigator.push(...),
///       ),
///     ],
///     buttons: [
///       DraggablePanelButtonItem(
///         icon: Icons.share,
///         label: 'Share',
///         onTap: (context) => share(),
///       ),
///     ],
///     child: YourMainContent(),
///   )
///   ```
@immutable
final class DraggablePanel extends StatefulWidget {
  const DraggablePanel({
    required this.child,
    super.key,
    this.icon,
    this.items = const [],
    this.buttons = const [],
    this.controller,
    this.onPositionChanged,
    this.panelHeight,
    this.theme = const DraggablePanelTheme(),
  });

  final DraggablePanelController? controller;

  /// The child widget that will be used as the main content of the screen.
  final Widget? child;

  /// The icon in the draggable button that will be used to drag the panel around
  /// the screen.
  ///
  /// I recommend use it with `dockType` option.
  final Widget? icon;

  /// The height of the panel.
  final double? panelHeight;

  /// The list of items that will be displayed in the panel.
  final List<DraggablePanelItem> items;

  /// The list of buttons that will be displayed in the panel.
  final List<DraggablePanelButtonItem> buttons;

  /// The theme of the panel.
  final DraggablePanelTheme theme;

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
    _controller.buttonWidth = widget.theme.draggableButtonWidth;

    _positionListener = (x, y) {
      if (!mounted || _controller.isDragging) return;
      widget.onPositionChanged?.call(x, y);
    };
    _controller.addPositionListener(_positionListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didInitLayout) return;
      _clampIntoViewport();
      if (_controller.panelState == PanelState.closed) {
        final pageWidth = MediaQuery.sizeOf(context).width;
        _controller
          ..isDragging = false
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

      _controller.buttonWidth = widget.theme.draggableButtonWidth;
      _controller.addPositionListener(_positionListener);
    } else if (oldWidget.theme.draggableButtonWidth !=
        widget.theme.draggableButtonWidth) {
      _controller.buttonWidth = widget.theme.draggableButtonWidth;
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
    if (!mounted) return;

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
    final buttonWidth = _controller.buttonWidth;
    final buttonHeight = widget.theme.draggableButtonHeight;

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
            color: widget.theme.draggableButtonColor ??
                _defaultBackgroundColor(context),
            borderRadius: widget.theme.panelBorderRadius,
            border: widget.theme.panelBorder,
            boxShadow: widget.theme.panelBoxShadow,
          ),
          curve: Curves.fastLinearToSlowEaseIn,
          child: Center(
            child: DraggableButtonContentWidget(
              isDragging: _controller.isDragging,
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
    final panelColor =
        widget.theme.panelBackgroundColor ?? _defaultPanelColor(context);

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
                    color: panelColor,
                    borderRadius: widget.theme.panelBorderRadius,
                    border: widget.theme.panelBorder,
                    boxShadow: widget.theme.panelBoxShadow,
                  ),
                  curve: Curves.linearToEaseOut,
                  padding: const EdgeInsets.all(8),
                  child: PanelContentsWidget(
                    theme: widget.theme,
                    items: widget.items,
                    buttons: widget.buttons,
                    itemColor: _itemColor,
                    onItemTap: (item) {
                      item.onTap(context);
                      _closePanelAndDock(pageWidth);
                    },
                    onItemLongPress: (item) => _showItemTooltip(
                      context,
                      item,
                      panelColor,
                    ),
                    onButtonTap: (button) => button.onTap(context),
                    onButtonLongPress: (button) => _showButtonTooltip(
                      context,
                      button,
                      panelColor,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  void _showItemTooltip(
    BuildContext context,
    DraggablePanelItem item,
    Color panelColor,
  ) {
    if (item.description?.isNotEmpty ?? false) {
      TooltipSnackBar.show(
        context,
        message: item.description!,
        icon: item.icon,
        backgroundColor: panelColor,
      );
    }
  }

  void _showButtonTooltip(
    BuildContext context,
    DraggablePanelButtonItem button,
    Color panelColor,
  ) {
    if (button.description?.isNotEmpty ?? false) {
      TooltipSnackBar.show(
        context,
        message: button.description!,
        icon: button.icon,
        backgroundColor: panelColor,
      );
    }
  }

  // <-- Helper Properties -->

  Color _defaultBackgroundColor(BuildContext context) =>
      Theme.of(context).colorScheme.primary.withValues(alpha: 0.4);

  Color _defaultPanelColor(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

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
    final buttonHeight = widget.theme.draggableButtonHeight;
    final buttonWidth = _controller.buttonWidth;

    final minTop = viewPadding.top + dockBoundary;
    final maxTop = (pageHeight - buttonHeight - 10) - dockBoundary;
    final minLeft = dockBoundary;
    final maxLeft = (pageWidth - buttonWidth) - dockBoundary;
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

    _clampIntoViewport();

    _controller
      ..forceDock(pageWidth)
      ..movementSpeed = 0;

    if (_controller.panelState == PanelState.open) {
      final isRight = _controller.isDockedRight;
      _controller.panelPositionLeft = isRight
          ? pageWidth - _controller.panelWidth - _controller.buttonWidth
          : _controller.buttonWidth;
    } else {
      _controller.hidePanel(pageWidth);
    }
  }

  void _ensureInitialDock() {
    _clampIntoViewport();

    if (_controller.panelState == PanelState.closed) {
      final pageWidth = MediaQuery.sizeOf(context).width;
      final isRight = _controller.draggablePositionLeft > pageWidth / 2;

      _controller.movementSpeed = 0;

      final left = isRight
          ? (pageWidth - _controller.buttonWidth) - _controller.dockBoundary
          : _controller.dockBoundary;

      _controller
        ..setPosition(x: left, y: _controller.draggablePositionTop)
        ..recomputeDockSide(pageWidth)
        ..panelPositionLeft = isRight
            ? pageWidth + _controller.buttonWidth
            : -_controller.buttonWidth;
    }
  }

  void _clampIntoViewport() {
    final size = MediaQuery.sizeOf(context);
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final dockBoundary = _controller.dockBoundary;
    final buttonWidth = _controller.buttonWidth;
    final buttonHeight = widget.theme.draggableButtonHeight;

    final minLeft = dockBoundary;
    final maxLeft = (size.width - buttonWidth) - dockBoundary;
    final minTop = statusBarHeight + dockBoundary;
    final maxTop = (size.height - buttonHeight - 10) - dockBoundary;

    final clampedLeft =
        _controller.draggablePositionLeft.clamp(minLeft, maxLeft);
    final clampedTop = _controller.draggablePositionTop.clamp(minTop, maxTop);

    final needsUpdate = _controller.draggablePositionLeft != clampedLeft ||
        _controller.draggablePositionTop != clampedTop;

    if (needsUpdate) {
      _controller.setPosition(x: clampedLeft, y: clampedTop);
    }
  }

  double _panelTopPosition(double pageHeight) {
    final panelHeight = _panelHeight;
    final buttonTop = _controller.draggablePositionTop;
    final buttonBottom = buttonTop + widget.theme.draggableButtonHeight;
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final minTop = viewPadding.top;
    final rawMaxTop = pageHeight - viewPadding.bottom - panelHeight;
    final maxTop = rawMaxTop < minTop ? minTop : rawMaxTop;

    if (minTop == maxTop) return minTop;

    final aboveSpace = buttonTop - viewPadding.top;
    final belowSpace = (pageHeight - viewPadding.bottom) - buttonBottom;

    final shouldPlaceBelow = belowSpace >= panelHeight;
    final shouldPlaceAbove = !shouldPlaceBelow && aboveSpace >= panelHeight;

    final desiredTop = shouldPlaceBelow
        ? buttonBottom
        : shouldPlaceAbove
            ? buttonTop - panelHeight
            : (aboveSpace > belowSpace ? minTop : maxTop);

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

  Color get _itemColor =>
      widget.theme.panelItemColor ??
      (Theme.of(context).brightness == Brightness.dark
          ? adjustColorBrightness(
              Theme.of(context).colorScheme.primaryContainer,
              0.9,
            )
          : adjustColorBrightness(
              Theme.of(context).colorScheme.primary,
              0.8,
            ));
}
