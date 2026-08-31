import 'package:draggable_panel/src/motion/panel_motion_spec.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';

/// Expansion progress, from `0` collapsed to `1` expanded.
///
/// A settle can be redirected at any moment: [settleTo] starts its simulation
/// from the current value, so reversing an expansion halfway overshoots, turns
/// around and comes back rather than jumping.
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

  @override
  double get value => _controller.value;

  Animation<double> get animation => _controller;

  bool get isAnimating => _controller.isAnimating;

  /// Springs to [target] from the current value and velocity.
  ///
  /// Safe to call mid-flight: the running simulation is replaced rather than
  /// restarted, so a reversal never produces a jump.
  void settleTo(double target) {
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

    _controller
        .animateWith(
          SpringSimulation(
            spec.morphSpring,
            _controller.value,
            target,
            _controller.velocity,
            snapToEnd: true,
            tolerance: spec.tolerance,
          ),
        )
        .orCancel
        .then((_) => onCompleted?.call(), onError: (Object _) {});
  }

  /// Sets progress with no animation and no completion callback.
  void jumpTo(double target) {
    if (_controller.isAnimating) _controller.stop();
    _controller.value = target;
  }

  @override
  void dispose() {
    _controller
      ..removeListener(notifyListeners)
      ..dispose();
    super.dispose();
  }
}
