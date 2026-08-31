import 'package:draggable_panel/src/motion/morph_controller.dart';
import 'package:draggable_panel/src/motion/panel_motion_spec.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _frame = Duration(milliseconds: 16);

MorphController _morph({
  PanelMotionSpec? spec,
  double initial = 0,
  VoidCallback? onCompleted,
}) {
  final morph = MorphController(
    vsync: const TestVSync(),
    spec: spec ?? PanelMotionSpec(),
    initial: initial,
    onCompleted: onCompleted,
  );
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

    testWidgets('a jump that cancels a settle reports no completion', (
      tester,
    ) async {
      var completed = 0;
      final morph = _morph(onCompleted: () => completed++)..settleTo(1);

      await tester.pump(_frame);
      await tester.pump(_frame);
      morph.jumpTo(morph.value);
      await tester.pump(_frame);

      expect(completed, 0);
    });

    testWidgets('a jump takes over from a running spring with no jump in '
        'value', (tester) async {
      final morph = _morph()..settleTo(1);
      await tester.pump(_frame);
      await tester.pump(_frame);

      final mid = morph.value;
      expect(morph.isAnimating, isTrue);
      expect(mid, greaterThan(0));

      morph.jumpTo(mid);

      expect(morph.isAnimating, isFalse);
      expect(morph.value, mid);
    });

    testWidgets('reversing mid-flight starts from the value it had reached', (
      tester,
    ) async {
      final morph = _morph()..settleTo(1);
      await tester.pump(_frame);
      await tester.pump(_frame);
      await tester.pump(_frame);

      final atReversal = morph.value;
      morph.settleTo(0);

      expect(morph.value, atReversal);

      await _settle(tester, morph);
      expect(morph.value, closeTo(0, 1e-6));
    });

    testWidgets('reversing mid-flight carries its velocity, so it overshoots '
        'before turning around', (tester) async {
      final morph = _morph()..settleTo(1);
      // Far enough in to be moving quickly towards 1.
      await tester.pump(_frame);
      await tester.pump(_frame);
      await tester.pump(_frame);

      final atReversal = morph.value;
      morph.settleTo(0);
      // The first frame after a restart evaluates the simulation at t = 0.
      await tester.pump(_frame);
      await tester.pump(_frame);

      expect(
        morph.value,
        greaterThan(atReversal),
        reason: 'entry velocity should carry it past the reversal point',
      );

      await _settle(tester, morph);
      expect(morph.value, closeTo(0, 1e-6));
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
