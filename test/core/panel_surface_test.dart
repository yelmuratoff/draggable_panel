import 'package:draggable_panel/src/core/panel_surface.dart';
import 'package:draggable_panel/src/core/render_panel_surface.dart';
import 'package:draggable_panel/src/motion/morph_controller.dart';
import 'package:draggable_panel/src/motion/offset_spring_driver.dart';
import 'package:draggable_panel/src/motion/panel_motion_spec.dart';
import 'package:draggable_panel/src/theme/draggable_panel_theme_data.dart';
import 'package:draggable_panel/src/theme/panel_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// A mutable counter a render object can bump from `performLayout`.
final class _Tally {
  int value = 0;
}

/// Counts how many times its subtree is laid out.
final class _CountLayouts extends SingleChildRenderObjectWidget {
  const _CountLayouts({required this.tally, super.child});

  final _Tally tally;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCountLayouts(tally);
}

final class _RenderCountLayouts extends RenderProxyBox {
  _RenderCountLayouts(this.tally);

  final _Tally tally;

  @override
  void performLayout() {
    tally.value++;
    super.performLayout();
  }
}

/// Counts how many times its subtree is painted.
final class _CountPaints extends SingleChildRenderObjectWidget {
  const _CountPaints({required this.tally, super.child});

  final _Tally tally;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCountPaints(tally);
}

final class _RenderCountPaints extends RenderProxyBox {
  _RenderCountPaints(this.tally);

  final _Tally tally;

  @override
  void paint(PaintingContext context, Offset offset) {
    tally.value++;
    super.paint(context, offset);
  }
}

final class _Harness {
  _Harness({PanelMotionSpec? spec})
    : driver = OffsetSpringDriver(
        vsync: const TestVSync(),
        spec: spec ?? PanelMotionSpec(),
      ),
      morph = MorphController(
        vsync: const TestVSync(),
        spec: spec ?? PanelMotionSpec(),
      );

  final OffsetSpringDriver driver;
  final MorphController morph;

  Listenable get repaint => Listenable.merge([driver, morph]);

  void dispose() {
    driver
      ..interrupt()
      ..dispose();
    morph
      ..jumpTo(morph.value)
      ..dispose();
  }
}

Future<_Harness> _pumpSurface(
  WidgetTester tester, {
  _Tally? collapsedLayouts,
  VoidCallback? onBuild,
  Alignment anchor = Alignment.bottomRight,
  Size collapsedSize = const Size(64, 64),
}) async {
  final harness = _Harness();
  addTearDown(harness.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          onBuild?.call();
          return PanelSurface(
            repaint: harness.repaint,
            style: PanelStyle.resolve(
              context,
              DraggablePanelThemeData(collapsedSize: collapsedSize),
            ),
            originOf: () => harness.driver.value,
            expansionOf: () => harness.morph.value,
            anchor: anchor,
            bounds: const EdgeInsets.all(16),
            isDragging: false,
            reduceMotion: false,
            opacity: 1,
            collapsed: collapsedLayouts == null
                ? const ColoredBox(color: Color(0xFF112233))
                : _CountLayouts(
                    tally: collapsedLayouts,
                    child: const ColoredBox(color: Color(0xFF112233)),
                  ),
            expanded: const SizedBox(
              width: 280,
              height: 200,
              child: ColoredBox(color: Color(0xFF445566)),
            ),
          );
        },
      ),
    ),
  );
  return harness;
}

RenderPanelSurface _surface(WidgetTester tester) =>
    tester.renderObject<RenderPanelSurface>(find.byType(PanelSurface));

void main() {
  group('painting', () {
    testWidgets('the collapsed panel sits at the driver position', (
      tester,
    ) async {
      final harness = await _pumpSurface(tester);
      harness.driver.drive(const Offset(200, 400));
      await tester.pump();

      expect(
        _surface(tester).paintedRect,
        const Rect.fromLTWH(200, 400, 64, 64),
      );
    });

    testWidgets('expanding grows the rect from the anchored corner', (
      tester,
    ) async {
      final harness = await _pumpSurface(tester);
      harness.driver.drive(const Offset(400, 400));
      await tester.pump();
      final collapsed = _surface(tester).paintedRect;

      harness.morph.jumpTo(1);
      await tester.pump();
      final expanded = _surface(tester).paintedRect;

      expect(expanded.width, greaterThan(collapsed.width));
      expect(expanded.bottomRight, collapsed.bottomRight);
    });

    testWidgets('staying on screen wins over keeping the corner pinned', (
      tester,
    ) async {
      final harness = await _pumpSurface(tester);
      harness.driver.drive(const Offset(20, 400));
      await tester.pump();

      harness.morph.jumpTo(1);
      await tester.pump();

      expect(_surface(tester).paintedRect.left, greaterThanOrEqualTo(16));
    });

    testWidgets('an expanded panel is never smaller than the collapsed one', (
      tester,
    ) async {
      final harness = await _pumpSurface(
        tester,
        collapsedSize: const Size(320, 240),
      );
      harness.morph.jumpTo(1);
      await tester.pump();

      final rect = _surface(tester).paintedRect;
      expect(rect.width, greaterThanOrEqualTo(320));
      expect(rect.height, greaterThanOrEqualTo(240));
    });

    testWidgets('a hidden panel paints nothing', (tester) async {
      await _pumpSurface(tester);
      _surface(tester).opacity = 0;
      await tester.pump();

      expect(_surface(tester).paintedRect, Rect.zero);
    });
  });

  group('hit testing', () {
    testWidgets('a tap outside the panel reaches the app behind it', (
      tester,
    ) async {
      final harness = await _pumpSurface(tester);
      harness.driver.drive(const Offset(200, 400));
      await tester.pump();

      final surface = _surface(tester);
      final result = BoxHitTestResult();

      expect(surface.hitTest(result, position: const Offset(20, 20)), isFalse);
      expect(surface.hitTest(result, position: const Offset(220, 420)), isTrue);
    });

    testWidgets('a hidden panel is not hit testable', (tester) async {
      await _pumpSurface(tester);
      _surface(tester).opacity = 0;
      await tester.pump();

      expect(
        _surface(tester).hitTest(BoxHitTestResult(), position: Offset.zero),
        isFalse,
      );
    });
  });

  group('performance', () {
    testWidgets('a motion frame rebuilds nothing and lays out nothing', (
      tester,
    ) async {
      var builds = 0;
      final layouts = _Tally();
      final harness = await _pumpSurface(
        tester,
        collapsedLayouts: layouts,
        onBuild: () => builds++,
      );

      await tester.pump();
      final buildsBefore = builds;
      final layoutsBefore = layouts.value;

      expect(buildsBefore, greaterThan(0), reason: 'build counter is wired');
      expect(layoutsBefore, greaterThan(0), reason: 'layout counter is wired');

      for (var frame = 1; frame <= 10; frame++) {
        harness.driver.drive(Offset(100.0 + frame * 8, 200.0 + frame * 4));
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(_surface(tester).paintedRect.left, 180);
      expect(builds, buildsBefore, reason: 'motion must not rebuild widgets');
      expect(
        layouts.value,
        layoutsBefore,
        reason: 'motion must not relayout children',
      );
    });

    testWidgets('motion does not repaint the application behind the panel', (
      tester,
    ) async {
      final appPaints = _Tally();
      final harness = _Harness();
      addTearDown(harness.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Stack(
              fit: StackFit.expand,
              children: [
                _CountPaints(
                  tally: appPaints,
                  child: const ColoredBox(color: Color(0xFFEEEEEE)),
                ),
                PanelSurface(
                  repaint: harness.repaint,
                  style: PanelStyle.resolve(context),
                  originOf: () => harness.driver.value,
                  expansionOf: () => harness.morph.value,
                  anchor: Alignment.bottomRight,
                  bounds: const EdgeInsets.all(16),
                  isDragging: false,
                  reduceMotion: false,
                  opacity: 1,
                  collapsed: const ColoredBox(color: Color(0xFF112233)),
                  expanded: const SizedBox(
                    width: 280,
                    height: 200,
                    child: ColoredBox(color: Color(0xFF445566)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final paintsBefore = appPaints.value;
      expect(paintsBefore, greaterThan(0), reason: 'paint counter is wired');

      for (var frame = 1; frame <= 10; frame++) {
        harness.driver.drive(Offset(100.0 + frame * 8, 200.0 + frame * 4));
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(
        appPaints.value,
        paintsBefore,
        reason: 'the panel must be its own repaint boundary',
      );
    });

    testWidgets('growing the panel also stays paint-only', (tester) async {
      var builds = 0;
      final layouts = _Tally();
      final harness = await _pumpSurface(
        tester,
        collapsedLayouts: layouts,
        onBuild: () => builds++,
      );

      await tester.pump();
      final buildsBefore = builds;
      final layoutsBefore = layouts.value;

      expect(buildsBefore, greaterThan(0), reason: 'build counter is wired');
      expect(layoutsBefore, greaterThan(0), reason: 'layout counter is wired');

      harness.morph.settleTo(1);
      for (var frame = 1; frame <= 12; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(_surface(tester).paintedRect.width, greaterThan(64));
      expect(builds, buildsBefore);
      expect(layouts.value, layoutsBefore);

      harness.morph.jumpTo(1);
    });
  });
}
