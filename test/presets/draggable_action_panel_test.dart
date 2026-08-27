import 'package:draggable_panel/draggable_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<DraggablePanelController> _pumpActionPanel(
  WidgetTester tester, {
  required List<PanelAction> actions,
  List<PanelActionButton> buttons = const [],
  DraggableActionPanelThemeData? actionTheme,
  String? title,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final controller = DraggablePanelController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: DraggableActionPanel(
            controller: controller,
            actions: actions,
            buttons: buttons,
            actionTheme: actionTheme,
            title: title,
            theme: DraggablePanelThemeData(motion: PanelMotionSpec.instant()),
            child: const ColoredBox(color: Color(0xFFFFFFFF)),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return controller;
}

List<PanelAction> _actions(int count, {void Function(int)? onPressed}) => [
  for (var index = 0; index < count; index++)
    PanelAction(
      icon: Icons.circle,
      tooltip: 'Action $index',
      onPressed: () => onPressed?.call(index),
    ),
];

void main() {
  group('grid layout', () {
    testWidgets('renders every action', (tester) async {
      final controller = await _pumpActionPanel(tester, actions: _actions(6));
      controller.expand();
      await tester.pump();

      expect(find.byType(ActionCell), findsNWidgets(6));
    });

    testWidgets('expanded content is built while collapsed but hidden from '
        'assistive technology', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpActionPanel(tester, actions: _actions(6));

      expect(find.byType(ActionCell), findsNWidgets(6));
      expect(
        find.bySemanticsLabel('Action 0'),
        findsNothing,
        reason: 'a collapsed panel must not expose its expanded controls',
      );

      handle.dispose();
    });

    testWidgets('balances the last row instead of leaving it near-empty', (
      tester,
    ) async {
      final controller = await _pumpActionPanel(tester, actions: _actions(5));
      controller.expand();
      await tester.pump();

      final rows = <double>{
        for (final cell in tester.widgetList<ActionCell>(
          find.byType(ActionCell),
        ))
          tester.getTopLeft(find.byWidget(cell)).dy,
      };
      final firstRow = tester
          .widgetList<ActionCell>(find.byType(ActionCell))
          .where(
            (cell) =>
                tester.getTopLeft(find.byWidget(cell)).dy ==
                rows.reduce((a, b) => a < b ? a : b),
          )
          .length;

      expect(rows.length, 2);
      expect(firstRow, 3, reason: 'five actions read better as 3 + 2');
    });

    testWidgets('a single short row is not split', (tester) async {
      final controller = await _pumpActionPanel(tester, actions: _actions(3));
      controller.expand();
      await tester.pump();

      final tops = <double>{
        for (final cell in tester.widgetList<ActionCell>(
          find.byType(ActionCell),
        ))
          tester.getTopLeft(find.byWidget(cell)).dy,
      };

      expect(tops.length, 1);
    });
  });

  group('interaction', () {
    testWidgets('tapping an action runs it', (tester) async {
      final pressed = <int>[];
      final controller = await _pumpActionPanel(
        tester,
        actions: _actions(3, onPressed: pressed.add),
      );
      controller.expand();
      await tester.pump();

      await tester.tap(find.byType(ActionCell).at(1));
      await tester.pump();

      expect(pressed, [1]);
    });

    testWidgets('tapping a button runs it', (tester) async {
      var pressed = 0;
      final controller = await _pumpActionPanel(
        tester,
        actions: _actions(2),
        buttons: [
          PanelActionButton(
            icon: Icons.share,
            label: 'Share',
            onPressed: () => pressed++,
          ),
        ],
      );
      controller.expand();
      await tester.pump();

      await tester.tap(find.text('Share'));
      await tester.pump();

      expect(pressed, 1);
    });

    testWidgets('the collapsed face is still tappable to expand', (
      tester,
    ) async {
      final controller = await _pumpActionPanel(tester, actions: _actions(3));

      await tester.tap(find.byIcon(Icons.apps));
      await tester.pump();

      expect(controller.phase, PanelPhase.expanded);
    });
  });

  group('presentation', () {
    testWidgets('a badge is drawn over its action', (tester) async {
      final controller = await _pumpActionPanel(
        tester,
        actions: [
          PanelAction(
            icon: Icons.mail,
            badge: const PanelBadge(label: '3'),
            onPressed: () {},
          ),
        ],
      );
      controller.expand();
      await tester.pump();

      expect(find.byType(Badge), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('the action theme retunes the grid', (tester) async {
      final controller = await _pumpActionPanel(
        tester,
        actions: _actions(3),
        actionTheme: const DraggableActionPanelThemeData(actionSize: 64),
      );
      controller.expand();
      await tester.pump();

      expect(tester.getSize(find.byType(ActionCell).first).height, 64);
    });

    testWidgets('cells share the row evenly, leaving no trailing gap', (
      tester,
    ) async {
      final controller = await _pumpActionPanel(tester, actions: _actions(4));
      controller.expand();
      await tester.pump();

      final cells = [
        for (var i = 0; i < 4; i++)
          tester.getRect(find.byType(ActionCell).at(i)),
      ];
      final content = tester.getRect(find.byType(ActionPanelContent));

      final step = cells[1].center.dx - cells[0].center.dx;
      for (var i = 1; i < cells.length; i++) {
        expect(
          cells[i].center.dx - cells[i - 1].center.dx,
          closeTo(step, 0.5),
          reason: 'columns are evenly pitched',
        );
      }
      expect(
        content.right - cells.last.center.dx,
        closeTo(cells.first.center.dx - content.left, 0.5),
        reason: 'the grid is balanced, so no slack piles up at its end',
      );
    });

    testWidgets('a panel of two actions is not four columns wide', (
      tester,
    ) async {
      final two = await _pumpActionPanel(tester, actions: _actions(2));
      two.expand();
      await tester.pump();
      final narrow = tester.getSize(find.byType(ActionPanelContent)).width;

      final four = await _pumpActionPanel(tester, actions: _actions(4));
      four.expand();
      await tester.pump();
      final wide = tester.getSize(find.byType(ActionPanelContent)).width;

      expect(narrow, lessThan(wide));
    });

    testWidgets('one long label cannot stretch the whole panel', (
      tester,
    ) async {
      Future<double> widthWithLabel(String label) async {
        final controller = DraggablePanelController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: DraggableActionPanel(
              controller: controller,
              theme: DraggablePanelThemeData(motion: PanelMotionSpec.instant()),
              actions: [
                PanelAction(icon: Icons.circle, label: label, onPressed: () {}),
                PanelAction(icon: Icons.circle, label: 'Ok', onPressed: () {}),
              ],
              child: const ColoredBox(color: Color(0xFFFFFFFF)),
            ),
          ),
        );
        controller.expand();
        await tester.pump();
        return tester.getSize(find.byType(ActionPanelContent)).width;
      }

      final short = await widthWithLabel('Logs');
      final absurd = await widthWithLabel(
        'Network diagnostics and connectivity',
      );

      expect(
        absurd,
        lessThanOrEqualTo(short + 96 * 2),
        reason: 'a column is capped at twice the tile, not at the label',
      );
    });

    testWidgets('there is no header until one is asked for', (tester) async {
      final controller = await _pumpActionPanel(tester, actions: _actions(3));
      controller.expand();
      await tester.pump();

      expect(find.byType(ActionPanelHeader), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('a title alone raises a header, with no close control', (
      tester,
    ) async {
      final controller = await _pumpActionPanel(
        tester,
        actions: _actions(3),
        title: 'Tools',
      );
      controller.expand();
      await tester.pump();

      expect(find.text('Tools'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('a close control alone raises a header, and collapses', (
      tester,
    ) async {
      final controller = await _pumpActionPanel(tester, actions: _actions(3));
      controller.expand();
      await tester.pump();

      await tester.pumpWidget(
        MaterialApp(
          home: DraggableActionPanel(
            controller: controller,
            actions: _actions(3),
            onClose: controller.collapse,
            theme: DraggablePanelThemeData(motion: PanelMotionSpec.instant()),
            child: const ColoredBox(color: Color(0xFFFFFFFF)),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(controller.phase, PanelPhase.collapsed);
    });

    testWidgets('the tile keeps a 48-pixel tap target', (tester) async {
      final controller = await _pumpActionPanel(tester, actions: _actions(3));
      controller.expand();
      await tester.pump();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('each action carries its tooltip as an accessible name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final controller = await _pumpActionPanel(tester, actions: _actions(2));
      controller.expand();
      await tester.pump();

      expect(find.bySemanticsLabel('Action 0'), findsOneWidget);
      expect(find.bySemanticsLabel('Action 1'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('survives a doubled text scale without overflowing', (
      tester,
    ) async {
      final controller = await _pumpActionPanel(
        tester,
        actions: _actions(6),
        buttons: [
          PanelActionButton(
            icon: Icons.share,
            label: 'Share this somewhere',
            onPressed: () {},
          ),
        ],
        textScaler: const TextScaler.linear(2),
      );
      controller.expand();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
