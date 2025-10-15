part of '../draggable_panel.dart';

final class _DraggableButtonContent extends StatelessWidget {
  const _DraggableButtonContent({
    required this.isDragging,
    required this.isDockedRight,
    required this.buttonWidth,
    required this.buttonHeight,
    this.icon,
  });

  final bool isDragging;
  final bool isDockedRight;
  final Widget? icon;
  final double buttonWidth;
  final double buttonHeight;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: child,
        ),
        child: isDragging
            ? _DraggingIndicator(
                key: const ValueKey('dragging'),
                buttonWidth: buttonWidth,
                buttonHeight: buttonHeight,
              )
            : _DragHandle(
                key: const ValueKey('drag_handle'),
                icon: icon,
                isDockedRight: isDockedRight,
                buttonWidth: buttonWidth,
                buttonHeight: buttonHeight,
              ),
      );
}

final class _DraggingIndicator extends StatelessWidget {
  const _DraggingIndicator({
    required this.buttonWidth,
    required this.buttonHeight,
    super.key,
  });

  final double buttonWidth;
  final double buttonHeight;

  @override
  Widget build(BuildContext context) => Center(
        child: SizedBox(
          width: buttonWidth,
          height: buttonHeight,
          child: Icon(
            Icons.drag_indicator_rounded,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      );
}

final class _DragHandle extends StatelessWidget {
  const _DragHandle({
    required this.isDockedRight,
    required this.buttonWidth,
    required this.buttonHeight,
    this.icon,
    super.key,
  });

  final bool isDockedRight;
  final Widget? icon;
  final double buttonWidth;
  final double buttonHeight;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: buttonWidth,
        height: buttonHeight,
        child: icon ??
            Align(
              alignment:
                  isDockedRight ? Alignment.centerLeft : Alignment.centerRight,
              child: CustomPaint(
                size: const Size(20, 65),
                painter: LineWithCurvePainter(
                  isInRightSide: isDockedRight,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
      );
}
