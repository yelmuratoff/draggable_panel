import 'package:draggable_panel/draggable_panel.dart';
import 'package:draggable_panel/src/core/panel_surface.dart';
import 'package:draggable_panel/src/core/render_panel_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// The panel's default margin and collapsed width, as `defaultPanelTheme`
/// resolves them.
const _margin = 16.0;
const _collapsed = 64.0;

const _collapsedKey = ValueKey('collapsed');
const _expandedKey = ValueKey('expanded');
const _appKey = ValueKey('app');

/// A panel whose motion is suppressed, so tests assert targets rather than
/// trajectories.
Future<DraggablePanelController> _pumpPanel(
  WidgetTester tester, {
  DraggablePanelController? controller,
  PanelBehavior behavior = const PanelBehavior(),
  DraggablePanelThemeData? theme,
  bool disableAnimations = false,
  TextDirection direction = TextDirection.ltr,
  ValueChanged<PanelPlacement>? onPlacementChanged,
}) async {
  final panelController = controller ?? DraggablePanelController();
  if (controller == null) addTearDown(panelController.dispose);

  final base = theme ?? const DraggablePanelThemeData();
  final resolved = base.motion == null
      ? base.copyWith(motion: PanelMotionSpec.instant())
      : base;

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: Directionality(
            textDirection: direction,
            child: DraggablePanel(
              controller: panelController,
              behavior: behavior,
              theme: resolved,
              onPlacementChanged: onPlacementChanged,
              collapsedBuilder: (context, status) => const ColoredBox(
                key: _collapsedKey,
                color: Color(0xFF112233),
              ),
              expandedBuilder: (context, status) => const SizedBox(
                key: _expandedKey,
                width: 280,
                height: 200,
                child: ColoredBox(color: Color(0xFF445566)),
              ),
              child: const ColoredBox(key: _appKey, color: Color(0xFFFFFFFF)),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return panelController;
}

Duration _at(int frame) => Duration(milliseconds: 16 * frame);

/// Carries the panel to [target] and comes to a stop before letting go.
///
/// The cadence is explicit because `tester.fling` synthesises its own, and the
/// still frames at the end matter: a release still in motion projects far past
/// wherever the finger was, which is a different gesture entirely.
Future<void> _dragTo(WidgetTester tester, Offset target) async {
  final start = _paintedRect(tester).center;
  final gesture = await tester.startGesture(start);
  const steps = 10;
  var frame = 0;

  Future<void> moveTo(Offset position) async {
    frame++;
    await gesture.moveTo(position, timeStamp: _at(frame));
    await tester.pump(const Duration(milliseconds: 16));
  }

  for (var step = 1; step <= steps; step++) {
    await moveTo(Offset.lerp(start, target, step / steps)!);
  }
  for (var still = 0; still < 6; still++) {
    await moveTo(target);
  }

  await gesture.up();
  await tester.pump();
}

Rect _panelRect(WidgetTester tester) =>
    tester.getRect(find.byKey(_collapsedKey));

/// The rect the panel surface actually painted, tab included.
Rect _paintedRect(WidgetTester tester) => tester
    .renderObject<RenderPanelSurface>(find.byType(PanelSurface))
    .paintedRect;

void main() {
  group('layout', () {
    testWidgets('a box smaller than the window is reported, not silently '
        'mispositioned', (tester) async {
      final errors = <FlutterErrorDetails>[];
      final reportError = FlutterError.onError;
      FlutterError.onError = errors.add;

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: DraggablePanel(
                theme: DraggablePanelThemeData(
                  motion: PanelMotionSpec.instant(),
                ),
                collapsedBuilder: (context, status) =>
                    const ColoredBox(color: Color(0xFF112233)),
                expandedBuilder: (context, status) =>
                    const SizedBox(width: 200, height: 100),
              ),
            ),
          ),
        ),
      );

      FlutterError.onError = reportError;

      expect(
        errors.map((details) => details.exception.toString()),
        contains(contains('Mount it through MaterialApp.builder')),
      );
      expect(
        find.byType(DraggablePanel),
        findsOneWidget,
        reason: 'the report must not take the app down with it',
      );
    });

    testWidgets('the report is made once, not on every layout', (tester) async {
      final errors = <FlutterErrorDetails>[];
      final reportError = FlutterError.onError;
      FlutterError.onError = errors.add;

      Widget boxed(double side) => MaterialApp(
        home: Center(
          child: SizedBox(
            width: side,
            height: side,
            child: DraggablePanel(
              theme: DraggablePanelThemeData(motion: PanelMotionSpec.instant()),
              collapsedBuilder: (context, status) =>
                  const ColoredBox(color: Color(0xFF112233)),
              expandedBuilder: (context, status) =>
                  const SizedBox(width: 200, height: 100),
            ),
          ),
        ),
      );

      await tester.pumpWidget(boxed(300));
      await tester.pumpWidget(boxed(320));
      await tester.pumpWidget(boxed(340));

      FlutterError.onError = reportError;

      expect(errors, hasLength(1));
    });

    testWidgets('starts collapsed in the bottom-end corner', (tester) async {
      final controller = await _pumpPanel(tester);

      expect(controller.phase, PanelPhase.collapsed);
      expect(find.byKey(_appKey), findsOneWidget);

      final rect = _panelRect(tester);
      expect(rect.size, const Size(64, 64));
      expect(rect.right, closeTo(800 - 16, 0.5));
      expect(rect.bottom, closeTo(600 - 16, 0.5));
    });

    testWidgets('honours an initial placement', (tester) async {
      final controller = DraggablePanelController(
        initialPlacement: const PanelPlacement.corner(PanelCorner.topStart),
      );
      addTearDown(controller.dispose);
      await _pumpPanel(tester, controller: controller);

      final rect = _panelRect(tester);
      expect(rect.left, closeTo(16, 0.5));
      expect(rect.top, closeTo(16, 0.5));
    });

    testWidgets('mirrors the start corner under RTL', (tester) async {
      final controller = DraggablePanelController(
        initialPlacement: const PanelPlacement.corner(PanelCorner.topStart),
      );
      addTearDown(controller.dispose);
      await _pumpPanel(
        tester,
        controller: controller,
        direction: TextDirection.rtl,
      );

      expect(_panelRect(tester).right, closeTo(800 - 16, 0.5));
    });

    testWidgets('a custom collapsed size is honoured', (tester) async {
      await _pumpPanel(
        tester,
        theme: const DraggablePanelThemeData(collapsedSize: Size(160, 90)),
      );

      expect(_panelRect(tester).size, const Size(160, 90));
    });

    testWidgets('the collapsed size never drops below the tap target', (
      tester,
    ) async {
      await _pumpPanel(
        tester,
        theme: const DraggablePanelThemeData(collapsedSize: Size(10, 10)),
      );

      expect(_panelRect(tester).size, const Size(48, 48));
    });
  });

  group('content context', () {
    testWidgets('bare text in a builder inherits the app text style', (
      tester,
    ) async {
      late TextStyle collapsedStyle;
      late TextStyle expandedStyle;

      final controller = DraggablePanelController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: DraggablePanel(
            controller: controller,
            theme: DraggablePanelThemeData(motion: PanelMotionSpec.instant()),
            collapsedBuilder: (context, status) => Builder(
              builder: (context) {
                collapsedStyle = DefaultTextStyle.of(context).style;
                return const Text('c');
              },
            ),
            expandedBuilder: (context, status) => SizedBox(
              width: 200,
              height: 120,
              child: Builder(
                builder: (context) {
                  expandedStyle = DefaultTextStyle.of(context).style;
                  return const Text('e');
                },
              ),
            ),
            child: const ColoredBox(color: Color(0xFFFFFFFF)),
          ),
        ),
      );
      await tester.pump();

      // DefaultTextStyle.fallback is 48px monospace, double-underlined, red.
      for (final style in [collapsedStyle, expandedStyle]) {
        expect(style.fontSize, isNot(48));
        expect(style.decoration, isNot(TextDecoration.underline));
        expect(style.fontFamily, isNot('monospace'));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('an InkWell inside panel content finds a Material', (
      tester,
    ) async {
      var taps = 0;
      final controller = DraggablePanelController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: DraggablePanel(
            controller: controller,
            theme: DraggablePanelThemeData(motion: PanelMotionSpec.instant()),
            collapsedBuilder: (context, status) => InkWell(
              key: _collapsedKey,
              onTap: () => taps++,
              child: const SizedBox.expand(),
            ),
            expandedBuilder: (context, status) =>
                const SizedBox(width: 200, height: 120),
            child: const ColoredBox(color: Color(0xFFFFFFFF)),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(_collapsedKey));
      await tester.pump();

      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'a Tooltip in panel content finds an Overlay under MaterialApp.builder',
      (tester) async {
        final controller = DraggablePanelController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => DraggablePanel(
              controller: controller,
              theme: DraggablePanelThemeData(motion: PanelMotionSpec.instant()),
              collapsedBuilder: (context, status) =>
                  const ColoredBox(color: Color(0xFF112233)),
              expandedBuilder: (context, status) => const SizedBox(
                width: 200,
                height: 120,
                child: Tooltip(
                  key: _expandedKey,
                  message: 'Logs',
                  child: SizedBox.expand(),
                ),
              ),
              child: child,
            ),
            home: const ColoredBox(key: _appKey, color: Color(0xFFFFFFFF)),
          ),
        );
        controller.expand();
        await tester.pump();

        expect(tester.takeException(), isNull);

        tester
            .state<TooltipState>(find.byKey(_expandedKey))
            .ensureTooltipVisible();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text('Logs'), findsOneWidget);
      },
    );
  });

  group('expanding', () {
    testWidgets('a tap expands the panel in place', (tester) async {
      final controller = await _pumpPanel(tester);
      final collapsed = _panelRect(tester);

      await tester.tap(find.byKey(_collapsedKey));
      await tester.pump();

      expect(controller.phase, PanelPhase.expanded);
      final expanded = tester.getRect(find.byKey(_expandedKey));
      expect(expanded.size, const Size(280, 200));
      expect(expanded.bottomRight, collapsed.bottomRight);
    });

    testWidgets('a second tap collapses it again', (tester) async {
      final controller = await _pumpPanel(tester);

      await tester.tap(find.byKey(_collapsedKey));
      await tester.pump();
      expect(controller.phase, PanelPhase.expanded);

      controller.toggle();
      await tester.pump();
      expect(controller.phase, PanelPhase.collapsed);
    });

    testWidgets('tapToExpand false leaves a tap inert', (tester) async {
      final controller = await _pumpPanel(
        tester,
        behavior: const PanelBehavior(tapToExpand: false),
      );

      await tester.tap(find.byKey(_collapsedKey));
      await tester.pump();

      expect(controller.phase, PanelPhase.collapsed);
    });

    testWidgets('tapping outside collapses an expanded panel', (tester) async {
      final controller = await _pumpPanel(tester);
      controller.expand();
      await tester.pump();

      await tester.tapAt(const Offset(40, 40));
      await tester.pump();

      expect(controller.phase, PanelPhase.collapsed);
    });
  });

  group('dragging', () {
    testWidgets('a drag moves the panel and snaps to a corner', (tester) async {
      final controller = await _pumpPanel(
        tester,
        behavior: const PanelBehavior(snapPolicy: PanelSnapPolicy.corners),
      );
      expect(
        controller.placement,
        const PanelPlacement.corner(PanelCorner.bottomEnd),
      );

      final gesture = await tester.startGesture(_panelRect(tester).center);
      for (var frame = 1; frame <= 10; frame++) {
        await gesture.moveBy(
          const Offset(-70, -50),
          timeStamp: Duration(milliseconds: 16 * frame),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump();

      expect(
        controller.placement,
        const PanelPlacement.corner(PanelCorner.topStart),
      );
      expect(controller.phase, PanelPhase.collapsed);
    });

    testWidgets('by default it settles against a side at any height', (
      tester,
    ) async {
      await _pumpPanel(tester);
      final start = _panelRect(tester);

      final gesture = await tester.startGesture(start.center);
      for (var frame = 1; frame <= 8; frame++) {
        await gesture.moveBy(
          const Offset(-40, -30),
          timeStamp: Duration(milliseconds: 16 * frame),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump();

      final rect = _panelRect(tester);
      expect(rect.right, closeTo(784, 1), reason: 'flush against the side');
      expect(
        rect.center.dy,
        lessThan(start.center.dy - 100),
        reason: 'and at the height it was left, not herded into a corner',
      );
      expect(
        rect.bottom,
        lessThan(584),
        reason: 'not snapped back down to the bottom corner',
      );
    });

    testWidgets('the panel tracks the finger during the drag', (tester) async {
      await _pumpPanel(tester);
      final start = _panelRect(tester);

      final gesture = await tester.startGesture(start.center);
      await gesture.moveBy(const Offset(-100, -80));
      await tester.pump();

      final moved = _panelRect(tester);
      expect(moved.center.dx, closeTo(start.center.dx - 100, 1));
      expect(moved.center.dy, closeTo(start.center.dy - 80, 1));

      await gesture.up();
      await tester.pump();
    });

    testWidgets('reports a resting placement, never a dragging one', (
      tester,
    ) async {
      final seen = <PanelPlacement>[];
      await _pumpPanel(
        tester,
        behavior: const PanelBehavior(snapPolicy: PanelSnapPolicy.corners),
        onPlacementChanged: seen.add,
      );

      final gesture = await tester.startGesture(_panelRect(tester).center);
      for (var frame = 1; frame <= 8; frame++) {
        await gesture.moveBy(
          const Offset(-80, -60),
          timeStamp: Duration(milliseconds: 16 * frame),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(seen, isEmpty);

      await gesture.up();
      await tester.pump();

      expect(seen, [const PanelPlacement.corner(PanelCorner.topStart)]);
    });

    testWidgets('an open panel travels with the finger', (tester) async {
      final controller = await _pumpPanel(tester);
      controller.expand();
      await tester.pump();

      final start = _paintedRect(tester);
      final gesture = await tester.startGesture(start.center);
      await gesture.moveBy(const Offset(-120, 0));
      await tester.pump();

      expect(_paintedRect(tester).left, closeTo(start.left - 120, 0.5));
      expect(
        _paintedRect(tester).size,
        start.size,
        reason: 'it travels, it does not resize',
      );

      await gesture.up();
      await tester.pump();
    });

    testWidgets('draggable false pins the panel in place', (tester) async {
      final controller = await _pumpPanel(
        tester,
        behavior: const PanelBehavior(draggable: false),
      );
      final start = _panelRect(tester);

      final gesture = await tester.startGesture(start.center);
      await gesture.moveBy(const Offset(-200, -200));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(_panelRect(tester), start);
      expect(controller.phase, PanelPhase.collapsed);
    });
  });

  group('stashing', () {
    testWidgets('the parked fade tracks the settle from its first frame', (
      tester,
    ) async {
      final controller = DraggablePanelController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: DraggablePanel(
            controller: controller,
            theme: const DraggablePanelThemeData(stashedOpacity: 0.4),
            collapsedBuilder: (context, status) =>
                const ColoredBox(key: _collapsedKey, color: Color(0xFF112233)),
            expandedBuilder: (context, status) =>
                const SizedBox(width: 200, height: 120),
            child: const ColoredBox(key: _appKey, color: Color(0xFFFFFFFF)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final surface = tester.renderObject<RenderPanelSurface>(
        find.byType(PanelSurface),
      );
      expect(surface.paintOpacity, 1, reason: 'opaque while it rests');

      controller.stash();
      final sampled = <double>[];
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        sampled.add(surface.paintOpacity);
      }

      for (var i = 1; i < sampled.length; i++) {
        expect(sampled[i], lessThanOrEqualTo(sampled[i - 1]));
        expect(sampled[i - 1] - sampled[i], lessThan(0.2));
      }
      expect(sampled[2], lessThan(1), reason: 'fading while it travels');
      expect(sampled.last, lessThan(0.6), reason: 'most of the way down');
    });

    testWidgets('a hard sideways flick parks the panel off-screen', (
      tester,
    ) async {
      final controller = await _pumpPanel(tester);

      final gesture = await tester.startGesture(_panelRect(tester).center);
      for (var frame = 1; frame <= 8; frame++) {
        await gesture.moveBy(
          const Offset(60, 0),
          timeStamp: Duration(milliseconds: 8 * frame),
        );
        await tester.pump(const Duration(milliseconds: 8));
      }
      await gesture.up();
      await tester.pump();

      expect(controller.phase, PanelPhase.stashed);
      expect(_panelRect(tester).right, greaterThan(800 - 32));
    });

    testWidgets('the same sideways flick parks an open panel', (tester) async {
      final controller = await _pumpPanel(tester);
      controller.expand();
      await tester.pump();
      expect(controller.phase, PanelPhase.expanded);

      final gesture = await tester.startGesture(_paintedRect(tester).center);
      for (var frame = 1; frame <= 8; frame++) {
        await gesture.moveBy(
          const Offset(60, 0),
          timeStamp: Duration(milliseconds: 8 * frame),
        );
        await tester.pump(const Duration(milliseconds: 8));
      }
      await gesture.up();
      await tester.pump();

      expect(controller.phase, PanelPhase.stashed);
      expect(
        _paintedRect(tester).size,
        const Size(35, 70),
        reason: 'it closed all the way down into its tab',
      );
    });

    testWidgets('an open panel parks at the height it was open at', (
      tester,
    ) async {
      final controller = await _pumpPanel(tester);
      controller.expand();
      await tester.pump();

      final gesture = await tester.startGesture(_paintedRect(tester).center);
      for (var frame = 1; frame <= 8; frame++) {
        await gesture.moveBy(
          const Offset(60, 0),
          timeStamp: Duration(milliseconds: 8 * frame),
        );
        await tester.pump(const Duration(milliseconds: 8));
      }
      await gesture.up();
      await tester.pump();

      expect(
        controller.placement,
        const PanelPlacement.stashed(PanelEdge.end, verticalAlignment: 1),
      );
    });

    testWidgets('dragging an open panel about does not park it', (
      tester,
    ) async {
      final controller = await _pumpPanel(tester);
      controller.expand();
      await tester.pump();

      final gesture = await tester.startGesture(_paintedRect(tester).center);
      for (var frame = 1; frame <= 8; frame++) {
        await gesture.moveBy(
          const Offset(0, -30),
          timeStamp: Duration(milliseconds: 16 * frame),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump();

      expect(controller.phase, PanelPhase.expanded);
    });

    testWidgets('tapping a stashed panel brings it back', (tester) async {
      final controller = await _pumpPanel(tester);
      controller.stash();
      await tester.pump();
      expect(controller.phase, PanelPhase.stashed);

      final peek = _paintedRect(tester);
      await tester.tapAt(Offset(peek.left + 4, peek.center.dy));
      await tester.pump();

      expect(controller.phase, PanelPhase.collapsed);
    });
  });

  group('expandOnUnstash', () {
    const behavior = PanelBehavior(expandOnUnstash: true);

    testWidgets('a tap on the tab opens the panel outright', (tester) async {
      final controller = await _pumpPanel(tester, behavior: behavior);
      controller.stash();
      await tester.pump();

      final peek = _paintedRect(tester);
      await tester.tapAt(Offset(peek.left + 4, peek.center.dy));
      await tester.pump();

      expect(controller.phase, PanelPhase.expanded);
      expect(find.byKey(_expandedKey), findsOneWidget);
    });

    testWidgets('the collapsed window is still there to close down to', (
      tester,
    ) async {
      final controller = await _pumpPanel(tester, behavior: behavior);
      controller.stash();
      await tester.pump();

      controller.unstash();
      await tester.pump();
      expect(controller.phase, PanelPhase.expanded);

      controller.collapse();
      await tester.pump();

      expect(
        controller.phase,
        PanelPhase.collapsed,
        reason: 'unlike collapsible: false, closing does not park it',
      );
      expect(_paintedRect(tester).size, const Size(64, 64));
    });

    testWidgets('a parked tab dragged to the far edge parks there', (
      tester,
    ) async {
      final controller = await _pumpPanel(tester, behavior: behavior);
      controller.stash(PanelEdge.end);
      await tester.pump();
      expect(controller.phase, PanelPhase.stashed);

      const flushAgainstFarSide = _margin + _collapsed / 2;
      await _dragTo(tester, const Offset(flushAgainstFarSide, 300));

      expect(
        controller.placement,
        isA<StashedPlacement>(),
        reason: 'moving a tab along to the other side is not asking to open it',
      );
      expect(controller.phase, PanelPhase.stashed);
    });

    testWidgets('a parked tab released away from the edges still opens', (
      tester,
    ) async {
      final controller = await _pumpPanel(tester, behavior: behavior);
      controller.stash(PanelEdge.end);
      await tester.pump();

      await _dragTo(tester, const Offset(400, 300));

      expect(controller.phase, PanelPhase.expanded);
    });

    testWidgets('a drag between corners still rests collapsed', (tester) async {
      final controller = await _pumpPanel(tester, behavior: behavior);

      final gesture = await tester.startGesture(_panelRect(tester).center);
      for (var frame = 1; frame <= 8; frame++) {
        await gesture.moveBy(
          const Offset(-60, -40),
          timeStamp: Duration(milliseconds: 16 * frame),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump();

      expect(controller.phase, PanelPhase.collapsed);
    });
  });

  group('a panel with no collapsed stage', () {
    const behavior = PanelBehavior(collapsible: false);

    testWidgets('opens straight out of its tab', (tester) async {
      final controller = await _pumpPanel(tester, behavior: behavior);
      controller.stash();
      await tester.pump();
      expect(controller.phase, PanelPhase.stashed);

      final peek = _paintedRect(tester);
      await tester.tapAt(Offset(peek.left + 4, peek.center.dy));
      await tester.pump();

      expect(controller.phase, PanelPhase.expanded);
      expect(find.byKey(_expandedKey), findsOneWidget);
    });

    testWidgets('parks when it is closed, however it is closed', (
      tester,
    ) async {
      final controller = await _pumpPanel(tester, behavior: behavior);
      controller.expand();
      await tester.pump();
      expect(controller.phase, PanelPhase.expanded);

      controller.collapse();
      await tester.pump();
      expect(controller.phase, PanelPhase.stashed);

      controller.toggle();
      await tester.pump();
      expect(controller.phase, PanelPhase.expanded, reason: 'toggle opens it');

      controller.toggle();
      await tester.pump();
      expect(controller.phase, PanelPhase.stashed, reason: 'toggle parks it');
    });

    testWidgets('a tap outside parks it rather than shrinking it', (
      tester,
    ) async {
      final controller = await _pumpPanel(tester, behavior: behavior);
      controller.expand();
      await tester.pump();

      await tester.tapAt(const Offset(20, 20));
      await tester.pump();

      expect(controller.phase, PanelPhase.stashed);
    });

    testWidgets('the collapsed face never becomes the resting one', (
      tester,
    ) async {
      final seen = <PanelPhase>[];
      final controller = await _pumpPanel(tester, behavior: behavior);
      controller
        ..addListener(() => seen.add(controller.phase))
        ..expand()
        ..collapse()
        ..expand();
      await tester.pumpAndSettle();

      expect(seen, isNot(contains(PanelPhase.collapsed)));
      expect(seen, isNot(contains(PanelPhase.collapsing)));
    });
  });

  group('dismissing', () {
    testWidgets('a hard throw clear of the screen hides the panel', (
      tester,
    ) async {
      final controller = await _pumpPanel(
        tester,
        behavior: const PanelBehavior(dismissible: true, stashable: false),
      );

      final gesture = await tester.startGesture(_panelRect(tester).center);
      for (var frame = 1; frame <= 8; frame++) {
        await gesture.moveBy(
          const Offset(90, 40),
          timeStamp: Duration(milliseconds: 8 * frame),
        );
        await tester.pump(const Duration(milliseconds: 8));
      }
      await gesture.up();
      await tester.pump();

      expect(controller.phase, PanelPhase.hidden);
    });

    testWidgets('the same throw only snaps when not dismissible', (
      tester,
    ) async {
      final controller = await _pumpPanel(
        tester,
        behavior: const PanelBehavior(stashable: false),
      );

      final gesture = await tester.startGesture(_panelRect(tester).center);
      for (var frame = 1; frame <= 8; frame++) {
        await gesture.moveBy(
          const Offset(90, 40),
          timeStamp: Duration(milliseconds: 8 * frame),
        );
        await tester.pump(const Duration(milliseconds: 8));
      }
      await gesture.up();
      await tester.pump();

      expect(controller.phase, PanelPhase.collapsed);
    });

    testWidgets('an ordinary flick towards a corner is not a dismissal', (
      tester,
    ) async {
      final controller = await _pumpPanel(
        tester,
        behavior: const PanelBehavior(dismissible: true, stashable: false),
      );

      final gesture = await tester.startGesture(_panelRect(tester).center);
      for (var frame = 1; frame <= 8; frame++) {
        await gesture.moveBy(
          const Offset(-40, -30),
          timeStamp: Duration(milliseconds: 16 * frame),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump();

      expect(controller.phase, PanelPhase.collapsed);
    });
  });

  group('parking at an edge', () {
    DraggablePanelController stashedController() => DraggablePanelController(
      initialPlacement: const PanelPlacement.stashed(PanelEdge.end),
    );

    Future<void> dragBy(
      WidgetTester tester,
      Offset step, {
      int frames = 8,
    }) async {
      // A parked panel's centre is off screen; grab the sliver that is not.
      final rect = _paintedRect(tester);
      final gesture = await tester.startGesture(
        Offset(rect.center.dx.clamp(8.0, 792.0), rect.center.dy),
      );
      for (var frame = 1; frame <= frames; frame++) {
        await gesture.moveBy(
          step,
          timeStamp: Duration(milliseconds: 16 * frame),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump();
    }

    testWidgets('a parked placement starts parked', (tester) async {
      final controller = stashedController();
      addTearDown(controller.dispose);
      await _pumpPanel(tester, controller: controller);

      expect(controller.phase, PanelPhase.stashed);
      expect(_paintedRect(tester).right, greaterThan(800));
    });

    testWidgets('it parks itself once left alone', (tester) async {
      final controller = await _pumpPanel(
        tester,
        behavior: const PanelBehavior(idleStashDelay: Duration(seconds: 3)),
      );
      expect(controller.phase, PanelPhase.collapsed);

      await tester.pump(const Duration(seconds: 2));
      expect(controller.phase, PanelPhase.collapsed, reason: 'not yet');

      await tester.pump(const Duration(seconds: 2));
      expect(controller.phase, PanelPhase.stashed);
    });

    testWidgets('touching it restarts the wait', (tester) async {
      final controller = await _pumpPanel(
        tester,
        behavior: const PanelBehavior(idleStashDelay: Duration(seconds: 3)),
      );

      await tester.pump(const Duration(seconds: 2));
      final panel = _paintedRect(tester).center;
      await (await tester.startGesture(panel)).up();
      await tester.pump(const Duration(seconds: 2));

      expect(
        controller.phase,
        isNot(PanelPhase.stashed),
        reason: 'the clock restarted when it was touched',
      );
    });

    testWidgets('a null delay leaves it out indefinitely', (tester) async {
      final controller = await _pumpPanel(
        tester,
        behavior: const PanelBehavior(idleStashDelay: null),
      );

      await tester.pump(const Duration(minutes: 5));

      expect(controller.phase, PanelPhase.collapsed);
    });

    testWidgets('touching the page parks it, without eating the touch', (
      tester,
    ) async {
      var pageTaps = 0;
      final controller = DraggablePanelController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: DraggablePanel(
            controller: controller,
            theme: DraggablePanelThemeData(motion: PanelMotionSpec.instant()),
            collapsedBuilder: (context, status) => const SizedBox.shrink(),
            expandedBuilder: (context, status) => const SizedBox.shrink(),
            child: GestureDetector(
              onTap: () => pageTaps++,
              child: const ColoredBox(
                key: _appKey,
                color: Color(0xFFFFFFFF),
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(controller.phase, PanelPhase.collapsed);

      await tester.tapAt(const Offset(80, 80));
      await tester.pump();

      expect(controller.phase, PanelPhase.stashed);
      expect(pageTaps, 1, reason: 'the page still got its own tap');
    });

    testWidgets('an expanded panel crosses the screen without stalling', (
      tester,
    ) async {
      final controller = await _pumpPanel(tester);
      controller.expand();
      await tester.pump();
      expect(controller.phase, PanelPhase.expanded);

      final start = _paintedRect(tester).center;
      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(-40, 0), timeStamp: _at(1));

      final travelled = <double>[];
      var previous = _paintedRect(tester).left;
      for (var frame = 2; frame <= 9; frame++) {
        await gesture.moveBy(const Offset(-40, 0), timeStamp: _at(frame));
        await tester.pump();
        final left = _paintedRect(tester).left;
        travelled.add(previous - left);
        previous = left;
      }
      await gesture.up();

      expect(
        travelled.where((step) => step <= 0.5),
        isEmpty,
        reason: 'the rect stalled while the finger kept moving: $travelled',
      );
    });

    testWidgets('an expanded panel released on the left stays left, even on a '
        'narrow screen', (tester) async {
      tester.view
        ..physicalSize = const Size(393 * 3, 852 * 3)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final controller = await _pumpPanel(tester);
      controller.expand();
      await tester.pump();

      final gesture = await tester.startGesture(_paintedRect(tester).center);
      for (var frame = 1; frame <= 3; frame++) {
        await gesture.moveBy(const Offset(-30, 0), timeStamp: _at(frame));
        await tester.pump();
      }
      final held = _paintedRect(tester);
      expect(held.center.dx, lessThan(393 / 2), reason: 'it is on the left');

      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        _paintedRect(tester).center.dx,
        lessThan(393 / 2),
        reason: 'it flew back across the screen',
      );
    });

    testWidgets('releasing an expanded panel does not teleport it', (
      tester,
    ) async {
      final controller = await _pumpPanel(
        tester,
        theme: DraggablePanelThemeData(motion: PanelMotionSpec()),
      );
      controller.expand();
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(_paintedRect(tester).center);
      for (var frame = 1; frame <= 10; frame++) {
        await gesture.moveBy(const Offset(-45, 0), timeStamp: _at(frame));
        await tester.pump();
      }
      final held = _paintedRect(tester);

      await gesture.up();
      await tester.pump();
      final released = _paintedRect(tester);

      expect(
        (released.left - held.left).abs(),
        lessThan(24),
        reason: 'the rect jumped $held -> $released on the frame after release',
      );

      await tester.pumpAndSettle();
    });

    group('switched off', () {
      const settled = PanelBehavior(stashable: false);

      testWidgets('the idle timer leaves it out', (tester) async {
        final controller = await _pumpPanel(
          tester,
          behavior: const PanelBehavior(
            stashable: false,
            idleStashDelay: Duration(seconds: 1),
          ),
        );

        await tester.pump(const Duration(seconds: 5));

        expect(controller.phase, PanelPhase.collapsed);
      });

      testWidgets('touching the page leaves it out', (tester) async {
        final controller = await _pumpPanel(tester, behavior: settled);

        await tester.tapAt(const Offset(80, 80));
        await tester.pump();

        expect(controller.phase, PanelPhase.collapsed);
      });

      testWidgets('shoving it at the edge only rubber-bands it', (
        tester,
      ) async {
        final controller = await _pumpPanel(tester, behavior: settled);

        await dragBy(tester, const Offset(60, 0));

        expect(controller.phase, PanelPhase.collapsed);
        expect(_paintedRect(tester).right, lessThanOrEqualTo(800));
      });

      testWidgets('stash() is a no-op', (tester) async {
        final controller = await _pumpPanel(tester, behavior: settled);

        controller.stash();
        await tester.pump();

        expect(controller.phase, PanelPhase.collapsed);
        expect(controller.placement, isNot(isA<StashedPlacement>()));
      });

      testWidgets('assistive technology is not offered the action', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _pumpPanel(tester, behavior: settled);

        final actions = tester
            .getSemantics(find.byKey(_collapsedKey))
            .getSemanticsData()
            .customSemanticsActionIds!
            .map(CustomSemanticsAction.getAction)
            .map((action) => action?.label);

        expect(actions, isNot(contains(const PanelSemantics().stashAction)));

        handle.dispose();
      });
    });

    testWidgets('it parks at the side it was dragged to, not the one it '
        'came from', (tester) async {
      final controller = stashedController();
      addTearDown(controller.dispose);
      await _pumpPanel(tester, controller: controller);
      expect(controller.placement, isA<StashedPlacement>());

      await dragBy(tester, const Offset(-90, 0));
      expect(controller.phase, PanelPhase.collapsed);
      expect(_paintedRect(tester).center.dx, lessThan(400));

      await tester.tapAt(const Offset(700, 300));
      await tester.pump();

      expect(
        controller.placement,
        isA<StashedPlacement>().having((p) => p.edge, 'edge', PanelEdge.start),
      );
    });

    testWidgets('touching the panel itself does not park it', (tester) async {
      final controller = await _pumpPanel(tester);

      await tester.tapAt(_paintedRect(tester).center);
      await tester.pump();

      expect(controller.phase, isNot(PanelPhase.stashed));
    });

    testWidgets('the sliver carries a grab affordance', (tester) async {
      final controller = stashedController();
      addTearDown(controller.dispose);
      await _pumpPanel(tester, controller: controller);

      final handle = tester.getRect(find.byType(PanelEdgeHandle));
      expect(
        handle.size,
        const Size(26, 70),
        reason: 'the handle fills only the sliver that stays on screen',
      );
      expect(handle.left, closeTo(_paintedRect(tester).left, 0.5));
      expect(handle.right, closeTo(800, 0.5));
    });

    testWidgets('a custom handleBuilder replaces the default', (tester) async {
      final controller = stashedController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: DraggablePanel(
            controller: controller,
            theme: DraggablePanelThemeData(motion: PanelMotionSpec.instant()),
            handleBuilder: (context, edge) =>
                Text(edge.name, key: const Key('custom-handle')),
            collapsedBuilder: (context, status) => const SizedBox.shrink(),
            expandedBuilder: (context, status) => const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PanelEdgeHandle), findsNothing);
      expect(find.byKey(const Key('custom-handle')), findsOneWidget);
      expect(find.text('end'), findsOneWidget);
    });

    testWidgets('exactly the peek shows, no more', (tester) async {
      final controller = stashedController();
      addTearDown(controller.dispose);
      await _pumpPanel(
        tester,
        controller: controller,
        theme: const DraggablePanelThemeData(
          stashedPeek: 14,
          margin: EdgeInsets.all(24),
        ),
      );

      expect(
        800 - _paintedRect(tester).left,
        closeTo(14, 0.5),
        reason: 'the resting margin must not widen the parked sliver',
      );
    });

    testWidgets('the tab keeps its height, it does not sink to a corner', (
      tester,
    ) async {
      final controller = stashedController();
      addTearDown(controller.dispose);
      await _pumpPanel(tester, controller: controller);

      expect(
        _panelRect(tester).center.dy,
        closeTo(300, 1),
        reason: 'a centred tab must sit at the middle of the screen',
      );
    });

    testWidgets('dragging it inward brings it back on screen', (tester) async {
      final controller = stashedController();
      addTearDown(controller.dispose);
      await _pumpPanel(tester, controller: controller);

      await dragBy(tester, const Offset(-40, 0));

      expect(controller.phase, PanelPhase.collapsed);
      expect(_paintedRect(tester).right, lessThanOrEqualTo(800));
    });

    testWidgets('dragging it back against the edge parks it again', (
      tester,
    ) async {
      final controller = await _pumpPanel(tester);
      expect(controller.phase, PanelPhase.collapsed);

      await dragBy(tester, const Offset(40, 0));

      expect(controller.phase, PanelPhase.stashed);
    });

    testWidgets('a parked panel travels without drifting vertically', (
      tester,
    ) async {
      final controller = stashedController();
      addTearDown(controller.dispose);
      await _pumpPanel(tester, controller: controller);

      final start = _panelRect(tester);
      final gesture = await tester.startGesture(start.center);

      for (var frame = 1; frame <= 6; frame++) {
        await gesture.moveBy(
          const Offset(-30, 0),
          timeStamp: Duration(milliseconds: 16 * frame),
        );
        await tester.pump(const Duration(milliseconds: 16));

        expect(_panelRect(tester).center.dy, closeTo(start.center.dy, 1));
      }

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('an expanded panel keeps its content while it travels', (
      tester,
    ) async {
      final controller = await _pumpPanel(tester)
        ..expand();
      await tester.pump();
      expect(controller.phase, PanelPhase.expanded);

      await dragBy(tester, const Offset(-30, -20));

      expect(
        controller.phase,
        PanelPhase.expanded,
        reason: 'moving a window must not close it',
      );
      expect(
        tester.getRect(find.byKey(_expandedKey)).size,
        const Size(280, 200),
      );
    });
  });

  group('viewport changes', () {
    testWidgets('a resize keeps the corner and re-places the panel', (
      tester,
    ) async {
      final controller = await _pumpPanel(tester);
      addTearDown(tester.view.reset);

      expect(_panelRect(tester).right, closeTo(784, 0.5));

      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(400, 900);
      await tester.pump();
      await tester.pump();

      expect(
        controller.placement,
        const PanelPlacement.corner(PanelCorner.bottomEnd),
      );
      expect(_panelRect(tester).right, closeTo(384, 0.5));
      expect(_panelRect(tester).bottom, closeTo(884, 0.5));
    });
  });

  group('reduced motion', () {
    testWidgets('the panel snaps into place but still cross-fades', (
      tester,
    ) async {
      final controller = await _pumpPanel(
        tester,
        theme: const DraggablePanelThemeData(),
        disableAnimations: true,
      );

      controller.expand();
      await tester.pump();

      expect(controller.phase, PanelPhase.expanding);
      expect(
        tester.getRect(find.byKey(_expandedKey)).size,
        const Size(280, 200),
        reason: 'geometry is already final while the content fades',
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.phase, PanelPhase.expanded);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('controller commands', () {
    testWidgets('hide and show round-trip', (tester) async {
      final controller = await _pumpPanel(tester);

      controller.hide();
      await tester.pump();
      expect(controller.phase, PanelPhase.hidden);

      controller.show();
      await tester.pump();
      expect(controller.phase, PanelPhase.collapsed);
    });

    testWidgets('moveTo keeps an expanded panel expanded', (tester) async {
      final controller = await _pumpPanel(tester)
        ..expand();
      await tester.pump();
      expect(controller.phase, PanelPhase.expanded);

      controller.moveTo(const PanelPlacement.corner(PanelCorner.topStart));
      await tester.pump();

      expect(controller.phase, PanelPhase.expanded);

      final rect = tester.getRect(find.byKey(_expandedKey));
      expect(rect.size, const Size(280, 200));
      expect(rect.left, closeTo(16, 0.5));
      expect(rect.top, closeTo(16, 0.5));
    });

    testWidgets('moveTo relocates without expanding', (tester) async {
      final controller = await _pumpPanel(tester)
        ..moveTo(const PanelPlacement.corner(PanelCorner.topEnd));
      await tester.pump();

      expect(controller.phase, PanelPhase.collapsed);
      expect(_panelRect(tester).top, closeTo(16, 0.5));
      expect(_panelRect(tester).right, closeTo(784, 0.5));
    });
  });
}
