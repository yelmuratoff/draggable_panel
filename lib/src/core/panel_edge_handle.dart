import 'package:flutter/widgets.dart';

/// The grab affordance shown on the sliver of a panel parked at a screen edge.
///
/// It is the only part of a parked panel the user can see, so it has to read as
/// something to pull. The curve points the way the panel comes out.
@immutable
final class PanelEdgeHandle extends StatelessWidget {
  const PanelEdgeHandle({
    required this.color,
    this.pointsTowardStart = true,
    this.strokeWidth = 5,
    super.key,
  });

  final Color color;

  /// Whether the curve's apex points towards the start edge — set when the
  /// panel is parked against the end edge and comes out that way.
  final bool pointsTowardStart;

  final double strokeWidth;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _EdgeCurvePainter(
      color: color,
      pointsTowardStart: pointsTowardStart,
      strokeWidth: strokeWidth,
    ),
  );
}

/// Draws a single quadratic curve bowing towards the direction of travel.
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
    if (size.isEmpty) return;

    final centreX = size.width / 2;
    final baseX = pointsTowardStart ? size.width - 7 : 7.0;
    final tipX = centreX + (pointsTowardStart ? 3 : -3);
    final capY = size.height * 0.2;

    canvas.drawPath(
      Path()
        ..moveTo(baseX, capY)
        ..quadraticBezierTo(centreX, size.height / 2, tipX, size.height - capY),
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_EdgeCurvePainter old) =>
      old.color != color ||
      old.pointsTowardStart != pointsTowardStart ||
      old.strokeWidth != strokeWidth;
}
