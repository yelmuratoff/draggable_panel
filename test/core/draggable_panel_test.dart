import 'package:draggable_panel/draggable_panel.dart';
import 'package:draggable_panel/src/core/panel_surface.dart';
import 'package:draggable_panel/src/core/render_panel_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

Rect _panelRect(WidgetTester tester) =>
    tester.getRect(find.byKey(_collapsedKey));

/// The rect the panel surface actually painted, tab included.
Rect _paintedRect(WidgetTester tester) => tester
    .renderObject<RenderPanelSurface>(find.byType(PanelSurface))
    .paintedRect;

void main() {
  group('layout', () {
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
