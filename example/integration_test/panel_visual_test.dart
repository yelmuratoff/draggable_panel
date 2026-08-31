import 'package:draggable_panel/draggable_panel.dart';
import 'package:draggable_panel/src/core/panel_surface.dart';
import 'package:draggable_panel/src/core/render_panel_surface.dart';
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

  Rect paintedRect(WidgetTester tester) => tester
      .renderObject<RenderPanelSurface>(find.byType(PanelSurface))
      .paintedRect;

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

  testWidgets('the default collapsed face', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Developer tools'));
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.byType(PanelEdgeHandle)));
    await tester.pumpAndSettle();

    await binding.takeScreenshot('14-default-icon');
  });

  testWidgets('the expanded action grid', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Developer tools'));
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.byType(PanelEdgeHandle)));
    await tester.pumpAndSettle();
    await tester.tapAt(
      tester.getCenter(find.byIcon(Icons.zoom_out_map_rounded)),
    );
    await tester.pumpAndSettle();

    await binding.takeScreenshot('09-expanded-grid');
  });

  testWidgets('an expanded panel crossing to the other side', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Developer tools'));
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.byType(PanelEdgeHandle)));
    await tester.pumpAndSettle();
    await tester.tapAt(
      tester.getCenter(find.byIcon(Icons.zoom_out_map_rounded)),
    );
    await tester.pumpAndSettle();

    final grip = tester.getCenter(find.text('Developer tools').last);
    final gesture = await tester.startGesture(grip);
    for (var frame = 1; frame <= 8; frame++) {
      await gesture.moveBy(
        const Offset(-40, 0),
        timeStamp: Duration(milliseconds: 16 * frame),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    await binding.takeScreenshot('10-crossing-held');

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 16));
    await binding.takeScreenshot('11-crossing-released');

    await tester.pumpAndSettle();
    await binding.takeScreenshot('12-crossing-settled');
  });

  testWidgets('parking switched off keeps the panel out', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Theming playground'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stash off the edge'));
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.byType(PanelEdgeHandle)));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 9));
    await tester.tapAt(const Offset(120, 260));
    await tester.pumpAndSettle();

    await binding.takeScreenshot('13-parking-off');
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

  /// Carries the tab to [targetX] and comes to a stop before letting go, so the
  /// velocity tracker reports a deliberate move rather than a flick.
  Future<void> dragTabTo(WidgetTester tester, double targetX) async {
    final grip = tester.getCenter(find.byType(PanelEdgeHandle));
    final gesture = await tester.startGesture(grip);
    var frame = 0;

    Future<void> moveTo(double x) async {
      frame++;
      await gesture.moveTo(
        Offset(x, grip.dy),
        timeStamp: Duration(milliseconds: 16 * frame),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }

    for (var step = 1; step <= 12; step++) {
      await moveTo(grip.dx + (targetX - grip.dx) * step / 12);
    }
    for (var still = 0; still < 6; still++) {
      await moveTo(targetX);
    }

    await gesture.up();
    await tester.pumpAndSettle();
  }

  for (final demo in const ['Quick open', 'Tab panel']) {
    testWidgets('$demo: a tab dragged to the far edge parks there', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text(demo));
      await tester.pumpAndSettle();

      final width = tester.getSize(find.byType(MaterialApp)).width;
      await dragTabTo(tester, 8);
      await binding.takeScreenshot('15-$demo-parked-far-edge');

      final rect = paintedRect(tester);
      expect(
        rect.width,
        lessThan(100),
        reason: 'moving a tab across is not asking to open it',
      );
      expect(rect.center.dx, lessThan(width / 2));
    });

    testWidgets('$demo: a tab released away from the edges opens', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text(demo));
      await tester.pumpAndSettle();

      final width = tester.getSize(find.byType(MaterialApp)).width;
      await dragTabTo(tester, width / 2);
      await binding.takeScreenshot('16-$demo-opened-mid-screen');

      expect(
        paintedRect(tester).width,
        greaterThan(200),
        reason: 'pulled clear of both edges, it should have opened',
      );
    });
  }

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
