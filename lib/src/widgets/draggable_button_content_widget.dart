import 'package:draggable_panel/src/theme/draggable_panel_handle_theme_data.dart';
import 'package:draggable_panel/src/widgets/curve_line_paint.dart';
import 'package:flutter/material.dart';

/// Internal widget for the draggable button's visual content.
///
/// Switches between a drag indicator (when dragging) and a handle (when docked).
@immutable
final class DraggableButtonContentWidget extends StatelessWidget {
  const DraggableButtonContentWidget({
    required this.isDragging,
    required this.isDockedRight,
    required this.buttonWidth,
    required this.buttonHeight,
    required this.handleTheme,
    this.icon,
    this.foregroundColor,
    super.key,
  });

  final bool isDragging;
  final bool isDockedRight;
  final Widget? icon;
  final double buttonWidth;
  final double buttonHeight;
  final Color? foregroundColor;
  final DraggablePanelHandleThemeData handleTheme;

  @override
  Widget build(BuildContext context) {
    final color = foregroundColor ??
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);

    return AnimatedSwitcher(
      duration: handleTheme.animationDuration,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: child,
      ),
      child: isDragging
          ? _DraggingIndicator(
              key: const ValueKey('dragging'),
              buttonWidth: buttonWidth,
              buttonHeight: buttonHeight,
              color: color,
            )
          : _DragHandle(
              key: const ValueKey('drag_handle'),
              icon: icon,
              isDockedRight: isDockedRight,
              buttonWidth: buttonWidth,
              buttonHeight: buttonHeight,
              color: color,
              curveLineSize: handleTheme.curveLineSize,
              curveStrokeWidth: handleTheme.curveStrokeWidth,
            ),
    );
  }
}

@immutable
final class _DraggingIndicator extends StatelessWidget {
  const _DraggingIndicator({
    required this.buttonWidth,
    required this.buttonHeight,
    required this.color,
    super.key,
  });

  final double buttonWidth;
  final double buttonHeight;
  final Color color;

  @override
  Widget build(BuildContext context) => Center(
        child: SizedBox(
          width: buttonWidth,
          height: buttonHeight,
          child: Icon(
            Icons.drag_indicator_rounded,
            color: color,
          ),
        ),
      );
}

@immutable
final class _DragHandle extends StatelessWidget {
  const _DragHandle({
    required this.isDockedRight,
    required this.buttonWidth,
    required this.buttonHeight,
    required this.color,
    required this.curveLineSize,
    required this.curveStrokeWidth,
    this.icon,
    super.key,
  });

  final bool isDockedRight;
  final Widget? icon;
  final double buttonWidth;
  final double buttonHeight;
  final Color color;
  final Size curveLineSize;
  final double curveStrokeWidth;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: buttonWidth,
        height: buttonHeight,
        child: icon ??
            Align(
              alignment:
                  isDockedRight ? Alignment.centerLeft : Alignment.centerRight,
              child: CustomPaint(
                size: curveLineSize,
                painter: LineWithCurvePainter(
                  isInRightSide: isDockedRight,
                  color: color,
                  strokeWidth: curveStrokeWidth,
                ),
              ),
            ),
      );
}
