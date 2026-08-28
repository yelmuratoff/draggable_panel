import 'package:draggable_panel/draggable_panel.dart';
import 'package:draggable_panel_example/main.dart';
import 'package:draggable_panel_example/mini_player_demo.dart';
import 'package:draggable_panel_example/tab_panel_demo.dart';
import 'package:draggable_panel_example/theming_demo.dart';
import 'package:draggable_panel_example/tools_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the demos against layout errors that only show up when run.
///
/// An overflowing panel throws during layout rather than failing an assertion,
/// so nothing but pumping the real screens catches it.
Future<void> _pumpDemo(WidgetTester tester, Widget demo) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: demo,
    ),
  );
  await tester.pumpAndSettle();
}

/// The panel's controller, read from the scope it publishes.
///
/// `DraggablePanelScope.of` deliberately only reaches down from panel content,
/// so a test driving the panel from outside reads the scope widget instead.
DraggablePanelController _controllerOf(WidgetTester tester) => tester
    .widget<DraggablePanelScope>(find.byType(DraggablePanelScope))
    .controller;

void main() {
  final demos = <String, Widget Function()>{
    'mini player': MiniPlayerDemo.new,
    'developer tools': ToolsDemo.new,
    'tab panel': TabPanelDemo.new,
    'theming playground': ThemingDemo.new,
  };

  for (final MapEntry(key: name, value: build) in demos.entries) {
    group(name, () {
      testWidgets('lays out collapsed without overflowing', (tester) async {
        await _pumpDemo(tester, build());

        expect(tester.takeException(), isNull);
      });

      testWidgets('lays out expanded without overflowing', (tester) async {
        await _pumpDemo(tester, build());

        _controllerOf(tester).expand();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('survives a doubled text scale while expanded', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(colorSchemeSeed: Colors.indigo),
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: build(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        _controllerOf(tester).expand();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });
  }

  group('home screen', () {
    testWidgets('lists every demo', (tester) async {
      await tester.pumpWidget(const ExampleApp());
      await tester.pumpAndSettle();

      expect(find.text('Mini player'), findsOneWidget);
      expect(find.text('Developer tools'), findsOneWidget);
      expect(find.text('Tab panel'), findsOneWidget);
      expect(find.text('Theming playground'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
