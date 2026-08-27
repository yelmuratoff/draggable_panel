import 'dart:ui';

import 'package:draggable_panel/src/motion/panel_motion_spec.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

/// Carries the panel's top-left corner, either under a finger or under springs.
///
/// Runs one [Ticker] over two independent per-axis simulations rather than
/// interpolating a single `Offset`. That is what UIKit's spring timing does, and
/// it matters: a straight-line interpolation would drag the panel along the
/// shortest path, whereas independent axes let a release velocity that is not
/// aimed at the target curve into it the way a thrown object does.
final class OffsetSpringDriver extends ChangeNotifier
    implements ValueListenable<Offset> {
  OffsetSpringDriver({
    required TickerProvider vsync,
    required this.spec,
    Offset initial = Offset.zero,
    this.onSettled,
  }) : _value = initial {
    _ticker = vsync.createTicker(_tick);
  }

  /// Called once each time a settle reaches its target.
  final VoidCallback? onSettled;

  /// The tunables this driver reads. Reassign to retune it in place.
  PanelMotionSpec spec;

  late final Ticker _ticker;

  Offset _value;
  Offset _velocity = Offset.zero;
  Simulation? _x;
  Simulation? _y;
  Duration _epoch = Duration.zero;
  Duration _elapsed = Duration.zero;

  @override
  Offset get value => _value;

  /// The current rate of change, in logical pixels per second.
  Offset get velocity => _velocity;

  bool get isAnimating => _ticker.isActive;

  /// Pins the panel to a position under direct manipulation.
  ///
  /// Cancels any running simulation so the finger always wins immediately.
  void drive(Offset position) {
    _halt();
    _emit(position, Offset.zero);
  }

  /// Moves to [position] with no animation and no settle callback.
  void jumpTo(Offset position) => drive(position);

  /// Freezes wherever the panel currently is and reports the velocity it was
  /// carrying, so a re-grab can fold that momentum into the next throw.
  Offset interrupt() {
    final carried = _velocity;
    _halt();
    _velocity = Offset.zero;
    return carried;
  }

  /// Springs to [target], entering the simulation at [velocity].
  ///
  /// Safe to call mid-flight: the new simulation starts from the current
  /// position, so a redirected gesture never produces a jump.
  void settle({required Offset target, Offset velocity = Offset.zero}) {
    if (spec.skipPositionAnimation) {
      _halt();
      _emit(target, Offset.zero);
      onSettled?.call();
      return;
    }

    _x = ScrollSpringSimulation(
      spec.snapSpring,
      _value.dx,
      target.dx,
      velocity.dx,
      tolerance: spec.tolerance,
    );
    _y = ScrollSpringSimulation(
      spec.snapSpring,
      _value.dy,
      target.dy,
      velocity.dy,
      tolerance: spec.tolerance,
    );

    if (_ticker.isActive) {
      _epoch = _elapsed;
      return;
    }
    _epoch = Duration.zero;
    _elapsed = Duration.zero;
    _ticker.start();
  }

  /// Aims an in-flight settle at a new [target], preserving current velocity.
  ///
  /// Used when the viewport changes underneath a moving panel, so it curves to
  /// the new resting place instead of teleporting.
  void retarget(Offset target) {
    if (!_ticker.isActive) {
      _emit(target, Offset.zero);
      return;
    }
    settle(target: target, velocity: _velocity);
  }

  void _tick(Duration elapsed) {
    _elapsed = elapsed;
    final x = _x;
    final y = _y;
    if (x == null || y == null) {
      _halt();
      return;
    }

    final t =
        (elapsed - _epoch).inMicroseconds / Duration.microsecondsPerSecond;
    final done = x.isDone(t) && y.isDone(t);
    _emit(Offset(x.x(t), y.x(t)), Offset(x.dx(t), y.dx(t)));

    if (done) {
      _halt();
      onSettled?.call();
    }
  }

  void _emit(Offset value, Offset velocity) {
    if (value == _value && velocity == _velocity) return;
    _value = value;
    _velocity = velocity;
    notifyListeners();
  }

  void _halt() {
    if (_ticker.isActive) _ticker.stop();
    _x = null;
    _y = null;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
