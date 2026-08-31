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
  /// The curve keeps its proportions inside whatever box it is given, so a
  /// retuned size rescales it rather than leaving its ends where the default
  /// box put them.
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
///
/// The geometry is expressed as fractions of the box it is handed, written as
/// the design's own measurements over the default `handleSize` of 20x65. A
/// retuned `handleSize` therefore rescales the curve instead of leaving its
/// endpoints where a 65-tall box put them — which on a shorter box would put
/// the far end above the near one.
final class _EdgeCurvePainter extends CustomPainter {
  const _EdgeCurvePainter({
    required this.color,
    required this.pointsTowardStart,
    required this.strokeWidth,
  });

  static const _endInsetX = 7 / 20;
  static const _endInsetY = 14 / 65;
  static const _bow = 3 / 20;

  final Color color;
  final bool pointsTowardStart;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = size.width * _endInsetX;
    final bow = size.width * _bow;
    final top = size.height * _endInsetY;

    final startX = pointsTowardStart ? size.width - inset : inset;
    final controlX = size.width / 2;
    final endX = controlX + (pointsTowardStart ? bow : -bow);

    canvas.drawPath(
      Path()
        ..moveTo(startX, top)
        ..quadraticBezierTo(controlX, size.height / 2, endX, size.height - top),
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
