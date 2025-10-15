import 'package:flutter/material.dart';

/// Custom painter that draws a curved line indicator for the draggable button.
///
/// This painter creates a curved line that indicates the draggable direction
/// based on which side of the screen the button is docked.
///
/// - Parameters:
///   - isInRightSide: Whether the button is docked on the right side
///   - color: The color of the curved line
/// - Usage example:
///   ```dart
///   CustomPaint(
///     size: Size(20, 65),
///     painter: LineWithCurvePainter(
///       isInRightSide: true,
///       color: Colors.white.withValues(alpha: 0.5),
///     ),
///   )
///   ```
final class LineWithCurvePainter extends CustomPainter {
  /// Creates a curved line painter.
  const LineWithCurvePainter({
    required this.isInRightSide,
    required this.color,
  });

  /// Whether the button is docked on the right side of the screen.
  final bool isInRightSide;

  /// The color of the curved line.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startX = isInRightSide ? size.width - 7.0 : 7.0;
    final controlPointX = size.width / 2;
    final endX = size.width / 2 + (isInRightSide ? 3 : -3);

    final path = Path()
      ..moveTo(startX, 14)
      ..quadraticBezierTo(
        controlPointX,
        size.height / 2,
        endX,
        size.height - 14,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LineWithCurvePainter oldDelegate) =>
      oldDelegate.isInRightSide != isInRightSide || oldDelegate.color != color;
}
