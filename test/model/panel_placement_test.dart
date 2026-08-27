import 'package:draggable_panel/src/model/panel_corner.dart';
import 'package:draggable_panel/src/model/panel_edge.dart';
import 'package:draggable_panel/src/model/panel_placement.dart';
import 'package:draggable_panel/src/model/panel_viewport.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

PanelViewport _viewport({
  Size size = const Size(400, 800),
  EdgeInsets safeArea = EdgeInsets.zero,
  EdgeInsets viewInsets = EdgeInsets.zero,
  EdgeInsets margin = EdgeInsets.zero,
  TextDirection direction = TextDirection.ltr,
  bool avoidKeyboard = true,
}) => PanelViewport(
  size: size,
  safeArea: safeArea,
  viewInsets: viewInsets,
  margin: margin,
  direction: direction,
  avoidKeyboard: avoidKeyboard,
);

void main() {
  const panel = Size(100, 60);

  group('PanelCorner', () {
    test('resolves start to the left edge under LTR', () {
      expect(
        PanelCorner.bottomStart.resolve(TextDirection.ltr),
        Alignment.bottomLeft,
      );
      expect(PanelCorner.topEnd.resolve(TextDirection.ltr), Alignment.topRight);
    });

    test('mirrors start and end under RTL', () {
      expect(
        PanelCorner.bottomStart.resolve(TextDirection.rtl),
        Alignment.bottomRight,
      );
      expect(PanelCorner.topEnd.resolve(TextDirection.rtl), Alignment.topLeft);
    });

    test('neighbour moves one step and stops at the sides', () {
      expect(
        PanelCorner.topEnd.neighbour(AxisDirection.down, TextDirection.ltr),
        PanelCorner.bottomEnd,
      );
      expect(
        PanelCorner.topEnd.neighbour(AxisDirection.left, TextDirection.ltr),
        PanelCorner.topStart,
      );
      expect(
        PanelCorner.topEnd.neighbour(AxisDirection.up, TextDirection.ltr),
        isNull,
      );
      expect(
        PanelCorner.topEnd.neighbour(AxisDirection.right, TextDirection.ltr),
        isNull,
      );
    });

    test('neighbour follows physical direction under RTL', () {
      expect(
        PanelCorner.topEnd.neighbour(AxisDirection.right, TextDirection.rtl),
        PanelCorner.topStart,
      );
    });
  });

  group('CornerPlacement.resolve', () {
    test('pins each corner to the travel rect', () {
      final viewport = _viewport();

      expect(
        const CornerPlacement(PanelCorner.topStart).resolve(viewport, panel),
        Offset.zero,
      );
      expect(
        const CornerPlacement(PanelCorner.bottomEnd).resolve(viewport, panel),
        const Offset(300, 740),
      );
    });

    test('insets by safe area and margin', () {
      final viewport = _viewport(
        safeArea: const EdgeInsets.only(top: 44, bottom: 34),
        margin: const EdgeInsets.all(16),
      );

      expect(
        const CornerPlacement(PanelCorner.topStart).resolve(viewport, panel),
        const Offset(16, 60),
      );
      expect(
        const CornerPlacement(PanelCorner.bottomEnd).resolve(viewport, panel),
        const Offset(284, 690),
      );
    });

    test('lifts a bottom corner by exactly the keyboard inset', () {
      final closed = _viewport();
      final open = _viewport(viewInsets: const EdgeInsets.only(bottom: 300));

      final closedY = const CornerPlacement(
        PanelCorner.bottomEnd,
      ).resolve(closed, panel).dy;
      final openY = const CornerPlacement(
        PanelCorner.bottomEnd,
      ).resolve(open, panel).dy;

      expect(closedY - openY, 300);
    });

    test('ignores the keyboard when avoidKeyboard is false', () {
      final open = _viewport(
        viewInsets: const EdgeInsets.only(bottom: 300),
        avoidKeyboard: false,
      );

      expect(
        const CornerPlacement(PanelCorner.bottomEnd).resolve(open, panel).dy,
        740,
      );
    });

    test('centres a panel larger than its bounds', () {
      final viewport = _viewport(size: const Size(80, 800));

      expect(
        const CornerPlacement(PanelCorner.topStart).resolve(viewport, panel).dx,
        -10,
      );
    });
  });

  group('StashedPlacement.resolve', () {
    test('leaves exactly the peek visible on the left', () {
      final viewport = _viewport();

      final offset = const StashedPlacement(
        PanelEdge.start,
      ).resolve(viewport, panel, stashedPeek: 20);

      expect(offset.dx, -80);
    });

    test('mirrors to the right edge under RTL', () {
      final viewport = _viewport(direction: TextDirection.rtl);

      final offset = const StashedPlacement(
        PanelEdge.start,
      ).resolve(viewport, panel, stashedPeek: 20);

      expect(offset.dx, 380);
    });

    test('preserves the vertical alignment it was flung at', () {
      final viewport = _viewport();

      expect(
        const StashedPlacement(
          PanelEdge.start,
          verticalAlignment: -1,
        ).resolve(viewport, panel).dy,
        0,
      );
      expect(
        const StashedPlacement(PanelEdge.start).resolve(viewport, panel).dy,
        370,
      );
    });
  });

  group('FreePlacement.resolve', () {
    test('inscribes the panel at the normalized position', () {
      final viewport = _viewport();

      expect(
        const FreePlacement(Alignment.center).resolve(viewport, panel),
        const Offset(150, 370),
      );
    });

    test('resolves directional alignment against RTL', () {
      final viewport = _viewport(direction: TextDirection.rtl);

      expect(
        const FreePlacement(
          AlignmentDirectional.topStart,
        ).resolve(viewport, panel),
        const Offset(300, 0),
      );
    });
  });

  group('JSON round-trip', () {
    const cases = <PanelPlacement>[
      CornerPlacement(PanelCorner.topStart),
      CornerPlacement(PanelCorner.bottomEnd),
      StashedPlacement(PanelEdge.end, verticalAlignment: -0.5),
      FreePlacement(Alignment(0.25, -0.75)),
      FreePlacement(AlignmentDirectional(0.25, -0.75)),
    ];

    for (final placement in cases) {
      test('survives $placement', () {
        expect(PanelPlacement.fromJson(placement.toJson()), placement);
      });
    }

    test('rejects an unknown type', () {
      expect(
        () => PanelPlacement.fromJson({'type': 'orbit'}),
        throwsFormatException,
      );
    });

    test('rejects an unknown corner', () {
      expect(
        () => PanelPlacement.fromJson({'type': 'corner', 'corner': 'middle'}),
        throwsFormatException,
      );
    });

    test('rejects a non-numeric coordinate', () {
      expect(
        () => PanelPlacement.fromJson({'type': 'free', 'x': 'left', 'y': 0}),
        throwsFormatException,
      );
    });
  });
}
