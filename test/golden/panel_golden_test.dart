@Tags(['golden'])
library;

import 'dart:ui' show ImageFilter;

import 'package:draggable_panel/draggable_panel.dart';
import 'package:draggable_panel/src/core/panel_surface.dart';
import 'package:draggable_panel/src/core/render_panel_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Goldens lock the panel's *shape and surface*, never its timing.
///
/// Motion is held still with [PanelMotionSpec.instant] and the expansion is
/// driven to an exact value, so nothing here depends on a frame clock. Shadows
/// are disabled because their blur is not identical across platforms.
Future<void> _pumpPanel(
  WidgetTester tester, {
  required Brightness brightness,
  DraggablePanelThemeData? theme,
  DraggablePanelController? controller,
  TextDirection direction = TextDirection.ltr,
}) async {
  final panelController = controller ?? DraggablePanelController();
  if (controller == null) addTearDown(panelController.dispose);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: brightness, colorSchemeSeed: Colors.indigo),
      home: Directionality(
        textDirection: direction,
        child: DraggablePanel(
          controller: panelController,
          theme: (theme ?? const DraggablePanelThemeData()).copyWith(
            motion: PanelMotionSpec.instant(),
          ),
          collapsedBuilder: (context, status) =>
              const _Face(color: Color(0xFF1B5E20), size: 24),
          expandedBuilder: (context, status) => const SizedBox(
            width: 260,
            height: 160,
            child: _Face(color: Color(0xFF0D47A1), size: 72),
          ),
          child: const _Backdrop(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Panel content drawn from plain colours rather than an icon font.
///
/// `flutter test` ships no Material Icons glyphs, so an [Icon] renders as an
/// empty box and would lock nothing useful into the reference image.
class _Face extends StatelessWidget {
  const _Face({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}

/// Something behind the panel with structure, so a backdrop filter has
/// visible material to work on.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3F51B5), Color(0xFFE91E63)],
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        6,
        (index) => Container(height: 12, color: Colors.white24),
      ),
    ),
  );
}

void main() {
  setUpAll(() => debugDisableShadows = true);
  tearDownAll(() => debugDisableShadows = false);

  group('surface', () {
    testWidgets('collapsed, light', (tester) async {
      await _pumpPanel(tester, brightness: Brightness.light);
      await expectLater(
        find.byType(DraggablePanel),
        matchesGoldenFile('goldens/collapsed_light.png'),
      );
    });

    testWidgets('collapsed, dark', (tester) async {
      await _pumpPanel(tester, brightness: Brightness.dark);
      await expectLater(
        find.byType(DraggablePanel),
        matchesGoldenFile('goldens/collapsed_dark.png'),
      );
    });

    testWidgets('expanded, light', (tester) async {
      final controller = DraggablePanelController();
      addTearDown(controller.dispose);
      await _pumpPanel(
        tester,
        brightness: Brightness.light,
        controller: controller,
      );

      controller.expand();
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(DraggablePanel),
        matchesGoldenFile('goldens/expanded_light.png'),
      );
    });

    testWidgets('expanded, dark', (tester) async {
      final controller = DraggablePanelController();
      addTearDown(controller.dispose);
      await _pumpPanel(
        tester,
        brightness: Brightness.dark,
        controller: controller,
      );

      controller.expand();
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(DraggablePanel),
        matchesGoldenFile('goldens/expanded_dark.png'),
      );
    });

    testWidgets('stashed against the start edge', (tester) async {
      final controller = DraggablePanelController();
      addTearDown(controller.dispose);
      await _pumpPanel(
        tester,
        brightness: Brightness.light,
        controller: controller,
      );

      controller.stash(PanelEdge.start);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(DraggablePanel),
        matchesGoldenFile('goldens/stashed_ltr.png'),
      );
    });

    testWidgets('stashed against the start edge, mirrored under RTL', (
      tester,
    ) async {
      final controller = DraggablePanelController();
      addTearDown(controller.dispose);
      await _pumpPanel(
        tester,
        brightness: Brightness.light,
        controller: controller,
        direction: TextDirection.rtl,
      );

      controller.stash(PanelEdge.start);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(DraggablePanel),
        matchesGoldenFile('goldens/stashed_rtl.png'),
      );
    });
  });

  group('themeable seams', () {
    // RoundedSuperellipseBorder is why this package requires Flutter 3.32.
    testWidgets('a squircle shape override actually paints a superellipse', (
      tester,
    ) async {
      await _pumpPanel(
        tester,
        brightness: Brightness.light,
        theme: const DraggablePanelThemeData(
          collapsedSize: Size(140, 140),
          collapsedShape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.all(Radius.circular(48)),
          ),
        ),
      );

      await expectLater(
        find.byType(DraggablePanel),
        matchesGoldenFile('goldens/seam_squircle.png'),
      );
    });

    testWidgets('the same radius as a plain rounded rectangle, for contrast', (
      tester,
    ) async {
      await _pumpPanel(
        tester,
        brightness: Brightness.light,
        theme: const DraggablePanelThemeData(
          collapsedSize: Size(140, 140),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(48)),
          ),
        ),
      );

      await expectLater(
        find.byType(DraggablePanel),
        matchesGoldenFile('goldens/seam_rounded_rect.png'),
      );
    });

    testWidgets('a surface filter frosts what is behind the panel', (
      tester,
    ) async {
      await _pumpPanel(
        tester,
        brightness: Brightness.light,
        theme: DraggablePanelThemeData(
          collapsedSize: const Size(160, 160),
          surfaceFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          surfaceColor: Colors.white.withValues(alpha: 0.35),
        ),
      );

      await expectLater(
        find.byType(DraggablePanel),
        matchesGoldenFile('goldens/seam_frosted.png'),
      );
    });
  });

  group('morph', () {
    testWidgets('held halfway between its two faces', (tester) async {
      final controller = DraggablePanelController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(colorSchemeSeed: Colors.indigo),
          home: DraggablePanel(
            controller: controller,
            theme: DraggablePanelThemeData(
              collapsedSize: const Size(80, 80),
              motion: PanelMotionSpec(
                morphSpring: SpringDescription.withDurationAndBounce(
                  duration: const Duration(seconds: 2),
                ),
              ),
            ),
            collapsedBuilder: (context, status) =>
                const _Face(color: Color(0xFF1B5E20), size: 24),
            expandedBuilder: (context, status) => const SizedBox(
              width: 260,
              height: 160,
              child: _Face(color: Color(0xFF0D47A1), size: 72),
            ),
            child: const _Backdrop(),
          ),
        ),
      );
      await tester.pump();

      controller.expand();
      final surface = tester.renderObject<RenderPanelSurface>(
        find.byType(PanelSurface),
      );

      var frames = 0;
      while (surface.paintedRect.width < 160 && frames < 240) {
        frames++;
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(surface.paintedRect.width, greaterThan(80));
      expect(surface.paintedRect.width, lessThan(260));

      await expectLater(
        find.byType(DraggablePanel),
        matchesGoldenFile('goldens/morph_midway.png'),
      );

      controller.hide();
      await tester.pumpAndSettle();
    });
  });
}
