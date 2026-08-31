import 'package:draggable_panel/draggable_panel.dart';
import 'package:draggable_panel/src/core/panel_surface.dart';
import 'package:draggable_panel/src/core/render_panel_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _headerKey = ValueKey('header');
const _listKey = ValueKey('list');
const _collapsedKey = ValueKey('collapsed');

/// An expanded panel holding more than it can show: a header over a list that
/// scrolls. [withDragArea] is the only difference between the two panels under
/// test, so every assertion below is about the area and nothing else.
Future<DraggablePanelController> _pumpPanel(
  WidgetTester tester, {
  required bool withDragArea,
  required ScrollController scroll,
  PanelMotionSpec? motion,
}) async {
  final controller = DraggablePanelController();
  addTearDown(controller.dispose);

  const header = SizedBox(
    key: _headerKey,
    height: 40,
    child: ColoredBox(color: Color(0xFF223344)),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: DraggablePanel(
        controller: controller,
        theme: DraggablePanelThemeData(
          motion: motion ?? PanelMotionSpec.instant(),
        ),
        collapsedBuilder: (context, status) =>
            const ColoredBox(key: _collapsedKey, color: Color(0xFF112233)),
        expandedBuilder: (context, status) => SizedBox(
          width: 280,
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (withDragArea) const PanelDragArea(child: header) else header,
              Expanded(
                child: ListView.builder(
                  key: _listKey,
                  controller: scroll,
                  itemCount: 40,
                  itemExtent: 40,
                  itemBuilder: (context, index) =>
                      ColoredBox(color: Color(0xFF000000 + index)),
                ),
              ),
            ],
          ),
        ),
        child: const ColoredBox(color: Color(0xFFFFFFFF)),
      ),
    ),
  );
  await tester.pump();
  return controller;
}

RenderPanelSurface _surface(WidgetTester tester) =>
    tester.renderObject<RenderPanelSurface>(find.byType(PanelSurface));

Rect _paintedRect(WidgetTester tester) => _surface(tester).paintedRect;

/// Whether a drag from [start] was taken by the panel rather than its content.
///
/// Read off the surface mid-gesture, because where the panel *ends up* also
/// carries whatever the rest of its motion was doing at the time.
Future<bool> _tookDrag(WidgetTester tester, Offset start, Offset delta) async {
  final gesture = await tester.startGesture(start);
  const steps = 20;
  for (var step = 1; step <= steps; step++) {
    await gesture.moveTo(
      start + delta * (step / steps),
      timeStamp: Duration(milliseconds: 16 * step),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }

  final dragging = _surface(tester).isDragging;
  await gesture.up();
  await tester.pump();
  return dragging;
}

/// Drags [delta] from [start] and reports where the panel sat at the end of it.
///
/// Measured before the release, because a released panel springs to its
/// placement and would hide whether the drag moved it at all.
Future<Offset> _dragBy(WidgetTester tester, Offset start, Offset delta) async {
  final gesture = await tester.startGesture(start);
  const steps = 20;
  for (var step = 1; step <= steps; step++) {
    await gesture.moveTo(
      start + delta * (step / steps),
      timeStamp: Duration(milliseconds: 16 * step),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }

  final origin = _paintedRect(tester).topLeft;
  await gesture.up();
  await tester.pump();
  return origin;
}

void main() {
  group('an expanded panel whose content declares a drag area', () {
    testWidgets('leaves a swipe on the content to the list', (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final controller = await _pumpPanel(
        tester,
        withDragArea: true,
        scroll: scroll,
      );
      controller.expand();
      await tester.pump();

      final before = _paintedRect(tester).topLeft;
      final after = await _dragBy(
        tester,
        tester.getRect(find.byKey(_listKey)).center,
        const Offset(14, -60),
      );

      expect(scroll.offset, greaterThan(0), reason: 'the list scrolled');
      expect(after, before, reason: 'the panel stayed where it was');
    });

    testWidgets('keeps the content even when the swipe runs across it', (
      tester,
    ) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final controller = await _pumpPanel(
        tester,
        withDragArea: true,
        scroll: scroll,
      );
      controller.expand();
      await tester.pump();

      final before = _paintedRect(tester).topLeft;
      final after = await _dragBy(
        tester,
        tester.getRect(find.byKey(_listKey)).center,
        const Offset(-60, 0),
      );

      expect(
        after,
        before,
        reason: 'a drag the list cannot use is still not the panel to take',
      );
    });

    testWidgets('moves on a drag that starts inside the area', (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final controller = await _pumpPanel(
        tester,
        withDragArea: true,
        scroll: scroll,
      );
      controller.expand();
      await tester.pump();

      final before = _paintedRect(tester).topLeft;
      final after = await _dragBy(
        tester,
        tester.getRect(find.byKey(_headerKey)).center,
        const Offset(-60, 0),
      );

      expect(after.dx, lessThan(before.dx), reason: 'the panel followed');
      expect(scroll.offset, 0, reason: 'the list stayed put');
    });

    testWidgets('is still grabbed anywhere while it is growing', (
      tester,
    ) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final controller = await _pumpPanel(
        tester,
        withDragArea: true,
        scroll: scroll,
        motion: PanelMotionSpec(),
      );
      controller.expand();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 32));
      expect(controller.phase, PanelPhase.expanding);

      final took = await _tookDrag(
        tester,
        _paintedRect(tester).center,
        const Offset(-60, 0),
      );

      expect(
        took,
        isTrue,
        reason: 'the area is already at its final place, the panel is not',
      );
    });

    testWidgets('leaves a tap outside the area to the content', (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final controller = await _pumpPanel(
        tester,
        withDragArea: true,
        scroll: scroll,
      );
      controller.expand();
      await tester.pump();

      await tester.tapAt(tester.getRect(find.byKey(_listKey)).center);
      await tester.pump();

      expect(controller.phase, PanelPhase.expanded);
    });

    testWidgets('still drags from anywhere while collapsed', (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await _pumpPanel(tester, withDragArea: true, scroll: scroll);

      final before = _paintedRect(tester).topLeft;
      final after = await _dragBy(
        tester,
        tester.getRect(find.byKey(_collapsedKey)).center,
        const Offset(-60, 0),
      );

      expect(after.dx, lessThan(before.dx));
    });
  });

  group('an expanded panel whose content declares none', () {
    testWidgets('takes a drag the content cannot use', (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final controller = await _pumpPanel(
        tester,
        withDragArea: false,
        scroll: scroll,
      );
      controller.expand();
      await tester.pump();

      final before = _paintedRect(tester).topLeft;
      final after = await _dragBy(
        tester,
        tester.getRect(find.byKey(_listKey)).center,
        const Offset(-60, 0),
      );

      expect(after.dx, lessThan(before.dx));
    });

    testWidgets('lets a scrollable win a swipe that leans off its axis', (
      tester,
    ) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final controller = await _pumpPanel(
        tester,
        withDragArea: false,
        scroll: scroll,
      );
      controller.expand();
      await tester.pump();

      final before = _paintedRect(tester).topLeft;
      final after = await _dragBy(
        tester,
        tester.getRect(find.byKey(_listKey)).center,
        const Offset(14, -60),
      );

      expect(
        scroll.offset,
        greaterThan(0),
        reason: 'no real finger swipes on a perfect axis',
      );
      expect(after, before);
    });
  });
}
