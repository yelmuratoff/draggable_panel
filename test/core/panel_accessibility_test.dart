import 'package:draggable_panel/draggable_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _collapsedKey = ValueKey('collapsed');
const _expandedKey = ValueKey('expanded');

Future<DraggablePanelController> _pumpPanel(
  WidgetTester tester, {
  PanelBehavior behavior = const PanelBehavior(),
  PanelSemantics semantics = const PanelSemantics(),
  bool accessibleNavigation = false,
  DraggablePanelController? controller,
}) async {
  final panelController = controller ?? DraggablePanelController();
  if (controller == null) addTearDown(panelController.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(accessibleNavigation: accessibleNavigation),
          child: DraggablePanel(
            controller: panelController,
            behavior: behavior,
            semantics: semantics,
            theme: DraggablePanelThemeData(motion: PanelMotionSpec.instant()),
            collapsedBuilder: (context, status) =>
                const ColoredBox(key: _collapsedKey, color: Color(0xFF112233)),
            expandedBuilder: (context, status) => const SizedBox(
              key: _expandedKey,
              width: 280,
              height: 200,
              child: ColoredBox(color: Color(0xFF445566)),
            ),
            child: const ColoredBox(color: Color(0xFFFFFFFF)),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return panelController;
}

void main() {
  group('guidelines', () {
    testWidgets('meets tap target and contrast guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpPanel(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      handle.dispose();
    });

    testWidgets('a tiny collapsed size is still a legal tap target', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: DraggablePanel(
            theme: DraggablePanelThemeData(
              collapsedSize: const Size(12, 12),
              motion: PanelMotionSpec.instant(),
            ),
            collapsedBuilder: (context, status) =>
                const ColoredBox(color: Color(0xFF112233)),
            expandedBuilder: (context, status) =>
                const SizedBox(width: 200, height: 100),
            child: const ColoredBox(color: Color(0xFFFFFFFF)),
          ),
        ),
      );
      await tester.pump();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });

  group('semantics tree', () {
    testWidgets('the collapsed panel is a labelled button', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpPanel(
        tester,
        semantics: const PanelSemantics(label: 'Now playing'),
      );

      expect(
        tester.getSemantics(find.byKey(_collapsedKey)),
        matchesSemantics(
          label: 'Now playing',
          hint: 'Expand the panel',
          isButton: true,
          hasTapAction: true,
          customActions: const <CustomSemanticsAction>[
            CustomSemanticsAction(label: 'Park at the edge'),
            CustomSemanticsAction(label: 'Move to top start'),
            CustomSemanticsAction(label: 'Move to top end'),
            CustomSemanticsAction(label: 'Move to bottom start'),
          ],
        ),
      );
      handle.dispose();
    });

    testWidgets('an expanded panel offers a dismiss action', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = await _pumpPanel(tester);
      controller.expand();
      await tester.pump();

      final node = tester.getSemantics(find.byKey(_expandedKey));
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.dismiss),
        isTrue,
      );
      expect(node.label, 'Floating panel');

      handle.dispose();
    });

    testWidgets('a stashed panel offers only the way back', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = await _pumpPanel(tester);
      controller.stash();
      await tester.pump();

      final node = tester.getSemantics(find.byKey(_collapsedKey));
      final labels = node
          .getSemanticsData()
          .customSemanticsActionIds!
          .map((id) => CustomSemanticsAction.getAction(id)!.label)
          .toList();

      expect(labels, ['Bring back on screen']);
      handle.dispose();
    });

    testWidgets('custom action labels are localizable', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpPanel(
        tester,
        semantics: const PanelSemantics(
          stashAction: 'Убрать к краю',
          moveActionPrefix: 'Переместить в',
          topStartName: 'верхний левый',
        ),
      );

      final node = tester.getSemantics(find.byKey(_collapsedKey));
      final labels = node
          .getSemanticsData()
          .customSemanticsActionIds!
          .map((id) => CustomSemanticsAction.getAction(id)!.label)
          .toList();

      expect(labels, contains('Убрать к краю'));
      expect(labels, contains('Переместить в верхний левый'));
      handle.dispose();
    });
  });

  group('assistive navigation', () {
    testWidgets('free dragging is disabled while a screen reader drives', (
      tester,
    ) async {
      final controller = await _pumpPanel(tester, accessibleNavigation: true);
      final before = tester.getRect(find.byKey(_collapsedKey));

      final gesture = await tester.startGesture(before.center);
      await gesture.moveBy(const Offset(-200, -200));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(tester.getRect(find.byKey(_collapsedKey)), before);
      expect(controller.phase, PanelPhase.collapsed);
    });

    testWidgets('the custom move action still relocates the panel', (
      tester,
    ) async {
      final controller = await _pumpPanel(tester, accessibleNavigation: true);

      controller.moveTo(const PanelPlacement.corner(PanelCorner.topStart));
      await tester.pump();

      expect(tester.getRect(find.byKey(_collapsedKey)).left, closeTo(16, 0.5));
    });
  });

  group('keyboard', () {
    /// The panel is reached by tab like any other control, so key handling only
    /// applies once it holds focus.
    Future<void> focusPanel(WidgetTester tester) async {
      Focus.of(tester.element(find.byKey(_collapsedKey))).requestFocus();
      await tester.pump();
    }

    testWidgets('arrow keys walk the panel between corners', (tester) async {
      final controller = await _pumpPanel(tester);
      await focusPanel(tester);
      expect(
        controller.placement,
        const PanelPlacement.corner(PanelCorner.bottomEnd),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(
        controller.placement,
        const PanelPlacement.corner(PanelCorner.topEnd),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(
        controller.placement,
        const PanelPlacement.corner(PanelCorner.topStart),
      );
    });

    testWidgets('an arrow into a wall does nothing', (tester) async {
      final controller = await _pumpPanel(tester);
      await focusPanel(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(
        controller.placement,
        const PanelPlacement.corner(PanelCorner.bottomEnd),
      );
    });

    testWidgets("an arrow inside the panel's own content is left alone", (
      tester,
    ) async {
      final controller = DraggablePanelController();
      addTearDown(controller.dispose);
      final field = TextEditingController(text: 'hello world');
      addTearDown(field.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: DraggablePanel(
            controller: controller,
            theme: DraggablePanelThemeData(motion: PanelMotionSpec.instant()),
            collapsedBuilder: (context, status) =>
                const ColoredBox(key: _collapsedKey, color: Color(0xFF112233)),
            expandedBuilder: (context, status) => SizedBox(
              key: _expandedKey,
              width: 280,
              height: 200,
              child: TextField(controller: field),
            ),
            child: const ColoredBox(color: Color(0xFFFFFFFF)),
          ),
        ),
      );
      await tester.pump();

      controller.expand();
      await tester.pump();
      await tester.tap(find.byType(TextField));
      await tester.pump();
      field.selection = const TextSelection.collapsed(offset: 5);
      await tester.pump();

      final placement = controller.placement;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      expect(
        field.selection.baseOffset,
        4,
        reason: 'the caret should move, not the panel',
      );
      expect(controller.placement, placement);
    });

    testWidgets('escape collapses an expanded panel', (tester) async {
      final controller = await _pumpPanel(tester);
      await focusPanel(tester);
      controller.expand();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(controller.phase, PanelPhase.collapsed);
    });
  });
}
