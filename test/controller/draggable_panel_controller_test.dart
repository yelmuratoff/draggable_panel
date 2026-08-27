import 'package:draggable_panel/src/controller/draggable_panel_controller.dart';
import 'package:draggable_panel/src/controller/panel_event.dart';
import 'package:draggable_panel/src/model/panel_behavior.dart';
import 'package:draggable_panel/src/model/panel_corner.dart';
import 'package:draggable_panel/src/model/panel_edge.dart';
import 'package:draggable_panel/src/model/panel_phase.dart';
import 'package:draggable_panel/src/model/panel_placement.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _topStart = PanelPlacement.corner(PanelCorner.topStart);
const _bottomEnd = PanelPlacement.corner(PanelCorner.bottomEnd);

DraggablePanelController _controller({
  PanelPlacement initialPlacement = _bottomEnd,
  bool initiallyExpanded = false,
  bool initiallyHidden = false,
}) {
  final controller = DraggablePanelController(
    initialPlacement: initialPlacement,
    initiallyExpanded: initiallyExpanded,
    initiallyHidden: initiallyHidden,
  );
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  group('initial status', () {
    test('starts collapsed at the given placement', () {
      final controller = _controller(initialPlacement: _topStart);

      expect(controller.phase, PanelPhase.collapsed);
      expect(controller.placement, _topStart);
    });

    test('honours initiallyExpanded and initiallyHidden', () {
      expect(_controller(initiallyExpanded: true).phase, PanelPhase.expanded);
      expect(_controller(initiallyHidden: true).phase, PanelPhase.hidden);
      expect(
        _controller(initiallyHidden: true, initiallyExpanded: true).phase,
        PanelPhase.hidden,
      );
    });
  });

  group('commands', () {
    test('expand, collapse, and toggle drive the morph phases', () {
      final controller = _controller()..expand();
      expect(controller.phase, PanelPhase.expanding);

      controller.dispatch(const PanelMorphCompleted());
      expect(controller.phase, PanelPhase.expanded);

      controller.toggle();
      expect(controller.phase, PanelPhase.collapsing);

      controller.dispatch(const PanelMorphCompleted());
      expect(controller.phase, PanelPhase.collapsed);
    });

    test('moveTo settles towards the requested placement', () {
      final controller = _controller()..moveTo(_topStart);

      expect(controller.phase, PanelPhase.settling);
      expect(controller.placement, _topStart);
    });

    test('hide keeps the placement for the next show', () {
      final controller = _controller(initialPlacement: _topStart)..hide();
      expect(controller.placement, _topStart);

      controller.show();
      expect(controller.phase, PanelPhase.settling);
      expect(controller.placement, _topStart);
    });
  });

  group('stash', () {
    test('defaults to the side the panel already sits on', () {
      final controller = _controller(initialPlacement: _topStart)..stash();

      expect(
        controller.placement,
        const PanelPlacement.stashed(PanelEdge.start, verticalAlignment: -1),
      );
    });

    test('keeps the vertical half it was on', () {
      final controller = _controller()..stash();

      expect(
        controller.placement,
        const PanelPlacement.stashed(PanelEdge.end, verticalAlignment: 1),
      );
    });

    test('honours an explicit edge', () {
      final controller = _controller(initialPlacement: _topStart)
        ..stash(PanelEdge.end);

      expect(
        controller.placement,
        const PanelPlacement.stashed(PanelEdge.end, verticalAlignment: -1),
      );
    });

    test('is refused when stashing is disabled', () {
      final controller = _controller()
        ..behavior = const PanelBehavior(stashable: false)
        ..stash();

      expect(controller.phase, PanelPhase.collapsed);
    });

    test('unstash returns to the side and height it was parked at', () {
      final controller = _controller(initialPlacement: _topStart)
        ..stash()
        ..dispatch(const PanelSettleCompleted());
      expect(controller.phase, PanelPhase.stashed);

      controller.unstash();
      expect(controller.phase, PanelPhase.settling);

      final placement = controller.placement as FreePlacement;
      final alignment = placement.alignment.resolve(TextDirection.ltr);
      expect(alignment.x, -1, reason: 'same side it was parked on');
      expect(alignment.y, -1, reason: 'same height it was parked at');
    });

    test('unstash keeps a mid-height tab at its own height', () {
      final controller = _controller()
        ..dispatch(
          const PanelStashRequested(PanelEdge.end, verticalAlignment: -0.25),
        )
        ..dispatch(const PanelSettleCompleted())
        ..unstash();

      final placement = controller.placement as FreePlacement;
      final alignment = placement.alignment.resolve(TextDirection.ltr);
      expect(alignment.x, 1);
      expect(alignment.y, closeTo(-0.25, 1e-9));
    });

    test('unstash on an unstashed panel does nothing', () {
      final controller = _controller()..unstash();

      expect(controller.phase, PanelPhase.collapsed);
      expect(controller.placement, _bottomEnd);
    });

    test('expand while stashed unstashes first, then expands', () {
      final controller = _controller(initialPlacement: _topStart)
        ..stash()
        ..dispatch(const PanelSettleCompleted())
        ..expand();

      expect(controller.phase, PanelPhase.settling);
      expect(controller.placement, isA<FreePlacement>());

      controller.dispatch(const PanelSettleCompleted());
      expect(controller.phase, PanelPhase.expanding);
    });

    test('a drag during the deferred expand cancels it', () {
      final controller = _controller()
        ..stash()
        ..dispatch(const PanelSettleCompleted())
        ..expand()
        ..dispatch(const PanelDragStarted())
        ..dispatch(const PanelDragSettled(_topStart))
        ..dispatch(const PanelSettleCompleted());

      expect(controller.phase, PanelPhase.collapsed);
    });
  });

  group('notification volume', () {
    test('a full drag emits exactly three notifications', () {
      final controller = _controller();
      var notifications = 0;
      controller
        ..addListener(() => notifications++)
        ..dispatch(const PanelDragStarted())
        ..dispatch(const PanelDragSettled(_topStart))
        ..dispatch(const PanelSettleCompleted());

      expect(notifications, 3);
    });

    test('a no-op command notifies nobody', () {
      final controller = _controller();
      var notifications = 0;
      controller
        ..addListener(() => notifications++)
        ..collapse()
        ..unstash()
        ..show();

      expect(notifications, 0);
    });

    test('moving to the placement it already holds notifies nobody', () {
      final controller = _controller(initialPlacement: _topStart);
      var notifications = 0;
      controller
        ..addListener(() => notifications++)
        ..dispatch(const PanelMoveRequested(_topStart));

      expect(notifications, 1);
      expect(controller.phase, PanelPhase.settling);

      controller.dispatch(const PanelMoveRequested(_topStart));
      expect(notifications, 1);
    });
  });

  group('derived listenables', () {
    test('placementListenable stays quiet while only the phase moves', () {
      final controller = _controller();
      var placements = 0;
      controller.placementListenable.addListener(() => placements++);

      controller
        ..expand()
        ..dispatch(const PanelMorphCompleted())
        ..collapse()
        ..dispatch(const PanelMorphCompleted());

      expect(placements, 0);
      expect(controller.placementListenable.value, _bottomEnd);
    });

    test('placementListenable reports a real move once', () {
      final controller = _controller();
      var placements = 0;
      controller.placementListenable.addListener(() => placements++);

      controller
        ..moveTo(_topStart)
        ..dispatch(const PanelSettleCompleted());

      expect(placements, 1);
      expect(controller.placementListenable.value, _topStart);
    });

    test('placementListenable never reports a drag in progress', () {
      final controller = _controller();
      final seen = <PanelPlacement>[];
      controller.placementListenable.addListener(
        () => seen.add(controller.placementListenable.value),
      );

      controller
        ..dispatch(const PanelDragStarted())
        ..dispatch(const PanelDragSettled(_topStart))
        ..dispatch(const PanelSettleCompleted());

      expect(seen, [_topStart]);
    });

    test('phaseListenable tracks the phase', () {
      final controller = _controller();
      final seen = <PanelPhase>[];
      controller.phaseListenable.addListener(
        () => seen.add(controller.phaseListenable.value),
      );

      controller
        ..expand()
        ..dispatch(const PanelMorphCompleted());

      expect(seen, [PanelPhase.expanding, PanelPhase.expanded]);
    });
  });

  group('lifecycle', () {
    test('dispatching after dispose trips an assertion', () {
      final controller = DraggablePanelController()..dispose();

      expect(controller.expand, throwsA(isA<AssertionError>()));
    });

    test('derived listenables stop tracking after dispose', () {
      final controller = DraggablePanelController();
      var placements = 0;
      controller.placementListenable.addListener(() => placements++);
      controller.dispose();

      expect(placements, 0);
    });
  });
}
