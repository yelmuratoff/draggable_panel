import 'package:draggable_panel/src/model/panel_extent.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bounds = Rect.fromLTWH(0, 0, 400, 800);

  group('FixedExtent', () {
    test('returns its size', () {
      expect(
        const PanelExtent.fixed(Size(300, 200)).resolve(bounds, Size.zero),
        const Size(300, 200),
      );
    });

    test('caps at the bounds', () {
      expect(
        const PanelExtent.fixed(Size(900, 900)).resolve(bounds, Size.zero),
        const Size(400, 800),
      );
    });
  });

  group('FractionExtent', () {
    test('scales the bounds', () {
      expect(
        const PanelExtent.fraction(
          width: 0.5,
          height: 0.25,
        ).resolve(bounds, Size.zero),
        const Size(200, 200),
      );
    });
  });

  group('ContentExtent', () {
    test('hugs the measured content', () {
      expect(
        const PanelExtent.content().resolve(bounds, const Size(220, 130)),
        const Size(220, 130),
      );
    });

    test('caps the width at maxWidth', () {
      expect(
        const PanelExtent.content(
          maxWidth: 180,
        ).resolve(bounds, const Size(220, 130)).width,
        180,
      );
    });

    test('caps the height at a fraction of the bounds', () {
      expect(
        const PanelExtent.content(
          maxHeightFraction: 0.5,
        ).resolve(bounds, const Size(220, 700)).height,
        400,
      );
    });

    test('never exceeds the bounds even without caps', () {
      expect(
        const PanelExtent.content().resolve(bounds, const Size(900, 900)),
        const Size(400, 800),
      );
    });
  });
}
