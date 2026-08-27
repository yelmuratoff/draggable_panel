import 'package:draggable_panel/src/motion/morph_controller.dart';
import 'package:draggable_panel/src/motion/panel_motion_spec.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _frame = Duration(milliseconds: 16);

MorphController _morph({
  PanelMotionSpec? spec,
  double initial = 0,
  double travelPixels = 200,
  VoidCallback? onCompleted,
}) {
  final morph = MorphController(
    vsync: const TestVSync(),
    spec: spec ?? PanelMotionSpec(),
    initial: initial,
    onCompleted: onCompleted,
  )..travelPixels = travelPixels;
  addTearDown(() {
    morph
      ..jumpTo(morph.value)
      ..dispose();
  });
  return morph;
}

Future<void> _settle(WidgetTester tester, MorphController morph) async {
  var frames = 0;
  while (morph.isAnimating && frames < 600) {
    frames++;
    await tester.pump(_frame);
  }
}

void main() {
  group('scrub', () {
    test('dragging up expands, dragging down collapses', () {
      final morph = _morph(initial: 0.5)..scrub(-100);
      expect(morph.value, closeTo(1, 1e-9));

      morph.scrub(100);
      expect(morph.value, closeTo(0.5, 1e-9));
    });

    test('resists beyond the ends instead of walling off', () {
      final morph = _morph(initial: 1)..scrub(-200);

      expect(morph.value, greaterThan(1));
      expect(morph.value, lessThan(1 + PanelMotionSpec().morphSlack));
    });

    test('resists below zero symmetrically', () {
      final morph = _morph()..scrub(200);

      expect(morph.value, lessThan(0));
      expect(morph.value, greaterThan(-PanelMotionSpec().morphSlack));
    });

    testWidgets('takes over from a running spring with no jump', (
      tester,
    ) async {
      final morph = _morph()..settleTo(1);
      await tester.pump(_frame);
      await tester.pump(_frame);

      final mid = morph.value;
      expect(morph.isAnimating, isTrue);
      expect(mid, greaterThan(0));

      morph.scrub(0);

      expect(morph.isAnimating, isFalse);
      expect(morph.value, mid);
    });
  });

  group('settle', () {
    testWidgets('reaches the target and reports completion once', (
      tester,
    ) async {
      var completed = 0;
      final morph = _morph(onCompleted: () => completed++)..settleTo(1);

      await _settle(tester, morph);

      expect(morph.value, closeTo(1, 1e-6));
      expect(morph.isAnimating, isFalse);
      expect(completed, 1);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('a scrub that cancels a settle reports no completion', (
      tester,
    ) async {
      var completed = 0;
      final morph = _morph(onCompleted: () => completed++)..settleTo(1);

      await tester.pump(_frame);
      await tester.pump(_frame);
      morph.scrub(0);
      await tester.pump(_frame);

      expect(completed, 0);
    });

    testWidgets('reversing mid-flight returns without a discontinuity', (
      tester,
    ) async {
      final morph = _morph()..settleTo(1);
      await tester.pump(_frame);
      await tester.pump(_frame);
      await tester.pump(_frame);

      final atReversal = morph.value;
      morph.settleTo(0);

      expect(morph.value, atReversal);

      await tester.pump(_frame);
      expect(morph.value, greaterThan(0));

      await _settle(tester, morph);
      expect(morph.value, closeTo(0, 1e-6));
    });

    testWidgets('a throw upward keeps rising before it turns around', (
      tester,
    ) async {
      final morph = _morph(initial: 0.7)..settleTo(0, pixelVelocity: -600);

      await tester.pump(_frame);
      await tester.pump(_frame);

      expect(morph.value, greaterThan(0.7));

      await _settle(tester, morph);
      expect(morph.value, closeTo(0, 1e-6));
    });
  });

  group('settleFromRelease', () {
    testWidgets('a slow release past the midpoint completes the expansion', (
      tester,
    ) async {
      final morph = _morph(initial: 0.6)..settleFromRelease(0);
      await _settle(tester, morph);

      expect(morph.value, closeTo(1, 1e-6));
    });

    testWidgets('a slow release below the midpoint falls back', (tester) async {
      final morph = _morph(initial: 0.4)..settleFromRelease(0);
      await _settle(tester, morph);

      expect(morph.value, closeTo(0, 1e-6));
    });

    testWidgets('a fast flick commits even when released early', (
      tester,
    ) async {
      final morph = _morph(initial: 0.2)..settleFromRelease(-900);
      await _settle(tester, morph);

      expect(morph.value, closeTo(1, 1e-6));
    });
  });

  group('immediate spec', () {
    test('settles in one call and reports completion', () {
      var completed = 0;
      final morph = _morph(
        spec: PanelMotionSpec.instant(),
        onCompleted: () => completed++,
      )..settleTo(1);

      expect(morph.value, 1);
      expect(morph.isAnimating, isFalse);
      expect(completed, 1);
    });
  });
}
