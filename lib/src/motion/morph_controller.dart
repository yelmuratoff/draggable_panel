import 'package:draggable_panel/src/motion/panel_motion_spec.dart';
import 'package:draggable_panel/src/motion/panel_physics.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';

/// Expansion progress, from `0` collapsed to `1` expanded.
///
/// Gestures scrub this value and springs settle it, both writing the same
/// variable. There is no "is animating" flag to consult, which is what makes a
/// half-finished expansion grabbable at any moment: a scrub simply stops the
/// spring and takes over from wherever it had reached.
///
/// The controller is [AnimationController.unbounded] because a bouncy spring
/// legitimately passes `1` on its way to settling, and a bounded controller
/// would silently clip that overshoot.
final class MorphController extends ChangeNotifier
    implements ValueListenable<double> {
  MorphController({
    required TickerProvider vsync,
    required this.spec,
    double initial = 0,
    this.onCompleted,
  }) : _controller = AnimationController.unbounded(
         vsync: vsync,
         value: initial,
       ) {
    _controller.addListener(notifyListeners);
  }

  /// Called once each time a settle reaches either end of the range.
  final VoidCallback? onCompleted;

  /// The tunables this controller reads. Reassign to retune it in place.
  PanelMotionSpec spec;

  final AnimationController _controller;

  /// How many logical pixels of drag correspond to a full expansion.
  ///
  /// Set by the layout layer once the collapsed and expanded sizes are known.
  double travelPixels = 1;

  @override
  double get value => _controller.value;

  Animation<double> get animation => _controller;

  bool get isAnimating => _controller.isAnimating;

  /// Applies a drag delta, in logical pixels, with a downward drag collapsing.
  ///
  /// Beyond either end of the range the delta is resisted rather than blocked,
  /// so the extremes feel soft in the hand instead of walled off.
  void scrub(double deltaPixels) {
    if (_controller.isAnimating) _controller.stop();
    final travel = travelPixels.abs() < 1 ? 1.0 : travelPixels;
    _controller.value = _resist(_controller.value - deltaPixels / travel);
  }

  /// Springs to [target], entering at [pixelVelocity] logical pixels per second.
  void settleTo(double target, {double pixelVelocity = 0}) {
    if (spec.immediate) {
      _controller.value = target;
      onCompleted?.call();
      return;
    }

    if (spec.reduceMotion) {
      _controller
          .animateTo(target, duration: spec.contentFadeDuration)
          .orCancel
          .then((_) => onCompleted?.call(), onError: (Object _) {});
      return;
    }

    final travel = travelPixels.abs() < 1 ? 1.0 : travelPixels;
    _controller
        .animateWith(
          SpringSimulation(
            spec.morphSpring,
            _controller.value,
            target,
            -pixelVelocity / travel,
            snapToEnd: true,
            tolerance: spec.tolerance,
          ),
        )
        .orCancel
        .then((_) => onCompleted?.call(), onError: (Object _) {});
  }

  /// Chooses an end to settle towards by projecting the release velocity.
  ///
  /// Uses the same projection as a positional fling, so a flick that would
  /// carry past the midpoint commits even when it is released early.
  void settleFromRelease(double pixelVelocity) {
    final travel = travelPixels.abs() < 1 ? 1.0 : travelPixels;
    final projected = PanelPhysics.project(
      _controller.value,
      -pixelVelocity / travel,
      spec.decelerationRate,
    );
    settleTo(projected > 0.5 ? 1 : 0, pixelVelocity: pixelVelocity);
  }

  /// Sets progress with no animation and no completion callback.
  void jumpTo(double target) {
    if (_controller.isAnimating) _controller.stop();
    _controller.value = target;
  }

  double _resist(double raw) {
    final slack = spec.morphSlack;
    if (raw > 1) {
      return 1 + PanelPhysics.rubberBand(raw - 1, slack).clamp(0.0, slack);
    }
    if (raw < 0) {
      return PanelPhysics.rubberBand(raw, slack).clamp(-slack, 0.0);
    }
    return raw;
  }

  @override
  void dispose() {
    _controller
      ..removeListener(notifyListeners)
      ..dispose();
    super.dispose();
  }
}
