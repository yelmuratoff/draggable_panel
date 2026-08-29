import 'dart:math' as math;
import 'dart:ui';

import 'package:draggable_panel/src/motion/panel_motion_spec.dart';
import 'package:draggable_panel/src/motion/panel_physics.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('project', () {
    test('matches the WWDC18 803 projection formula', () {
      expect(
        PanelPhysics.project(100, 1000, kPanelNormalDecelerationRate),
        closeTo(599, 1e-9),
      );
    });

    test('is the identity at rest', () {
      expect(PanelPhysics.project(240, 0, kPanelNormalDecelerationRate), 240);
    });

    test('projects backwards for negative velocity', () {
      expect(
        PanelPhysics.project(100, -1000, kPanelNormalDecelerationRate),
        closeTo(-399, 1e-9),
      );
    });

    test('the fast rate travels less than the normal rate', () {
      final fast = PanelPhysics.project(0, 1000, kPanelFastDecelerationRate);
      final normal = PanelPhysics.project(
        0,
        1000,
        kPanelNormalDecelerationRate,
      );

      expect(fast, closeTo(99, 1e-9));
      expect(fast, lessThan(normal));
    });
  });

  group('rubberBand', () {
    test('is zero with no overshoot', () {
      expect(PanelPhysics.rubberBand(0, 400), 0);
    });

    test('asymptotes at the viewport dimension', () {
      expect(PanelPhysics.rubberBand(1000000000, 400), closeTo(400, 0.01));
      expect(PanelPhysics.rubberBand(1000000000000, 400), lessThan(400));
    });

    test('is odd about zero', () {
      expect(
        PanelPhysics.rubberBand(-137, 400),
        -PanelPhysics.rubberBand(137, 400),
      );
    });

    test('always resists — output stays below input', () {
      for (final overshoot in <double>[1, 10, 100, 400, 900]) {
        expect(
          PanelPhysics.rubberBand(overshoot, 400),
          lessThan(overshoot),
          reason: 'overshoot $overshoot should be damped',
        );
      }
    });

    test('is monotonic in overshoot', () {
      var previous = 0.0;
      for (var overshoot = 1.0; overshoot < 2000; overshoot += 37) {
        final value = PanelPhysics.rubberBand(overshoot, 400);
        expect(value, greaterThan(previous));
        previous = value;
      }
    });

    test('a lower coefficient resists harder', () {
      expect(
        PanelPhysics.rubberBand(100, 400, coefficient: 0.35),
        lessThan(PanelPhysics.rubberBand(100, 400)),
      );
    });

    test('degenerate viewports do not divide by zero', () {
      expect(PanelPhysics.rubberBand(100, 0), 0);
      expect(PanelPhysics.rubberBand(100, -5), 0);
    });
  });

  group('rubberBandSlope', () {
    test('equals the coefficient at the boundary', () {
      expect(
        PanelPhysics.rubberBandSlope(0, 400),
        closeTo(kPanelRubberBandCoefficient, 1e-12),
      );
    });

    test('approaches the derivative of rubberBand', () {
      const overshoot = 120.0;
      const epsilon = 1e-4;
      final numeric =
          (PanelPhysics.rubberBand(overshoot + epsilon, 400) -
              PanelPhysics.rubberBand(overshoot - epsilon, 400)) /
          (2 * epsilon);

      expect(
        PanelPhysics.rubberBandSlope(overshoot, 400),
        closeTo(numeric, 1e-6),
      );
    });

    test('falls off as the panel is pulled further', () {
      expect(
        PanelPhysics.rubberBandSlope(400, 400),
        lessThan(PanelPhysics.rubberBandSlope(40, 400)),
      );
    });
  });

  group('resist', () {
    const travel = Rect.fromLTRB(16, 16, 300, 600);
    const viewport = Size(400, 800);

    test('is the identity inside the travel rect', () {
      for (final point in const <Offset>[
        Offset(16, 16),
        Offset(150, 300),
        Offset(300, 600),
      ]) {
        expect(PanelPhysics.resist(point, travel, viewport), point);
      }
    });

    test('resists past every edge', () {
      final left = PanelPhysics.resist(
        const Offset(-84, 300),
        travel,
        viewport,
      );
      final right = PanelPhysics.resist(
        const Offset(400, 300),
        travel,
        viewport,
      );
      final top = PanelPhysics.resist(const Offset(150, -84), travel, viewport);
      final bottom = PanelPhysics.resist(
        const Offset(150, 700),
        travel,
        viewport,
      );

      expect(left.dx, greaterThan(-84));
      expect(left.dx, lessThan(16));
      expect(right.dx, lessThan(400));
      expect(right.dx, greaterThan(300));
      expect(top.dy, greaterThan(-84));
      expect(bottom.dy, lessThan(700));
    });

    test('resists each axis independently', () {
      final resisted = PanelPhysics.resist(
        const Offset(-100, 300),
        travel,
        viewport,
      );

      expect(resisted.dy, 300);
    });

    test('centres an axis whose travel is inverted', () {
      const inverted = Rect.fromLTRB(100, 16, 20, 600);

      expect(
        PanelPhysics.resist(const Offset(0, 100), inverted, viewport).dx,
        60,
      );
    });
  });

  group('overshootOf', () {
    const travel = Rect.fromLTRB(16, 16, 300, 600);

    test('is zero inside', () {
      expect(
        PanelPhysics.overshootOf(const Offset(150, 300), travel),
        Offset.zero,
      );
    });

    test('is signed outside', () {
      expect(
        PanelPhysics.overshootOf(const Offset(-4, 700), travel),
        const Offset(-20, 100),
      );
    });
  });

  group('nearest', () {
    test('picks the closest candidate', () {
      const corners = <Offset>[
        Offset.zero,
        Offset(300, 0),
        Offset(0, 600),
        Offset(300, 600),
      ];

      expect(
        PanelPhysics.nearest(const Offset(280, 20), corners, (o) => o),
        const Offset(300, 0),
      );
    });

    test('throws on an empty candidate set', () {
      expect(
        () => PanelPhysics.nearest(Offset.zero, const <Offset>[], (o) => o),
        throwsStateError,
      );
    });
  });

  group('kPanelSnapSpring', () {
    test('is the settle spring: response 0.4, critically damped', () {
      final expected = SpringDescription.withDampingRatio(
        mass: 1,
        stiffness: math.pow(2 * math.pi / 0.4, 2).toDouble(),
      );

      expect(kPanelSnapSpring.mass, closeTo(1, 1e-12));
      expect(kPanelSnapSpring.stiffness, closeTo(246.7401100272339, 1e-9));
      expect(kPanelSnapSpring.stiffness, closeTo(expected.stiffness, 1e-9));
      expect(kPanelSnapSpring.damping, closeTo(expected.damping, 1e-9));
    });

    test('never overshoots and settles in well under a second', () {
      final simulation = ScrollSpringSimulation(
        kPanelSnapSpring,
        0,
        300,
        0,
        tolerance: kPanelTolerance,
      );

      var t = 0.0;
      var peak = 0.0;
      while (!simulation.isDone(t) && t < 3) {
        peak = math.max(peak, simulation.x(t));
        t += 1 / 120;
      }

      expect(t, lessThan(1));
      expect(peak, lessThanOrEqualTo(300 + 1e-6));
      expect(simulation.x(t), closeTo(300, 1e-9));
    });

    test('carries release velocity into the settle', () {
      final still = ScrollSpringSimulation(kPanelSnapSpring, 0, 300, 0);
      final flung = ScrollSpringSimulation(kPanelSnapSpring, 0, 300, 2000);

      expect(flung.x(0.05), greaterThan(still.x(0.05)));
    });
  });

  group('PanelMotionSpec', () {
    test('rejects an undamped spring that would never settle', () {
      expect(
        () => PanelMotionSpec(
          snapSpring: const SpringDescription(
            mass: 1,
            stiffness: 100,
            damping: 0,
          ),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects a deceleration rate outside (0, 1)', () {
      expect(
        () => PanelMotionSpec(decelerationRate: 1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('instant and reduced both snap the panel into place', () {
      expect(PanelMotionSpec.instant().skipPositionAnimation, isTrue);
      expect(PanelMotionSpec.reduced().skipPositionAnimation, isTrue);
      expect(PanelMotionSpec().skipPositionAnimation, isFalse);
    });

    test('reduced still cross-fades content, instant does not', () {
      expect(PanelMotionSpec.instant().immediate, isTrue);
      expect(PanelMotionSpec.instant().contentFadeDuration, Duration.zero);

      expect(PanelMotionSpec.reduced().immediate, isFalse);
      expect(PanelMotionSpec.reduced().reduceMotion, isTrue);
      expect(
        PanelMotionSpec.reduced().contentFadeDuration,
        const Duration(milliseconds: 200),
      );
    });

    test('lerp swaps at the midpoint rather than blending springs', () {
      final a = PanelMotionSpec();
      final b = PanelMotionSpec.instant();

      expect(PanelMotionSpec.lerp(a, b, 0.49), same(a));
      expect(PanelMotionSpec.lerp(a, b, 0.5), same(b));
    });

    test('equal specs compare equal and hash alike', () {
      expect(PanelMotionSpec(), PanelMotionSpec());
      expect(PanelMotionSpec().hashCode, PanelMotionSpec().hashCode);
      expect(PanelMotionSpec(), isNot(PanelMotionSpec.instant()));
    });
  });
}
