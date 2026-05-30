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

    testWidgets('does not toggle on tap when tapToToggle is false',
        (tester) async {
      final controller = DraggablePanelController(
        initialPosition: (x: 100, y: 100),
        tapToToggle: false,
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

      await tester.tap(
        find.byKey(const ValueKey('draggable_panel_button')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(controller.panelState, PanelState.closed);
    });

    testWidgets('applies custom motion duration to the panel slide',
        (tester) async {
      const customDuration = Duration(milliseconds: 700);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DraggablePanel(
              theme: DraggablePanelTheme(
                motion: DraggablePanelMotion(panelMoveDuration: customDuration),
              ),
              child: SizedBox.expand(),
            ),
          ),
        ),
      );

      final positioned = tester.widget<AnimatedPositioned>(
        find.byKey(const ValueKey('draggable_panel')),
      );

      expect(positioned.duration, customDuration);
    });

    testWidgets('uses handleBuilder for the button content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DraggablePanel(
              handleBuilder: (
                context, {
                required isDragging,
                required isDockedRight,
              }) =>
                  const SizedBox(key: ValueKey('custom_handle')),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('custom_handle')), findsOneWidget);
    });

    testWidgets('uses itemBuilder for item content', (tester) async {
      final controller = DraggablePanelController(
        initialPosition: (x: 100, y: 100),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DraggablePanel(
              controller: controller,
              itemBuilder: (context, item) =>
                  const Text('custom', key: ValueKey('custom_item')),
              items: [
                DraggablePanelItem(
                  icon: Icons.home,
                  onTap: (_) {},
                  enableBadge: false,
                ),
              ],
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('draggable_panel_button')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('custom_item')), findsOneWidget);
      expect(find.byIcon(Icons.home), findsNothing);
    });

    testWidgets('applies a custom item icon size from the theme',
        (tester) async {
      final controller = DraggablePanelController(
        initialPosition: (x: 100, y: 100),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DraggablePanel(
              controller: controller,
              theme: const DraggablePanelTheme(
                itemTheme: DraggablePanelItemThemeData(iconSize: 40),
              ),
              items: [
                DraggablePanelItem(
                  icon: Icons.home,
                  onTap: (_) {},
                  enableBadge: false,
                ),
              ],
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('draggable_panel_button')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.home));
      expect(icon.size, 40);
    });

    testWidgets('uses itemFrameBuilder to replace the cell shell',
        (tester) async {
      final controller = DraggablePanelController(
        initialPosition: (x: 100, y: 100),
      );
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DraggablePanel(
              controller: controller,
              itemFrameBuilder: (context, render) => GestureDetector(
                key: const ValueKey('item_frame'),
                onTap: render.onTap,
                child: render.content,
              ),
              items: [
                DraggablePanelItem(
                  icon: Icons.home,
                  onTap: (_) => tapped = true,
                  enableBadge: false,
                ),
              ],
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('draggable_panel_button')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('item_frame')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('item_frame')));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('routes long-press through onShowTooltip', (tester) async {
      final controller = DraggablePanelController(
        initialPosition: (x: 100, y: 100),
      );
      DraggablePanelTooltipData? captured;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DraggablePanel(
              controller: controller,
              onShowTooltip: (context, data) => captured = data,
              items: [
                DraggablePanelItem(
                  icon: Icons.home,
                  onTap: (_) {},
                  enableBadge: false,
                  description: 'tooltip text',
                ),
              ],
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('draggable_panel_button')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.byIcon(Icons.home));
      await tester.pumpAndSettle();

      expect(captured?.message, 'tooltip text');
    });

    testWidgets('uses panelBuilder for the panel surface', (tester) async {
      final controller = DraggablePanelController(
        initialPosition: (x: 100, y: 100),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DraggablePanel(
              controller: controller,
              panelBuilder: (context, surface) => ConstrainedBox(
                key: const ValueKey('custom_surface'),
                constraints: BoxConstraints(
                  maxHeight: surface.maxHeight,
                  maxWidth: surface.width,
                ),
                child: ColoredBox(
                  color: surface.color,
                  child: SingleChildScrollView(child: surface.content),
                ),
              ),
              items: [
                DraggablePanelItem(
                  icon: Icons.home,
                  onTap: (_) {},
                  enableBadge: false,
                ),
              ],
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('draggable_panel_button')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('custom_surface')), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('uses panelContentBuilder for the content layout',
        (tester) async {
      final controller = DraggablePanelController(
        initialPosition: (x: 100, y: 100),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DraggablePanel(
              controller: controller,
              panelContentBuilder: (context, content) => Column(
                key: const ValueKey('custom_layout'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final item in content.items)
                    content.buildItem(context, item),
                ],
              ),
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

      await tester.tap(
        find.byKey(const ValueKey('draggable_panel_button')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('custom_layout')), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('panel height wraps its content tightly', (tester) async {
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
              ],
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('draggable_panel_button')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      // One 40px cell (24 icon + 8*2 padding) + 8*2 content padding ≈ 56,
      // not a fixed/over-estimated height that leaves dead space.
      final height =
          tester.getSize(find.byKey(const ValueKey('panel_container'))).height;
      expect(height, lessThan(80));
    });

    testWidgets('panel width hugs its content (no trailing space)',
        (tester) async {
      final controller = DraggablePanelController(
        initialPosition: (x: 20, y: 100),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DraggablePanel(
              controller: controller,
              // Default panelWidth is 200; three small items must not fill it.
              items: [
                for (final icon in [Icons.home, Icons.search, Icons.settings])
                  DraggablePanelItem(
                    icon: icon,
                    onTap: (_) {},
                    enableBadge: false,
                  ),
              ],
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('draggable_panel_button')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      final size =
          tester.getSize(find.byKey(const ValueKey('panel_container')));
      // Three small items fit one row well under the 200px max: the panel hugs
      // them (narrow) and stays a single row (short), with no 2-column wrap.
      expect(size.width, lessThan(190));
      expect(size.height, lessThan(80));
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

  group('DraggablePanelController', () {
    const pageWidth = 400.0;

    DraggablePanelController dockedController() => DraggablePanelController()
      ..buttonWidth = 40
      ..panelWidth = 200
      ..forceDock(pageWidth);

    test('does not report the off-screen position when opening', () {
      final reportedX = <double>[];
      final controller = dockedController()
        ..addPositionListener((x, y) => reportedX.add(x))
        ..toggleMainButton(pageWidth);

      expect(controller.panelState, PanelState.open);
      expect(
        reportedX,
        isEmpty,
        reason: 'the hidden off-screen X must never reach position listeners',
      );
    });

    test('keeps the button hidden when relayout runs while panel is open', () {
      final controller = dockedController()..toggleMainButton(pageWidth);
      expect(controller.panelState, PanelState.open);

      final hiddenLeft = controller.draggablePositionLeft;
      controller.relayout(pageWidth);

      expect(controller.panelState, PanelState.open);
      expect(
        controller.draggablePositionLeft,
        hiddenLeft,
        reason: 'resizing while open must not pull the button back on-screen',
      );
    });

    test('disables movement animation during relayout', () {
      final controller = dockedController()..toggleMainButton(pageWidth);
      expect(controller.animateMovement, isTrue);

      controller.relayout(pageWidth);

      expect(controller.animateMovement, isFalse);
    });
  });
}
