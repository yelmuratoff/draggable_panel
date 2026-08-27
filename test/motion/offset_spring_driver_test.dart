import 'dart:ui';

import 'package:draggable_panel/src/motion/offset_spring_driver.dart';
import 'package:draggable_panel/src/motion/panel_motion_spec.dart';
import 'package:flutter_test/flutter_test.dart';

const _frame = Duration(milliseconds: 16);

OffsetSpringDriver _driver({
  PanelMotionSpec? spec,
  Offset initial = Offset.zero,
  VoidCallback? onSettled,
}) {
  final driver = OffsetSpringDriver(
    vsync: const TestVSync(),
    spec: spec ?? PanelMotionSpec(),
    initial: initial,
    onSettled: onSettled,
  );
  addTearDown(
    () => driver
      ..interrupt()
      ..dispose(),
  );
  return driver;
}

/// Pumps until [driver] stops, returning how many frames that took.
Future<int> _settleFrames(
  WidgetTester tester,
  OffsetSpringDriver driver, {
  int maxFrames = 600,
}) async {
  var frames = 0;
  while (driver.isAnimating && frames < maxFrames) {
    frames++;
    await tester.pump(_frame);
  }
  return frames;
}

void main() {
  group('direct manipulation', () {
    test('drive reports the position verbatim', () {
      final driver = _driver()..drive(const Offset(120, 240));

      expect(driver.value, const Offset(120, 240));
      expect(driver.isAnimating, isFalse);
    });

    test('drive cancels a running settle so the finger always wins', () {
      final driver = _driver()..settle(target: const Offset(300, 0));
      expect(driver.isAnimating, isTrue);

      driver.drive(const Offset(10, 10));

      expect(driver.isAnimating, isFalse);
      expect(driver.value, const Offset(10, 10));
      expect(driver.velocity, Offset.zero);
    });

    test('notifies only when the value actually changes', () {
      var notifications = 0;
      _driver()
        ..addListener(() => notifications++)
        ..drive(const Offset(5, 5))
        ..drive(const Offset(5, 5));

      expect(notifications, 1);
    });
  });

  group('settling', () {
    testWidgets('reaches the target and stops the ticker', (tester) async {
      var settled = 0;
      final driver = _driver(onSettled: () => settled++)
        ..settle(target: const Offset(300, 180));

      final frames = await _settleFrames(tester, driver);

      expect(driver.value.dx, closeTo(300, 0.1));
      expect(driver.value.dy, closeTo(180, 0.1));
      expect(driver.isAnimating, isFalse);
      expect(settled, 1);
      expect(frames, lessThan(60));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('never overshoots a critically damped target', (tester) async {
      final driver = _driver()..settle(target: const Offset(300, 0));

      var frames = 0;
      while (driver.isAnimating && frames < 600) {
        frames++;
        await tester.pump(_frame);
        expect(driver.value.dx, lessThanOrEqualTo(300.001));
      }

      expect(frames, greaterThan(0));
    });

    testWidgets('a release velocity carries it further, sooner', (
      tester,
    ) async {
      final still = _driver()..settle(target: const Offset(300, 0));
      final flung = _driver()
        ..settle(target: const Offset(300, 0), velocity: const Offset(2000, 0));

      // Ticker.start's first tick reports zero elapsed and only sets the epoch.
      await tester.pump(_frame);
      await tester.pump(_frame);
      await tester.pump(_frame);

      expect(flung.value.dx, greaterThan(still.value.dx));

      still.interrupt();
      flung.interrupt();
    });

    testWidgets('axes settle independently, not along a straight line', (
      tester,
    ) async {
      final driver = _driver()
        ..settle(
          target: const Offset(300, 300),
          velocity: const Offset(3000, 0),
        );

      await tester.pump(_frame);
      await tester.pump(_frame);

      expect(driver.value.dx, greaterThan(driver.value.dy));

      driver.interrupt();
    });
  });

  group('interruption', () {
    testWidgets('interrupt freezes in place and hands back momentum', (
      tester,
    ) async {
      final driver = _driver()..settle(target: const Offset(600, 0));

      for (var frame = 0; frame < 4; frame++) {
        await tester.pump(_frame);
      }

      final frozenAt = driver.value;
      final carried = driver.interrupt();

      expect(driver.isAnimating, isFalse);
      expect(driver.value, frozenAt);
      expect(carried.dx, greaterThan(0));
      expect(driver.velocity, Offset.zero);
    });

    testWidgets('retarget mid-flight keeps position and velocity', (
      tester,
    ) async {
      final driver = _driver()..settle(target: const Offset(600, 0));

      for (var frame = 0; frame < 4; frame++) {
        await tester.pump(_frame);
      }

      final before = driver.value;
      driver.retarget(const Offset(0, 400));

      expect(driver.value, before);
      expect(driver.isAnimating, isTrue);

      await _settleFrames(tester, driver);

      expect(driver.value.dx, closeTo(0, 0.1));
      expect(driver.value.dy, closeTo(400, 0.1));
    });

    test('retarget while idle simply moves there', () {
      final driver = _driver()..retarget(const Offset(50, 60));

      expect(driver.value, const Offset(50, 60));
      expect(driver.isAnimating, isFalse);
    });
  });

  group('immediate spec', () {
    test('settles in one call without running a simulation', () {
      var settled = 0;
      final driver = _driver(
        spec: PanelMotionSpec.instant(),
        onSettled: () => settled++,
      )..settle(target: const Offset(42, 84), velocity: const Offset(999, 999));

      expect(driver.value, const Offset(42, 84));
      expect(driver.isAnimating, isFalse);
      expect(settled, 1);
    });
  });
}
