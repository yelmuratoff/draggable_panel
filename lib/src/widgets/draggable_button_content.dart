part of '../draggable_panel.dart';

class _DraggableButtonContent extends StatelessWidget {
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
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: isDragging
                  ? Center(
                      child: SizedBox(
                        width: buttonWidth,
                        height: buttonHeight,
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : SizedBox(
                      key: const ValueKey('drag_handle'),
                      width: buttonWidth,
                      height: buttonHeight,
                      child: icon ??
                          Align(
                            alignment: isDockedRight
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: CustomPaint(
                              size: const Size(20, 65),
                              painter: LineWithCurvePainter(
                                isInRightSide: isDockedRight,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                    ),
            ),
          ),
        ],
      );
}
