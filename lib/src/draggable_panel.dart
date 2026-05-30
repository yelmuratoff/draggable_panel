import 'package:draggable_panel/src/builders.dart';
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
    this.itemBuilder,
    this.buttonBuilder,
    this.handleBuilder,
    this.itemFrameBuilder,
    this.buttonFrameBuilder,
    this.onShowTooltip,
    this.panelBuilder,
    this.panelContentBuilder,
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

  /// Builds custom content for each item, replacing the default icon. The cell,
  /// tap/long-press handling, and badge are still provided by the panel.
  final DraggablePanelItemBuilder? itemBuilder;

  /// Builds custom content for each action button, replacing the default icon +
  /// label row. The button shape and tap/long-press handling are kept.
  final DraggablePanelButtonBuilder? buttonBuilder;

  /// Builds the entire draggable button content, replacing the default handle.
  final DraggablePanelHandleBuilder? handleBuilder;

  /// Builds the entire item cell (shell + content), replacing the default
  /// badge/ink-well frame. Takes precedence over [itemBuilder] for the shell;
  /// [itemBuilder]'s result is still passed in as the cell content.
  final DraggablePanelItemFrameBuilder? itemFrameBuilder;

  /// Builds the entire action button (shell + content), replacing the default
  /// [FilledButton] frame. [buttonBuilder]'s result is passed in as the content.
  final DraggablePanelButtonFrameBuilder? buttonFrameBuilder;

  /// Presents the long-press tooltip. When null, a built-in SnackBar is shown.
  final DraggablePanelTooltipPresenter? onShowTooltip;

  /// Builds the visible panel surface (the decorated sheet), replacing the
  /// default container. Slide/dock positioning, fade, and tap-to-close are
  /// kept; the builder receives the contents plus the resolved size and color.
  final DraggablePanelSurfaceBuilder? panelBuilder;

  /// Builds the panel content layout, replacing the default `Wrap` + `Column`.
  /// Use the provided `buildItem`/`buildButton` helpers to keep interactions.
  final DraggablePanelContentBuilder? panelContentBuilder;

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
    _controller
      ..buttonWidth = widget.theme.draggableButtonWidth
      ..panelWidth = widget.theme.panelWidth;

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

      _controller
        ..buttonWidth = widget.theme.draggableButtonWidth
        ..panelWidth = widget.theme.panelWidth
        ..addPositionListener(_positionListener);
    } else if (oldWidget.theme != widget.theme) {
      _controller
        ..buttonWidth = widget.theme.draggableButtonWidth
        ..panelWidth = widget.theme.panelWidth;
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
    final motion = widget.theme.motion;
    final buttonDuration =
        _controller.animateMovement ? motion.buttonMoveDuration : Duration.zero;
    final buttonWidth = _controller.buttonWidth;
    final buttonHeight = widget.theme.draggableButtonHeight;
    final isDraggable = _controller.draggable;

    return AnimatedPositioned(
      key: const ValueKey('draggable_panel_button'),
      duration: buttonDuration,
      top: _controller.draggablePositionTop,
      left: _controller.draggablePositionLeft,
      curve: motion.buttonMoveCurve,
      child: GestureDetector(
        onPanEnd: isDraggable ? (_) => _handlePanEnd(pageWidth) : null,
        onPanStart: isDraggable ? _handlePanStart : null,
        onPanUpdate: isDraggable
            ? (details) => _handlePanUpdate(
                  context: context,
                  details: details,
                  pageWidth: pageWidth,
                  pageHeight: pageHeight,
                )
            : null,
        onTap: _controller.tapToToggle
            ? () => _controller
              ..toggleMainButton(pageWidth)
              ..togglePanel(pageWidth)
            : null,
        child: AnimatedContainer(
          duration: motion.buttonMoveDuration,
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
          curve: motion.buttonMoveCurve,
          child: Center(
            child: widget.handleBuilder?.call(
                  context,
                  isDragging: _controller.isDragging,
                  isDockedRight: isDockedRight,
                ) ??
                DraggableButtonContentWidget(
                  isDragging: _controller.isDragging,
                  isDockedRight: isDockedRight,
                  icon: widget.icon,
                  buttonWidth: buttonWidth,
                  buttonHeight: buttonHeight,
                  foregroundColor: widget.theme.foregroundColor,
                  handleTheme: widget.theme.effectiveHandleTheme,
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
    final motion = widget.theme.motion;
    final isPanelOpen = _controller.panelState == PanelState.open;
    final panelColor =
        widget.theme.panelBackgroundColor ?? _defaultPanelColor(context);
    final placement = _panelPlacement(pageHeight);

    return AnimatedPositioned(
      key: const ValueKey('draggable_panel'),
      duration: motion.panelMoveDuration,
      top: placement.top,
      bottom: placement.bottom,
      left: placement.left,
      right: placement.right,
      curve: motion.panelMoveCurve,
      child: TapRegion(
        onTapOutside: (_) {
          if (isPanelOpen && _controller.closeOnTapOutside) {
            _closePanelAndDock(pageWidth);
          }
        },
        child: AnimatedSwitcher(
          duration: motion.panelSwitchDuration,
          switchInCurve: motion.panelSwitchInCurve,
          switchOutCurve: motion.panelSwitchOutCurve,
          transitionBuilder: (child, animation) => Transform.translate(
            offset: Offset.zero,
            child: child,
          ),
          child: isPanelOpen
              ? KeyedSubtree(
                  key: const ValueKey('panel_container'),
                  child: _buildPanelSurface(
                    context,
                    panelColor,
                    pageWidth,
                    placement.width,
                    placement.maxHeight,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildPanelSurface(
    BuildContext context,
    Color panelColor,
    double pageWidth,
    double width,
    double maxHeight,
  ) {
    final motion = widget.theme.motion;
    final content = _buildPanelContents(context, panelColor, pageWidth);

    final panelBuilder = widget.panelBuilder;
    if (panelBuilder != null) {
      return panelBuilder(
        context,
        DraggablePanelSurface(
          content: content,
          width: width,
          maxHeight: maxHeight,
          color: panelColor,
          theme: widget.theme,
          isOpen: true,
        ),
      );
    }

    final fixedHeight = widget.panelHeight?.clamp(0.0, maxHeight);
    final sizedContent = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: fixedHeight ?? 0.0,
        maxHeight: fixedHeight ?? maxHeight,
      ),
      child: Padding(
        padding: widget.theme.panelContentPadding,
        child: content,
      ),
    );

    return AnimatedContainer(
      duration: motion.panelMoveDuration,
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: widget.theme.panelBorderRadius,
        border: widget.theme.panelBorder,
        boxShadow: widget.theme.panelBoxShadow,
      ),
      curve: motion.panelMoveCurve,
      child: AnimatedSize(
        duration: motion.panelMoveDuration,
        curve: motion.panelMoveCurve,
        alignment: Alignment.topCenter,
        child: sizedContent,
      ),
    );
  }

  Widget _buildPanelContents(
    BuildContext context,
    Color panelColor,
    double pageWidth,
  ) =>
      PanelContentsWidget(
        theme: widget.theme,
        items: widget.items,
        buttons: widget.buttons,
        itemBuilder: widget.itemBuilder,
        buttonBuilder: widget.buttonBuilder,
        itemFrameBuilder: widget.itemFrameBuilder,
        buttonFrameBuilder: widget.buttonFrameBuilder,
        contentBuilder: widget.panelContentBuilder,
        itemColor: _itemColor,
        itemForegroundColor: _itemForegroundColor,
        onItemTap: (item) {
          item.onTap(context);
          _closePanelAndDock(pageWidth);
        },
        onItemLongPress: (item) => _showItemTooltip(context, item, panelColor),
        onButtonTap: (button) => button.onTap(context),
        onButtonLongPress: (button) =>
            _showButtonTooltip(context, button, panelColor),
      );

  void _showItemTooltip(
    BuildContext context,
    DraggablePanelItem item,
    Color panelColor,
  ) {
    if (item.description?.isNotEmpty ?? false) {
      _presentTooltip(
        context,
        message: item.description!,
        icon: item.icon,
        panelColor: panelColor,
      );
    }
  }

  void _showButtonTooltip(
    BuildContext context,
    DraggablePanelButtonItem button,
    Color panelColor,
  ) {
    if (button.description?.isNotEmpty ?? false) {
      _presentTooltip(
        context,
        message: button.description!,
        icon: button.icon,
        panelColor: panelColor,
      );
    }
  }

  void _presentTooltip(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color panelColor,
  }) {
    final data = DraggablePanelTooltipData(
      message: message,
      icon: icon,
      backgroundColor: panelColor,
      iconColor: _itemForegroundColor,
      iconBackgroundColor: _itemColor,
      tooltipTheme: widget.theme.effectiveTooltipTheme,
    );

    final presenter = widget.onShowTooltip;
    if (presenter != null) {
      presenter(context, data);
      return;
    }

    TooltipSnackBar.show(
      context,
      message: data.message,
      icon: data.icon,
      backgroundColor: data.backgroundColor,
      iconColor: data.iconColor,
      iconBackgroundColor: data.iconBackgroundColor,
      tooltipTheme: data.tooltipTheme,
    );
  }

  // <-- Helper Properties -->

  Color _defaultBackgroundColor(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;

  Color _defaultPanelColor(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainer;

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
      ..animateMovement = false
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
    final pageWidth = MediaQuery.sizeOf(context).width;
    // When open, the button sits off-screen on purpose; clamping it would pull
    // it back into view for a frame. relayout re-places everything instead.
    if (_controller.panelState == PanelState.closed) {
      _clampIntoViewport();
    }
    _controller.relayout(pageWidth);
  }

  void _ensureInitialDock() {
    _clampIntoViewport();

    if (_controller.panelState == PanelState.closed) {
      final pageWidth = MediaQuery.sizeOf(context).width;
      final isRight = _controller.draggablePositionLeft > pageWidth / 2;

      _controller.animateMovement = false;

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

  /// Chooses which side of the button the panel opens on and how much height it
  /// may use, without forcing a fixed panel height.
  ///
  /// The panel sizes itself to its content (capped at [maxHeight], scrolling
  /// beyond it), so the estimate is only used to prefer the more natural side.
  /// Above placement anchors via `bottom` so the height never has to be known.
  ({
    double? left,
    double? right,
    double? top,
    double? bottom,
    double width,
    double maxHeight,
  }) _panelPlacement(double pageHeight) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final buttonTop = _controller.draggablePositionTop;
    final buttonBottom = buttonTop + widget.theme.draggableButtonHeight;
    final topLimit = viewPadding.top;
    final bottomLimit = pageHeight - viewPadding.bottom;

    final aboveSpace = (buttonTop - topLimit).clamp(0.0, double.infinity);
    final belowSpace = (bottomLimit - buttonBottom).clamp(0.0, double.infinity);

    final desired = _estimatedContentHeight;
    final fitsBelow = desired <= belowSpace;
    final fitsAbove = desired <= aboveSpace;
    final useBelow = fitsBelow || (!fitsAbove && belowSpace >= aboveSpace);

    final double? top;
    final double? bottom;
    final double maxHeight;
    if (useBelow) {
      top = buttonBottom;
      bottom = null;
      maxHeight = belowSpace;
    } else {
      top = null;
      bottom = pageHeight - buttonTop;
      maxHeight = aboveSpace;
    }

    // Horizontal: the panel hugs its content width (see _resolvedContentWidth)
    // and anchors to the button's inner edge so it sits flush against it (no
    // gap), no matter how narrow the content is. Off-screen on the dock side
    // when closed.
    final border = widget.theme.panelBorder;
    final borderH =
        border is Border ? border.left.width + border.right.width : 0.0;
    final width = _resolvedContentWidth() + borderH;
    final buttonWidth = _controller.buttonWidth;
    final isOpen = _controller.panelState == PanelState.open;

    double? left;
    double? right;
    if (_controller.isDockedRight) {
      right = isOpen ? buttonWidth : -width;
    } else {
      left = isOpen ? buttonWidth : -width;
    }

    return (
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      width: width,
      maxHeight: maxHeight,
    );
  }

  /// Rough content-height estimate used only to pick the open side. The actual
  /// panel sizes to its content, so this never has to be exact (and tolerates
  /// custom item/button/content builders).
  double get _estimatedContentHeight {
    if (widget.panelHeight != null) return widget.panelHeight!;

    final theme = widget.theme;
    final buttonTheme = theme.effectiveButtonTheme;
    final itemTheme = theme.effectiveItemTheme;
    final padding = theme.panelContentPadding;

    final singleButtonHeight = buttonTheme.height + theme.buttonSpacing;
    final buttonsHeight = widget.buttons.isNotEmpty
        ? widget.buttons.length * singleButtonHeight + theme.sectionSpacing
        : 0.0;

    final itemSize = itemTheme.padding.vertical + itemTheme.iconSize;
    final spacing = theme.itemSpacing;
    final itemCount = widget.items.length;
    final columns = _gridColumns();
    final rows = columns == 0 ? 0 : (itemCount / columns).ceil();
    final itemsHeight = rows * itemSize + (rows - 1).clamp(0, rows) * spacing;

    return itemsHeight + buttonsHeight + padding.vertical;
  }

  /// Number of item columns, balanced so the last row isn't left half-empty.
  ///
  /// Fits as many fixed-size cells as the panel width allows, then redistributes
  /// the items evenly across the resulting number of rows.
  int _gridColumns() {
    final itemCount = widget.items.length;
    if (itemCount == 0) return 0;

    final theme = widget.theme;
    final itemTheme = theme.effectiveItemTheme;
    final padding = theme.panelContentPadding;
    final spacing = theme.itemSpacing;
    final itemExtent = itemTheme.padding.horizontal + itemTheme.iconSize;
    final available = _controller.panelWidth - padding.horizontal;

    final maxColumns = ((available + spacing) / (itemExtent + spacing))
        .floor()
        .clamp(1, itemCount);
    final rows = (itemCount / maxColumns).ceil();
    return (itemCount / rows).ceil();
  }

  /// Width the panel hugs to. A uniform item grid shrinks to its balanced
  /// column count; panels with action buttons, a custom content builder, or no
  /// items use the full [DraggablePanelTheme.panelWidth].
  double _resolvedContentWidth() {
    final maxWidth = _controller.panelWidth;
    if (widget.panelContentBuilder != null ||
        widget.buttons.isNotEmpty ||
        widget.items.isEmpty) {
      return maxWidth;
    }

    final theme = widget.theme;
    final itemTheme = theme.effectiveItemTheme;
    final padding = theme.panelContentPadding;
    final spacing = theme.itemSpacing;
    final itemExtent = itemTheme.padding.horizontal + itemTheme.iconSize;
    final columns = _gridColumns();
    final contentWidth = columns * itemExtent + (columns - 1) * spacing;

    return (contentWidth + padding.horizontal).clamp(0.0, maxWidth);
  }

  Color get _itemColor =>
      widget.theme.panelItemColor ??
      (Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : adjustColorBrightness(
              Theme.of(context).colorScheme.primary,
              0.8,
            ));

  Color get _itemForegroundColor =>
      widget.theme.foregroundColor ??
      (Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.onSurface
          : Theme.of(context).colorScheme.onPrimary);
}
