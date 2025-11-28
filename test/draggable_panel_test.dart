import 'package:draggable_panel/draggable_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DraggablePanel', () {
    testWidgets('renders correctly with default theme', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DraggablePanel(
              child: SizedBox(),
            ),
          ),
        ),
      );

      expect(find.byType(DraggablePanel), findsOneWidget);
      expect(
        find.byKey(const ValueKey('draggable_panel_button')),
        findsOneWidget,
      );
    });

    testWidgets('applies custom theme correctly', (tester) async {
      const customColor = Colors.red;
      const customButtonWidth = 50.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DraggablePanel(
              theme: DraggablePanelTheme(
                draggableButtonColor: customColor,
                draggableButtonWidth: customButtonWidth,
              ),
              child: SizedBox(),
            ),
          ),
        ),
      );

      final buttonContainer = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byKey(const ValueKey('draggable_panel_button')),
          matching: find.byType(AnimatedContainer),
        ),
      );

      final decoration = buttonContainer.decoration! as BoxDecoration;
      expect(decoration.color, customColor);
      expect(buttonContainer.constraints?.maxWidth, customButtonWidth);
    });

    testWidgets('toggles panel on tap', (tester) async {
      final controller = DraggablePanelController(
        initialPosition: (x: 100, y: 100),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DraggablePanel(
              controller: controller,
              items: [
                DraggablePanelItem(
                  icon: Icons.add,
                  onTap: (_) {},
                  enableBadge: false,
                ),
              ],
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      // Initially closed
      expect(controller.panelState, PanelState.closed);
      expect(find.byKey(const ValueKey('panel_container')), findsNothing);

      // Tap button
      await tester.tap(
        find.byKey(const ValueKey('draggable_panel_button')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      // Should be open
      expect(controller.panelState, PanelState.open);
      expect(find.byKey(const ValueKey('panel_container')), findsOneWidget);
    });

    testWidgets('items render correctly in panel', (tester) async {
      final controller = DraggablePanelController(
        initialPosition: (x: 100, y: 100),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DraggablePanel(
              controller: controller,
              items: [
                DraggablePanelItem(
                  icon: Icons.home,
                  onTap: (_) {},
                  enableBadge: false,
                ),
                DraggablePanelItem(
                  icon: Icons.settings,
                  onTap: (_) {},
                  enableBadge: false,
                ),
              ],
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      // Tap to open
      await tester.tap(
        find.byKey(const ValueKey('draggable_panel_button')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });
}
