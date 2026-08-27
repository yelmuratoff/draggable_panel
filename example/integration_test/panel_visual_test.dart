import 'package:draggable_panel/draggable_panel.dart';
import 'package:draggable_panel_example/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Drives the parked panel on a real device and photographs each step.
///
/// Widget tests and goldens cannot judge whether the tab reads as something to
/// grab against a real app background; these frames can.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shoot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    await binding.takeScreenshot(name);
  }

  testWidgets('the parked tab, and pulling it out', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Developer tools'));
    await tester.pumpAndSettle();
    await shoot(tester, '01-parked-light');

    final handle = find.byType(PanelEdgeHandle);
    expect(handle, findsOneWidget);

    final grip = tester.getCenter(handle);
    final gesture = await tester.startGesture(grip);

    // Past the halved pan slop, so the panel is under the finger from here on.
    await gesture.moveBy(const Offset(-19, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await binding.takeScreenshot('02-drag-registers');

    for (final (index, step) in [6.0, 6.0, 8.0].indexed) {
      await gesture.moveBy(Offset(-step, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await binding.takeScreenshot('0${3 + index}-pulled');
    }

    await gesture.up();
    await shoot(tester, '05-released');
  });

  testWidgets('touching the page puts a drawn-out panel away', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Developer tools'));
    await tester.pumpAndSettle();

    await tester.tapAt(tester.getCenter(find.byType(PanelEdgeHandle)));
    await tester.pumpAndSettle();
    expect(find.byType(PanelEdgeHandle), findsOneWidget);
    await binding.takeScreenshot('07-drawn-out');

    await tester.tapAt(const Offset(120, 300));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('08-parked-again');
  });

  testWidgets('the parked tab in dark mode', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.brightness_6_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Developer tools'));
    await tester.pumpAndSettle();

    await shoot(tester, '06-parked-dark');
  });
}
