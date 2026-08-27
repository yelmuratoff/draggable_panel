import 'package:draggable_panel/src/motion/panel_frame.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _collapsed = Size(64, 64);
const _expanded = Size(280, 200);
const _bounds = Rect.fromLTWH(0, 0, 400, 800);

PanelFrame _frame({
  Offset origin = const Offset(320, 720),
  Alignment anchor = Alignment.bottomRight,
  double expansion = 0,
  Rect bounds = _bounds,
  bool reduceMotion = false,
  Size collapsedSize = _collapsed,
  Size expandedSize = _expanded,
}) => computePanelFrame(
  origin: origin,
  collapsedSize: collapsedSize,
  expandedSize: expandedSize,
  anchor: anchor,
  bounds: bounds,
  expansion: expansion,
  reduceMotion: reduceMotion,
);

void main() {
  group('at rest', () {
    test('collapsed sits exactly at the origin', () {
      expect(_frame().rect, const Rect.fromLTWH(320, 720, 64, 64));
    });

    test('fully expanded takes the expanded size', () {
      expect(_frame(expansion: 1).rect.size, _expanded);
    });
  });

  group('anchoring', () {
    test('the bottom-right corner stays pinned while growing', () {
      final collapsed = _frame().rect;

      for (final t in const <double>[0.25, 0.5, 0.75, 1]) {
        final grown = _frame(expansion: t).rect;
        expect(grown.bottomRight, collapsed.bottomRight, reason: 't = $t');
      }
    });

    test('the top-left corner stays pinned while growing', () {
      const anchor = Alignment.topLeft;
      final collapsed = _frame(origin: Offset.zero, anchor: anchor).rect;

      for (final t in const <double>[0.25, 0.5, 1]) {
        final grown = _frame(
          origin: Offset.zero,
          anchor: anchor,
          expansion: t,
        ).rect;
        expect(grown.topLeft, collapsed.topLeft, reason: 't = $t');
      }
    });

    test('each corner grows away from its own edge', () {
      const cases = <(Alignment, Offset)>[
        (Alignment.topLeft, Offset(16, 16)),
        (Alignment.topRight, Offset(320, 16)),
        (Alignment.bottomLeft, Offset(16, 720)),
        (Alignment.bottomRight, Offset(320, 720)),
      ];

      for (final (anchor, origin) in cases) {
        final collapsed = _frame(origin: origin, anchor: anchor).rect;
        final grown = _frame(origin: origin, anchor: anchor, expansion: 1).rect;

        expect(
          Offset(
            anchor.x < 0 ? grown.left : grown.right,
            anchor.y < 0 ? grown.top : grown.bottom,
          ),
          Offset(
            anchor.x < 0 ? collapsed.left : collapsed.right,
            anchor.y < 0 ? collapsed.top : collapsed.bottom,
          ),
          reason: '$anchor',
        );
      }
    });
  });

  group('growth', () {
    test('size increases monotonically with expansion', () {
      var previous = 0.0;
      for (var t = 0.0; t <= 1; t += 0.1) {
        final area = _frame(expansion: t).rect.width;
        expect(area, greaterThanOrEqualTo(previous));
        previous = area;
      }
    });

    test('a bouncy overshoot grows past the expanded size', () {
      expect(_frame(expansion: 1.1).rect.width, greaterThan(_expanded.width));
    });
  });

  group('content placement', () {
    test('children keep their natural size — nothing is scaled', () {
      final frame = _frame(expansion: 0.5);

      expect(
        frame.expandedOrigin.dx + _expanded.width,
        closeTo(frame.rect.right, 1e-9),
      );
      expect(
        frame.collapsedOrigin.dx + _collapsed.width,
        closeTo(frame.rect.right, 1e-9),
      );
    });

    test('both children align to the anchored corner', () {
      final frame = _frame(anchor: Alignment.topLeft, expansion: 0.5);

      expect(frame.collapsedOrigin, frame.rect.topLeft);
      expect(frame.expandedOrigin, frame.rect.topLeft);
    });
  });

  group('cross-dissolve', () {
    test('collapsed content is gone before expanded content arrives', () {
      final atQuarter = _frame(expansion: 0.27);

      expect(atQuarter.collapsedOpacity, 0);
      expect(atQuarter.expandedOpacity, 0);
    });

    test('opacities run to their ends', () {
      expect(_frame().collapsedOpacity, 1);
      expect(_frame().expandedOpacity, 0);
      expect(_frame(expansion: 1).collapsedOpacity, 0);
      expect(_frame(expansion: 1).expandedOpacity, 1);
    });

    test('expanded content fades in over the second half', () {
      final mid = _frame(expansion: 0.5);

      expect(mid.expandedOpacity, greaterThan(0));
      expect(mid.expandedOpacity, lessThan(1));
    });
  });

  group('containment', () {
    test('an expanded panel is pulled back inside the bounds', () {
      final frame = _frame(origin: const Offset(380, 780), expansion: 1);

      expect(frame.rect.right, lessThanOrEqualTo(_bounds.right));
      expect(frame.rect.bottom, lessThanOrEqualTo(_bounds.bottom));
    });

    test('a collapsed rubber-banded panel is left where the finger put it', () {
      final frame = _frame(origin: const Offset(-40, 720));

      expect(frame.rect.left, -40);
    });

    test('containment fades in with the growth', () {
      const origin = Offset(-40, 720);
      const unbounded = Rect.fromLTWH(-10000, -10000, 20000, 20000);

      final free = _frame(origin: origin, expansion: 0.25, bounds: unbounded);
      final pulled = _frame(origin: origin, expansion: 0.25);
      final settled = _frame(origin: origin, expansion: 1);

      expect(pulled.rect.left, greaterThan(free.rect.left));
      expect(pulled.rect.left, lessThan(_bounds.left));
      expect(settled.rect.left, _bounds.left);
    });

    test('a panel wider than its bounds pins to the leading edge', () {
      final frame = _frame(
        origin: const Offset(200, 400),
        expandedSize: const Size(900, 200),
        expansion: 1,
      );

      expect(frame.rect.left, _bounds.left);
    });
  });

  group('reduced motion', () {
    test('the rect steps instead of sweeping', () {
      expect(_frame(expansion: 0.5, reduceMotion: true).rect.size, _expanded);
      expect(_frame(reduceMotion: true).rect.size, _collapsed);
    });

    test('the content still cross-fades', () {
      final mid = _frame(expansion: 0.5, reduceMotion: true);

      expect(mid.collapsedOpacity, 0);
      expect(mid.expandedOpacity, greaterThan(0));
      expect(mid.expandedOpacity, lessThan(1));
    });
  });
}
