import 'package:flutter/widgets.dart';

/// The grab affordance shown on the sliver of a panel parked at a screen edge.
///
/// It is the only part of a parked panel the user can see, so it has to read as
/// something to pull. The curve leans the way the panel comes out.
@immutable
final class PanelEdgeHandle extends StatelessWidget {
  const PanelEdgeHandle({
    required this.color,
    this.pointsTowardStart = true,
    this.curveSize = const Size(20, 65),
    this.strokeWidth = 5,
    super.key,
  });

  final Color color;

  /// Whether the curve leans towards the start edge — set when the panel is
  /// parked against the end edge and comes out that way.
  final bool pointsTowardStart;

  /// The box the curve is drawn in, centred within the handle.
  ///
  /// Fixed rather than proportional: the curve's two ends line up only at this
  /// width, and stretching it to the handle skews one end past the other.
  final Size curveSize;

  final double strokeWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: CustomPaint(
      size: curveSize,
      painter: _EdgeCurvePainter(
        color: color,
        pointsTowardStart: pointsTowardStart,
        strokeWidth: strokeWidth,
      ),
    ),
  );
}

/// Draws a single shallow curve bowing towards the direction of travel.
final class _EdgeCurvePainter extends CustomPainter {
  const _EdgeCurvePainter({
    required this.color,
    required this.pointsTowardStart,
    required this.strokeWidth,
  });

  final Color color;
  final bool pointsTowardStart;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final startX = pointsTowardStart ? size.width - 7.0 : 7.0;
    final controlX = size.width / 2;
    final endX = controlX + (pointsTowardStart ? 3 : -3);

    canvas.drawPath(
      Path()
        ..moveTo(startX, 14)
        ..quadraticBezierTo(controlX, size.height / 2, endX, size.height - 14),
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_EdgeCurvePainter old) =>
      old.color != color ||
      old.pointsTowardStart != pointsTowardStart ||
      old.strokeWidth != strokeWidth;
}
