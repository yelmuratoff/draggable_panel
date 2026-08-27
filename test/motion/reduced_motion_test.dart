import 'package:draggable_panel/src/motion/morph_controller.dart';
import 'package:draggable_panel/src/motion/offset_spring_driver.dart';
import 'package:draggable_panel/src/motion/panel_motion_spec.dart';
import 'package:flutter_test/flutter_test.dart';

const _frame = Duration(milliseconds: 16);

void main() {
  group('position under reduced motion', () {
    test('snaps instead of springing', () {
      final driver = OffsetSpringDriver(
        vsync: const TestVSync(),
        spec: PanelMotionSpec.reduced(),
      )..settle(target: const Offset(200, 300), velocity: const Offset(800, 0));
      addTearDown(driver.dispose);

      expect(driver.value, const Offset(200, 300));
      expect(driver.isAnimating, isFalse);
    });
  });

  group('expansion under reduced motion', () {
    testWidgets('still cross-fades rather than cutting', (tester) async {
      final morph = MorphController(
        vsync: const TestVSync(),
        spec: PanelMotionSpec.reduced(),
      )..settleTo(1);
      addTearDown(() {
        morph
          ..jumpTo(morph.value)
          ..dispose();
      });

      expect(morph.isAnimating, isTrue);
      expect(morph.value, lessThan(1));

      await tester.pump(_frame);
      await tester.pump(_frame);
      expect(morph.value, greaterThan(0));
      expect(morph.value, lessThan(1));

      await tester.pump(const Duration(milliseconds: 300));
      expect(morph.value, 1);
      expect(morph.isAnimating, isFalse);
    });

    testWidgets('fades linearly over the configured duration', (tester) async {
      final morph = MorphController(
        vsync: const TestVSync(),
        spec: PanelMotionSpec.reduced(),
      )..settleTo(1);
      addTearDown(() {
        morph
          ..jumpTo(morph.value)
          ..dispose();
      });

      await tester.pump(Duration.zero);
      await tester.pump(const Duration(milliseconds: 100));

      expect(morph.value, closeTo(0.5, 0.05));

      morph.jumpTo(1);
    });
  });

  group('instant spec', () {
    test('suppresses both position and expansion', () {
      final spec = PanelMotionSpec.instant();

      expect(spec.immediate, isTrue);
      expect(spec.skipPositionAnimation, isTrue);

      final morph = MorphController(vsync: const TestVSync(), spec: spec)
        ..settleTo(1);
      addTearDown(morph.dispose);

      expect(morph.value, 1);
      expect(morph.isAnimating, isFalse);
    });
  });
}
