import 'dart:math' as math;
import 'dart:ui';

/// `UIScrollView.DecelerationRate.normal`.
const double kPanelNormalDecelerationRate = 0.998;

/// `UIScrollView.DecelerationRate.fast`, for snappier, paging-like settles.
const double kPanelFastDecelerationRate = 0.99;

/// The resistance constant `UIScrollView` uses when dragged past its bounds.
const double kPanelRubberBandCoefficient = 0.55;

/// The gesture mathematics behind the panel's feel.
///
/// Every function here is pure and framework-free, so the whole interaction
/// model can be tuned and tested without building a widget.
abstract final class PanelPhysics {
  /// Where momentum would carry [position] if it decelerated at [rate].
  ///
  /// From Apple's "Designing Fluid Interfaces" (WWDC 2018, session 803). Snap
  /// targets are chosen against this projected point rather than the release
  /// point, which is what makes a flick land where the user aimed instead of
  /// where their finger happened to leave the glass.
  static double project(double position, double velocity, double rate) =>
      position + (velocity / 1000) * rate / (1 - rate);

  /// [project] applied to both axes.
  static Offset projectOffset(Offset position, Offset velocity, double rate) =>
      Offset(
        project(position.dx, velocity.dx, rate),
        project(position.dy, velocity.dy, rate),
      );

  /// How far past a boundary something dragged [overshoot] beyond it appears.
  ///
  /// `b(x) = (x·d·c) / (d + c·x)`, the curve `UIScrollView` uses. It asymptotes
  /// at [dimension], so the panel can never be dragged more than one viewport
  /// clear of its bounds however hard it is pulled.
  static double rubberBand(
    double overshoot,
    double dimension, {
    double coefficient = kPanelRubberBandCoefficient,
  }) {
    if (overshoot == 0 || dimension <= 0) return 0;
    final distance = overshoot.abs();
    return overshoot.sign *
        (distance * dimension * coefficient) /
        (dimension + coefficient * distance);
  }

  /// The derivative of [rubberBand] at [overshoot].
  ///
  /// This is the ratio between how fast the surface moves and how fast the
  /// finger moves while outside the bounds. A settle must start from the
  /// surface's velocity rather than the finger's, or the hand-off from drag to
  /// spring shows a visible jump in speed.
  static double rubberBandSlope(
    double overshoot,
    double dimension, {
    double coefficient = kPanelRubberBandCoefficient,
  }) {
    if (dimension <= 0) return 1;
    final denominator = dimension + coefficient * overshoot.abs();
    return (dimension * dimension * coefficient) / (denominator * denominator);
  }

  /// Maps an unclamped drag position onto the position actually rendered.
  ///
  /// Inside [travel] this is the identity, so the panel tracks the finger
  /// exactly. Outside it, [rubberBand] applies resistance on that axis.
  /// [viewport] supplies the asymptote for each axis.
  ///
  /// An inverted [travel] — the panel is larger than its bounds on that axis —
  /// resolves to the centre of the range rather than to a meaningless edge.
  static Offset resist(
    Offset raw,
    Rect travel,
    Size viewport, {
    double coefficient = kPanelRubberBandCoefficient,
  }) => Offset(
    _resistAxis(raw.dx, travel.left, travel.right, viewport.width, coefficient),
    _resistAxis(
      raw.dy,
      travel.top,
      travel.bottom,
      viewport.height,
      coefficient,
    ),
  );

  /// How far [raw] lies outside [travel] on each axis, signed, zero inside.
  static Offset overshootOf(Offset raw, Rect travel) => Offset(
    _overshootAxis(raw.dx, travel.left, travel.right),
    _overshootAxis(raw.dy, travel.top, travel.bottom),
  );

  /// Clamps [raw] into [travel], centring on an axis whose range is inverted.
  static Offset clampInto(Offset raw, Rect travel) => Offset(
    _clampAxis(raw.dx, travel.left, travel.right),
    _clampAxis(raw.dy, travel.top, travel.bottom),
  );

  /// The entry of [candidates] closest to [probe].
  ///
  /// Throws [StateError] if [candidates] is empty.
  static T nearest<T>(
    Offset probe,
    Iterable<T> candidates,
    Offset Function(T candidate) originOf,
  ) {
    final iterator = candidates.iterator;
    if (!iterator.moveNext()) {
      throw StateError('nearest() needs at least one candidate');
    }
    var best = iterator.current;
    var bestDistance = (originOf(best) - probe).distanceSquared;
    while (iterator.moveNext()) {
      final distance = (originOf(iterator.current) - probe).distanceSquared;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = iterator.current;
      }
    }
    return best;
  }

  static double _resistAxis(
    double value,
    double low,
    double high,
    double dimension,
    double coefficient,
  ) {
    if (high < low) return (low + high) / 2;
    if (value < low) {
      return low + rubberBand(value - low, dimension, coefficient: coefficient);
    }
    if (value > high) {
      return high +
          rubberBand(value - high, dimension, coefficient: coefficient);
    }
    return value;
  }

  static double _overshootAxis(double value, double low, double high) {
    if (high < low) return 0;
    if (value < low) return value - low;
    if (value > high) return value - high;
    return 0;
  }

  static double _clampAxis(double value, double low, double high) {
    if (high < low) return (low + high) / 2;
    return math.min(math.max(value, low), high);
  }
}
