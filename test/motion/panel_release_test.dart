import 'package:draggable_panel/src/model/panel_behavior.dart';
import 'package:draggable_panel/src/model/panel_corner.dart';
import 'package:draggable_panel/src/model/panel_edge.dart';
import 'package:draggable_panel/src/model/panel_placement.dart';
import 'package:draggable_panel/src/model/panel_viewport.dart';
import 'package:draggable_panel/src/motion/panel_motion_spec.dart';
import 'package:draggable_panel/src/motion/panel_release.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _panel = Size(64, 64);

PanelViewport _viewport({TextDirection direction = TextDirection.ltr}) =>
    PanelViewport(
      size: const Size(400, 800),
      safeArea: EdgeInsets.zero,
      viewInsets: EdgeInsets.zero,
      margin: const EdgeInsets.all(16),
      direction: direction,
      avoidKeyboard: true,
    );

PanelPlacement _release(
  Offset topLeft, {
  Offset velocity = Offset.zero,
  PanelBehavior behavior = const PanelBehavior(
    snapPolicy: PanelSnapPolicy.corners,
  ),
  TextDirection direction = TextDirection.ltr,
  PanelPlacement from = const PanelPlacement.corner(PanelCorner.bottomEnd),
  Size panelSize = _panel,
}) => resolvePanelRelease(
  topLeft: topLeft,
  velocity: velocity,
  panelSize: panelSize,
  collapsedSize: _panel,
  viewport: _viewport(direction: direction),
  behavior: behavior,
  motion: PanelMotionSpec(),
  from: from,
);

void main() {
  group('corner snapping', () {
    test('a slow release goes to the nearest corner', () {
      expect(
        _release(const Offset(40, 40)),
        const PanelPlacement.corner(PanelCorner.topStart),
      );
      expect(
        _release(const Offset(300, 700)),
        const PanelPlacement.corner(PanelCorner.bottomEnd),
      );
    });

    test('a flick lands where it was aimed, not where it was released', () {
      const nearTopLeft = Offset(60, 60);
      const noStash = PanelBehavior(
        snapPolicy: PanelSnapPolicy.corners,
        stashable: false,
      );

      expect(
        _release(nearTopLeft, behavior: noStash),
        const PanelPlacement.corner(PanelCorner.topStart),
      );
      expect(
        _release(
          nearTopLeft,
          velocity: const Offset(1200, 1600),
          behavior: noStash,
        ),
        const PanelPlacement.corner(PanelCorner.bottomEnd),
      );
    });

    test('a gentle nudge is not enough to cross the screen', () {
      expect(
        _release(const Offset(60, 60), velocity: const Offset(60, 60)),
        const PanelPlacement.corner(PanelCorner.topStart),
      );
    });

    test('corners are directional, so RTL mirrors the result', () {
      expect(
        _release(const Offset(40, 40)),
        const PanelPlacement.corner(PanelCorner.topStart),
      );
      expect(
        _release(const Offset(40, 40), direction: TextDirection.rtl),
        const PanelPlacement.corner(PanelCorner.topEnd),
      );
    });
  });

  group('stashing', () {
    test('a hard horizontal flick past the edge stashes', () {
      expect(
        _release(const Offset(30, 400), velocity: const Offset(-1500, 0)),
        isA<StashedPlacement>().having((p) => p.edge, 'edge', PanelEdge.start),
      );
    });

    test('stashing to the trailing edge works too', () {
      expect(
        _release(const Offset(300, 400), velocity: const Offset(1500, 0)),
        isA<StashedPlacement>().having((p) => p.edge, 'edge', PanelEdge.end),
      );
    });

    test('a flick that stays on screen does not park', () {
      expect(
        _release(const Offset(160, 400), velocity: const Offset(0, 900)),
        isA<CornerPlacement>(),
      );
    });

    test('letting go at the resting edge does not park it', () {
      expect(_release(const Offset(16, 400)), isA<CornerPlacement>());
      expect(
        _release(const Offset(16, 400), velocity: const Offset(-20, 0)),
        isA<CornerPlacement>(),
      );
    });

    test('pushing it a quarter of its width past the edge parks it', () {
      expect(
        _release(const Offset(-4, 400), velocity: const Offset(-120, 90)),
        isA<StashedPlacement>(),
        reason: 'a sideways push with a little downward drift must still park',
      );
    });

    test('a stash keeps the vertical position it was flung at', () {
      final low = _release(
        const Offset(30, 700),
        velocity: const Offset(-1500, 0),
      );
      final high = _release(
        const Offset(30, 40),
        velocity: const Offset(-1500, 0),
      );

      expect((low as StashedPlacement).verticalAlignment, greaterThan(0));
      expect((high as StashedPlacement).verticalAlignment, lessThan(0));
    });

    test('is refused when the behaviour disallows it', () {
      expect(
        _release(
          const Offset(30, 400),
          velocity: const Offset(-1500, 0),
          behavior: const PanelBehavior(
            stashable: false,
            snapPolicy: PanelSnapPolicy.corners,
          ),
        ),
        isA<CornerPlacement>(),
      );
    });

    test('the stash edge is directional under RTL', () {
      final ltr = _release(
        const Offset(30, 400),
        velocity: const Offset(-1500, 0),
      );
      final rtl = _release(
        const Offset(30, 400),
        velocity: const Offset(-1500, 0),
        direction: TextDirection.rtl,
      );

      expect((ltr as StashedPlacement).edge, PanelEdge.start);
      expect((rtl as StashedPlacement).edge, PanelEdge.end);
    });
  });

  group('snap policies', () {
    test('edges, the default, keeps the height and picks a side', () {
      final placement = _release(
        const Offset(300, 500),
        behavior: const PanelBehavior(),
      );

      expect(placement, isA<FreePlacement>());
      final alignment = (placement as FreePlacement).alignment.resolve(
        TextDirection.ltr,
      );
      expect(alignment.x, 1);
      expect(alignment.y, greaterThan(0));
      expect(alignment.y, lessThan(1));
    });

    test('free leaves the panel where momentum carried it', () {
      final placement = _release(
        const Offset(200, 400),
        behavior: const PanelBehavior(snapPolicy: PanelSnapPolicy.free),
      );

      expect(placement, isA<FreePlacement>());
      final alignment = (placement as FreePlacement).alignment.resolve(
        TextDirection.ltr,
      );
      expect(alignment.x, greaterThan(-1));
      expect(alignment.x, lessThan(1));
    });

    test('free still clamps a projection that leaves the screen', () {
      final placement = _release(
        const Offset(200, 400),
        velocity: const Offset(9000, 0),
        behavior: const PanelBehavior(
          snapPolicy: PanelSnapPolicy.free,
          stashable: false,
        ),
      );

      final alignment = (placement as FreePlacement).alignment.resolve(
        TextDirection.ltr,
      );
      expect(alignment.x, 1);
    });
  });

  group('a parked tab moving between edges', () {
    const stashed = PanelPlacement.stashed(PanelEdge.end);

    test('re-parks once it reaches the far side, without being shoved past '
        'it', () {
      for (final behavior in const [
        PanelBehavior(expandOnUnstash: true),
        PanelBehavior(collapsible: false),
      ]) {
        expect(
          _release(const Offset(18, 400), behavior: behavior, from: stashed),
          isA<StashedPlacement>(),
          reason: '$behavior should park a tab that lands on the far side',
        );
      }
    });

    test('still opens when it is released away from either edge', () {
      for (final behavior in const [
        PanelBehavior(expandOnUnstash: true),
        PanelBehavior(collapsible: false),
      ]) {
        expect(
          _release(const Offset(170, 400), behavior: behavior, from: stashed),
          isNot(isA<StashedPlacement>()),
          reason: '$behavior should let a tab pulled clear of the edges open',
        );
      }
    });

    test('a panel still morphing shut keeps somewhere to be released', () {
      expect(
        _release(
          const Offset(34, 400),
          behavior: const PanelBehavior(collapsible: false),
          from: stashed,
          panelSize: const Size(300, 200),
        ),
        isNot(isA<StashedPlacement>()),
        reason: 'the inward band is the small window, not the open panel',
      );
    });

    test('a panel that has a collapsed window to rest in still needs the '
        'outward shove', () {
      expect(
        _release(
          const Offset(18, 400),
          behavior: const PanelBehavior(),
          from: stashed,
        ),
        isNot(isA<StashedPlacement>()),
      );
    });
  });
}
