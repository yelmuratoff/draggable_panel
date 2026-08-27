import 'dart:ui' show ImageFilter;

import 'package:draggable_panel/draggable_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Resolves a style inside a real [Theme], optionally with an app-wide
/// extension and a call-site override.
Future<PanelStyle> _resolve(
  WidgetTester tester, {
  DraggablePanelThemeData? appWide,
  DraggablePanelThemeData? override,
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
}) async {
  late PanelStyle style;
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        brightness: brightness,
        extensions: appWide == null ? const [] : [appWide],
      ),
      home: Directionality(
        textDirection: direction,
        child: Builder(
          builder: (context) {
            style = PanelStyle.resolve(context, override);
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  // MaterialApp crossfades theme changes through AnimatedTheme.
  await tester.pumpAndSettle();
  return style;
}

void main() {
  group('resolution order', () {
    testWidgets('falls back to ColorScheme-derived defaults', (tester) async {
      final style = await _resolve(tester);

      expect(style.elevation, 6);
      expect(style.stashedPeek, 26);
      expect(style.expandedExtent, isA<ContentExtent>());
    });

    testWidgets('surface colour follows the ColorScheme in both brightnesses', (
      tester,
    ) async {
      final light = await _resolve(tester);
      final dark = await _resolve(tester, brightness: Brightness.dark);

      expect(
        light.surfaceColor,
        ThemeData(
          brightness: Brightness.light,
        ).colorScheme.surfaceContainerHigh,
      );
      expect(
        dark.surfaceColor,
        ThemeData(brightness: Brightness.dark).colorScheme.surfaceContainerHigh,
      );
      expect(light.surfaceColor, isNot(dark.surfaceColor));
    });

    testWidgets('an app-wide extension overrides the defaults', (tester) async {
      final style = await _resolve(
        tester,
        appWide: const DraggablePanelThemeData(elevation: 10),
      );

      expect(style.elevation, 10);
      expect(style.stashedPeek, 26);
    });

    testWidgets('a call-site theme wins over the app-wide extension', (
      tester,
    ) async {
      final style = await _resolve(
        tester,
        appWide: const DraggablePanelThemeData(elevation: 10, stashedPeek: 30),
        override: const DraggablePanelThemeData(elevation: 2),
      );

      expect(style.elevation, 2);
      expect(style.stashedPeek, 30);
    });

    testWidgets('a null token inherits rather than clobbering', (tester) async {
      final style = await _resolve(
        tester,
        appWide: const DraggablePanelThemeData(surfaceColor: Color(0xFF00FF00)),
        override: const DraggablePanelThemeData(elevation: 1),
      );

      expect(style.surfaceColor, const Color(0xFF00FF00));
      expect(style.elevation, 1);
    });
  });

  group('resolved rules', () {
    testWidgets('the collapsed size is floored by the minimum tap target', (
      tester,
    ) async {
      final style = await _resolve(
        tester,
        override: const DraggablePanelThemeData(
          collapsedSize: Size(20, 20),
          minimumTapTarget: Size(48, 48),
        ),
      );

      expect(style.collapsedSize, const Size(48, 48));
    });

    testWidgets('a large collapsed size is left alone', (tester) async {
      final style = await _resolve(
        tester,
        override: const DraggablePanelThemeData(collapsedSize: Size(160, 90)),
      );

      expect(style.collapsedSize, const Size(160, 90));
    });

    testWidgets('the directional margin mirrors under RTL', (tester) async {
      final ltr = await _resolve(
        tester,
        override: const DraggablePanelThemeData(
          margin: EdgeInsetsDirectional.only(start: 40),
        ),
      );
      final rtl = await _resolve(
        tester,
        direction: TextDirection.rtl,
        override: const DraggablePanelThemeData(
          margin: EdgeInsetsDirectional.only(start: 40),
        ),
      );

      expect(ltr.margin, const EdgeInsets.only(left: 40));
      expect(rtl.margin, const EdgeInsets.only(right: 40));
    });
  });

  group('surface filter seam', () {
    testWidgets('is null by default, so nothing pays for a backdrop pass', (
      tester,
    ) async {
      expect((await _resolve(tester)).surfaceFilter, isNull);
    });

    testWidgets('flows from the theme into the resolved style', (tester) async {
      final filter = ImageFilter.blur(sigmaX: 12, sigmaY: 12);
      final style = await _resolve(
        tester,
        override: DraggablePanelThemeData(surfaceFilter: filter),
      );

      expect(style.surfaceFilter, filter);
    });

    testWidgets('a filtered panel paints without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DraggablePanel(
            theme: DraggablePanelThemeData(
              surfaceFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              surfaceColor: const Color(0x66FFFFFF),
              motion: PanelMotionSpec.instant(),
            ),
            collapsedBuilder: (context, status) =>
                const ColoredBox(color: Color(0xFF112233)),
            expandedBuilder: (context, status) =>
                const SizedBox(width: 200, height: 120),
            child: const ColoredBox(color: Color(0xFF884422)),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('interpolation', () {
    /// The widest corner the shape rounds a [box] by, read off its outline.
    double cornerInsetOf(ShapeBorder shape, Rect box) {
      final path = shape.getOuterPath(box);
      var inset = 0.0;
      while (inset < box.height / 2 &&
          !path.contains(Offset(box.left + 0.5, box.top + inset))) {
        inset += 0.5;
      }
      return inset;
    }

    testWidgets('shapeAt grows the corner radius with the panel', (
      tester,
    ) async {
      final style = await _resolve(tester);
      const box = Rect.fromLTWH(0, 0, 64, 64);

      expect(
        cornerInsetOf(style.shapeAt(0), box),
        closeTo(cornerInsetOf(style.collapsedShape, box), 0.5),
      );
      expect(
        cornerInsetOf(style.shapeAt(1), box),
        closeTo(cornerInsetOf(style.shape, box), 0.5),
      );
      expect(
        cornerInsetOf(style.shapeAt(1), box),
        greaterThan(cornerInsetOf(style.shapeAt(0), box)),
      );
    });

    testWidgets('shapeAt carries the stashed shape out of the edge', (
      tester,
    ) async {
      final style = await _resolve(
        tester,
        override: const DraggablePanelThemeData(
          stashedShape: RoundedRectangleBorder(),
        ),
      );
      const box = Rect.fromLTWH(0, 0, 64, 64);

      expect(cornerInsetOf(style.shapeAt(0, emergence: 0), box), 0);
      expect(
        cornerInsetOf(style.shapeAt(0), box),
        closeTo(cornerInsetOf(style.collapsedShape, box), 0.5),
      );
      expect(
        cornerInsetOf(style.shapeAt(0, emergence: 0.5), box),
        greaterThan(0),
        reason: 'the tab rounds as it is pulled out, not on arrival',
      );
    });

    testWidgets('elevationAt lifts while dragging, whatever the expansion', (
      tester,
    ) async {
      final style = await _resolve(tester);

      expect(style.elevationAt(0, isDragging: false), 6);
      expect(style.elevationAt(1, isDragging: false), 8);
      expect(style.elevationAt(0.5, isDragging: false), 7);
      expect(style.elevationAt(0, isDragging: true), 12);
      expect(style.elevationAt(1, isDragging: true), 12);
    });

    test('lerp crossfades continuous tokens', () {
      const a = DraggablePanelThemeData(
        elevation: 0,
        surfaceColor: Color(0xFF000000),
      );
      const b = DraggablePanelThemeData(
        elevation: 10,
        surfaceColor: Color(0xFFFFFFFF),
      );

      final mid = a.lerp(b, 0.5);

      expect(mid.elevation, 5);
      expect(mid.surfaceColor, isNot(const Color(0xFF000000)));
      expect(mid.surfaceColor, isNot(const Color(0xFFFFFFFF)));
    });

    test('lerp switches discrete tokens at the midpoint', () {
      final a = DraggablePanelThemeData(
        clipBehavior: Clip.none,
        expandedExtent: const PanelExtent.fixed(Size(10, 10)),
        motion: PanelMotionSpec(),
      );
      final b = DraggablePanelThemeData(
        clipBehavior: Clip.antiAlias,
        expandedExtent: const PanelExtent.fixed(Size(20, 20)),
        motion: PanelMotionSpec.instant(),
      );

      expect(a.lerp(b, 0.49).clipBehavior, Clip.none);
      expect(a.lerp(b, 0.5).clipBehavior, Clip.antiAlias);
      expect(
        a.lerp(b, 0.49).expandedExtent,
        const PanelExtent.fixed(Size(10, 10)),
      );
      expect(a.lerp(b, 0.51).motion?.immediate, isTrue);
    });

    test('lerp against null keeps this side', () {
      const a = DraggablePanelThemeData(elevation: 3);

      expect(a.lerp(null, 0.9), a);
    });
  });

  group('value semantics', () {
    test('equal tokens compare equal and hash alike', () {
      const a = DraggablePanelThemeData(elevation: 4, stashedPeek: 12);
      const b = DraggablePanelThemeData(elevation: 4, stashedPeek: 12);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const DraggablePanelThemeData(elevation: 5)));
    });

    test('merge leaves the receiver untouched', () {
      const base = DraggablePanelThemeData(elevation: 4);
      final merged = base.merge(const DraggablePanelThemeData(elevation: 9));

      expect(base.elevation, 4);
      expect(merged.elevation, 9);
    });

    test('merging null is a no-op', () {
      const base = DraggablePanelThemeData(elevation: 4);

      expect(base.merge(null), same(base));
    });

    test('tokens show up in diagnostics', () {
      const theme = DraggablePanelThemeData(elevation: 7);

      expect(theme.toString(), contains('elevation: 7'));
    });
  });
}
