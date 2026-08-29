import 'package:draggable_panel/src/motion/panel_physics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';

/// The settle spring: critically damped with a 400 ms response, taken from the
/// sample code accompanying WWDC 2018 session 803.
///
/// [SpringDescription.withDurationAndBounce] mirrors SwiftUI's spring model, in
/// which `duration` is what UIKit calls `response`, so this is that spring
/// exactly rather than an approximation of it.
final SpringDescription kPanelSnapSpring =
    SpringDescription.withDurationAndBounce(
      duration: const Duration(milliseconds: 400),
    );

/// A slightly softer, faintly bouncy spring for growing and shrinking.
final SpringDescription kPanelMorphSpring =
    SpringDescription.withDurationAndBounce(
      duration: const Duration(milliseconds: 480),
      bounce: 0.12,
    );

/// Tolerance at which a settle is considered finished.
///
/// Flutter's default of `1e-3` spends roughly twenty extra frames travelling a
/// distance no display can show, which costs both battery and test runtime.
const Tolerance kPanelTolerance = Tolerance(distance: 0.05, velocity: 0.5);

/// Every tunable that decides how the panel moves.
///
/// Springs are authored with [SpringDescription.withDurationAndBounce] because
/// duration-and-bounce is the model designers reason in; mass, stiffness, and
/// damping are derived from it.
@immutable
final class PanelMotionSpec {
  PanelMotionSpec({
    SpringDescription? snapSpring,
    SpringDescription? morphSpring,
    this.tolerance = kPanelTolerance,
    this.decelerationRate = kPanelNormalDecelerationRate,
    this.rubberBandCoefficient = kPanelRubberBandCoefficient,
    this.momentumHalfLife = const Duration(milliseconds: 100),
    this.contentFadeDuration = Duration.zero,
    this.stashCommit = 0.25,
    this.morphSlack = 0.12,
    this.expandTravelFraction = 0.35,
    this.immediate = false,
    this.reduceMotion = false,
  }) : assert(
         (snapSpring ?? kPanelSnapSpring).damping > 0 &&
             (morphSpring ?? kPanelMorphSpring).damping > 0,
         'An undamped spring never settles, which hangs pumpAndSettle.',
       ),
       assert(
         decelerationRate > 0 && decelerationRate < 1,
         'decelerationRate must be in the range (0, 1)',
       ),
       snapSpring = snapSpring ?? kPanelSnapSpring,
       morphSpring = morphSpring ?? kPanelMorphSpring;

  /// Motion suppressed entirely: geometry snaps and content swaps at once.
  ///
  /// Intended for widget tests that assert targets rather than trajectories.
  PanelMotionSpec.instant() : this(immediate: true);

  /// The reduced-motion variant used when [MediaQueryData.disableAnimations] is
  /// set: geometry snaps, but content still cross-fades.
  ///
  /// Fades are acceptable under reduced motion; translation and scale are not.
  PanelMotionSpec.reduced()
    : this(
        reduceMotion: true,
        contentFadeDuration: const Duration(milliseconds: 200),
      );

  /// Carries the panel to a resting placement after a drag.
  final SpringDescription snapSpring;

  /// Drives expansion progress between collapsed and expanded.
  final SpringDescription morphSpring;

  /// When a simulation is close enough to its target to stop.
  final Tolerance tolerance;

  /// Deceleration used to project where a fling would land.
  final double decelerationRate;

  /// Resistance constant for dragging beyond the bounds.
  final double rubberBandCoefficient;

  /// How quickly momentum captured from an interrupted settle decays.
  ///
  /// [Duration.zero] discards it outright, which is UIKit's behaviour; the
  /// default keeps it briefly, so grabbing and immediately flicking compounds
  /// the throw while grabbing and holding does not.
  final Duration momentumHalfLife;

  /// How long collapsed and expanded content cross-fade when [reduceMotion].
  final Duration contentFadeDuration;

  /// How far past its resting edge the panel must project to park there, as a
  /// fraction of the panel's width.
  final double stashCommit;

  /// How far expansion progress may be dragged beyond its `0..1` range before
  /// resistance holds it, so the ends feel soft rather than walled.
  final double morphSlack;

  /// How much of the available height a drag must cover to fully expand or
  /// collapse the panel, as a fraction of the viewport bounds.
  ///
  /// Lower values make the panel open and close with a shorter gesture.
  final double expandTravelFraction;

  /// Whether settles complete instantly instead of running a simulation.
  ///
  /// Suppresses both position and expansion animation. Intended for tests that
  /// assert targets rather than trajectories.
  final bool immediate;

  /// Whether to honour a reduced-motion preference.
  ///
  /// Position snaps and the panel's rect steps between its collapsed and
  /// expanded sizes, but its content still cross-fades over
  /// [contentFadeDuration]. Fades are acceptable under reduced motion;
  /// translation and scale are not.
  final bool reduceMotion;

  /// Whether position changes should complete without a simulation.
  bool get skipPositionAnimation => immediate || reduceMotion;

  PanelMotionSpec copyWith({
    SpringDescription? snapSpring,
    SpringDescription? morphSpring,
    Tolerance? tolerance,
    double? decelerationRate,
    double? rubberBandCoefficient,
    Duration? momentumHalfLife,
    Duration? contentFadeDuration,
    double? stashCommit,
    double? morphSlack,
    double? expandTravelFraction,
    bool? immediate,
    bool? reduceMotion,
  }) => PanelMotionSpec(
    snapSpring: snapSpring ?? this.snapSpring,
    morphSpring: morphSpring ?? this.morphSpring,
    tolerance: tolerance ?? this.tolerance,
    decelerationRate: decelerationRate ?? this.decelerationRate,
    rubberBandCoefficient: rubberBandCoefficient ?? this.rubberBandCoefficient,
    momentumHalfLife: momentumHalfLife ?? this.momentumHalfLife,
    contentFadeDuration: contentFadeDuration ?? this.contentFadeDuration,
    stashCommit: stashCommit ?? this.stashCommit,
    morphSlack: morphSlack ?? this.morphSlack,
    expandTravelFraction: expandTravelFraction ?? this.expandTravelFraction,
    immediate: immediate ?? this.immediate,
    reduceMotion: reduceMotion ?? this.reduceMotion,
  );

  /// Interpolates between two specs, switching over at the midpoint.
  ///
  /// A spring halfway between two stiffnesses is not the spring a designer
  /// asked for, so the values swap rather than blend.
  static PanelMotionSpec? lerp(
    PanelMotionSpec? a,
    PanelMotionSpec? b,
    double t,
  ) => t < 0.5 ? a : b;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PanelMotionSpec &&
          other.snapSpring.mass == snapSpring.mass &&
          other.snapSpring.stiffness == snapSpring.stiffness &&
          other.snapSpring.damping == snapSpring.damping &&
          other.morphSpring.mass == morphSpring.mass &&
          other.morphSpring.stiffness == morphSpring.stiffness &&
          other.morphSpring.damping == morphSpring.damping &&
          other.tolerance.distance == tolerance.distance &&
          other.tolerance.velocity == tolerance.velocity &&
          other.decelerationRate == decelerationRate &&
          other.rubberBandCoefficient == rubberBandCoefficient &&
          other.momentumHalfLife == momentumHalfLife &&
          other.contentFadeDuration == contentFadeDuration &&
          other.stashCommit == stashCommit &&
          other.morphSlack == morphSlack &&
          other.expandTravelFraction == expandTravelFraction &&
          other.immediate == immediate &&
          other.reduceMotion == reduceMotion;

  @override
  int get hashCode => Object.hash(
    Object.hash(snapSpring.mass, snapSpring.stiffness, snapSpring.damping),
    Object.hash(morphSpring.mass, morphSpring.stiffness, morphSpring.damping),
    Object.hash(tolerance.distance, tolerance.velocity),
    decelerationRate,
    rubberBandCoefficient,
    momentumHalfLife,
    contentFadeDuration,
    stashCommit,
    morphSlack,
    expandTravelFraction,
    immediate,
    reduceMotion,
  );
}
