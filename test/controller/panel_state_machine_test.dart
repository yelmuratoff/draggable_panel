import 'package:draggable_panel/src/controller/panel_event.dart';
import 'package:draggable_panel/src/controller/panel_state_machine.dart';
import 'package:draggable_panel/src/model/panel_behavior.dart';
import 'package:draggable_panel/src/model/panel_corner.dart';
import 'package:draggable_panel/src/model/panel_edge.dart';
import 'package:draggable_panel/src/model/panel_phase.dart';
import 'package:draggable_panel/src/model/panel_placement.dart';
import 'package:draggable_panel/src/model/panel_status.dart';
import 'package:flutter_test/flutter_test.dart';

const _corner = PanelPlacement.corner(PanelCorner.bottomEnd);
const _otherCorner = PanelPlacement.corner(PanelCorner.topStart);
const _stashed = PanelPlacement.stashed(PanelEdge.start);
const _behavior = PanelBehavior();

PanelStatus _status(PanelPhase phase, [PanelPlacement placement = _corner]) =>
    PanelStatus(phase: phase, placement: placement);

PanelPhase _phaseAfter(
  PanelPhase from,
  PanelEvent event, {
  PanelBehavior behavior = _behavior,
  PanelPlacement placement = _corner,
}) => panelTransition(_status(from, placement), event, behavior).phase;

void main() {
  const events = <PanelEvent>[
    PanelDragStarted(),
    PanelDragSettled(_otherCorner),
    PanelDragCancelled(),
    PanelSettleCompleted(),
    PanelMorphCompleted(),
    PanelExpandRequested(),
    PanelCollapseRequested(),
    PanelToggleRequested(),
    PanelMoveRequested(_otherCorner),
    PanelStashRequested(PanelEdge.start),
    PanelUnstashRequested(_otherCorner),
    PanelHideRequested(),
    PanelShowRequested(),
    PanelDismissRequested(),
  ];

  group('totality', () {
    test('every phase accepts every event without throwing', () {
      for (final phase in PanelPhase.values) {
        for (final event in events) {
          expect(
            () => panelTransition(_status(phase), event, _behavior),
            returnsNormally,
            reason: '$phase + ${event.runtimeType}',
          );
        }
      }
    });

    test('expanded accepts only its documented events', () {
      const accepted = <Type>{
        PanelCollapseRequested,
        PanelToggleRequested,
        PanelHideRequested,
        PanelMoveRequested,
        PanelStashRequested,
      };

      for (final event in events) {
        final before = _status(PanelPhase.expanded);
        final after = panelTransition(before, event, _behavior);

        expect(
          after != before,
          accepted.contains(event.runtimeType),
          reason: '${event.runtimeType} from expanded',
        );
      }
    });
  });

  group('drag', () {
    test('starts only from a collapsed-family phase', () {
      const start = PanelDragStarted();

      expect(_phaseAfter(PanelPhase.collapsed, start), PanelPhase.dragging);
      expect(_phaseAfter(PanelPhase.settling, start), PanelPhase.dragging);
      expect(_phaseAfter(PanelPhase.stashed, start), PanelPhase.dragging);
    });

    test('cannot start from an expanded or morphing phase', () {
      const start = PanelDragStarted();

      expect(_phaseAfter(PanelPhase.expanded, start), PanelPhase.expanded);
      expect(_phaseAfter(PanelPhase.expanding, start), PanelPhase.expanding);
      expect(_phaseAfter(PanelPhase.collapsing, start), PanelPhase.collapsing);
      expect(_phaseAfter(PanelPhase.hidden, start), PanelPhase.hidden);
    });

    test('cannot start when the panel is not draggable', () {
      expect(
        _phaseAfter(
          PanelPhase.collapsed,
          const PanelDragStarted(),
          behavior: const PanelBehavior(draggable: false),
        ),
        PanelPhase.collapsed,
      );
    });

    test('release adopts the resolved target', () {
      final after = panelTransition(
        _status(PanelPhase.dragging),
        const PanelDragSettled(_otherCorner),
        _behavior,
      );

      expect(after.phase, PanelPhase.settling);
      expect(after.placement, _otherCorner);
    });

    test('release outside a drag is ignored', () {
      final before = _status(PanelPhase.collapsed);

      expect(
        panelTransition(
          before,
          const PanelDragSettled(_otherCorner),
          _behavior,
        ),
        before,
      );
    });

    test('cancel settles back to where the drag began', () {
      final after = panelTransition(
        _status(PanelPhase.dragging),
        const PanelDragCancelled(),
        _behavior,
      );

      expect(after.phase, PanelPhase.settling);
      expect(after.placement, _corner);
    });
  });

  group('settling', () {
    test('completes to collapsed for a corner placement', () {
      expect(
        _phaseAfter(PanelPhase.settling, const PanelSettleCompleted()),
        PanelPhase.collapsed,
      );
    });

    test('completes to stashed for a stashed placement', () {
      expect(
        _phaseAfter(
          PanelPhase.settling,
          const PanelSettleCompleted(),
          placement: _stashed,
        ),
        PanelPhase.stashed,
      );
    });

    test('completion outside settling is ignored', () {
      expect(
        _phaseAfter(PanelPhase.collapsed, const PanelSettleCompleted()),
        PanelPhase.collapsed,
      );
    });
  });

  group('morph', () {
    test('expands from collapsed and from settling', () {
      const expand = PanelExpandRequested();

      expect(_phaseAfter(PanelPhase.collapsed, expand), PanelPhase.expanding);
      expect(_phaseAfter(PanelPhase.settling, expand), PanelPhase.expanding);
    });

    test('cannot expand directly out of a stash', () {
      expect(
        _phaseAfter(
          PanelPhase.stashed,
          const PanelExpandRequested(),
          placement: _stashed,
        ),
        PanelPhase.stashed,
      );
    });

    test('reverses mid-flight in both directions', () {
      expect(
        _phaseAfter(PanelPhase.expanding, const PanelCollapseRequested()),
        PanelPhase.collapsing,
      );
      expect(
        _phaseAfter(PanelPhase.collapsing, const PanelExpandRequested()),
        PanelPhase.expanding,
      );
    });

    test('completes to the phase it was heading towards', () {
      const done = PanelMorphCompleted();

      expect(_phaseAfter(PanelPhase.expanding, done), PanelPhase.expanded);
      expect(_phaseAfter(PanelPhase.collapsing, done), PanelPhase.collapsed);
      expect(_phaseAfter(PanelPhase.collapsed, done), PanelPhase.collapsed);
    });

    test('toggle picks the opposite direction', () {
      const toggle = PanelToggleRequested();

      expect(_phaseAfter(PanelPhase.collapsed, toggle), PanelPhase.expanding);
      expect(_phaseAfter(PanelPhase.expanded, toggle), PanelPhase.collapsing);
      expect(_phaseAfter(PanelPhase.expanding, toggle), PanelPhase.collapsing);
      expect(_phaseAfter(PanelPhase.collapsing, toggle), PanelPhase.expanding);
    });

    test('a full expand and collapse cycle returns to collapsed', () {
      var status = _status(PanelPhase.collapsed);
      for (final event in const <PanelEvent>[
        PanelExpandRequested(),
        PanelMorphCompleted(),
        PanelCollapseRequested(),
        PanelMorphCompleted(),
      ]) {
        status = panelTransition(status, event, _behavior);
      }

      expect(status, _status(PanelPhase.collapsed));
    });
  });

  group('stash', () {
    test('settles towards a stashed placement', () {
      final after = panelTransition(
        _status(PanelPhase.collapsed),
        const PanelStashRequested(PanelEdge.end, verticalAlignment: -0.5),
        _behavior,
      );

      expect(after.phase, PanelPhase.settling);
      expect(
        after.placement,
        const PanelPlacement.stashed(PanelEdge.end, verticalAlignment: -0.5),
      );
    });

    test('is refused when stashing is disabled', () {
      expect(
        _phaseAfter(
          PanelPhase.collapsed,
          const PanelStashRequested(PanelEdge.start),
          behavior: const PanelBehavior(stashable: false),
        ),
        PanelPhase.collapsed,
      );
    });

    test('closes an expanded panel on its way to the edge', () {
      for (final phase in const [
        PanelPhase.expanded,
        PanelPhase.expanding,
        PanelPhase.collapsing,
      ]) {
        final after = panelTransition(
          _status(phase),
          const PanelStashRequested(PanelEdge.start),
          _behavior,
        );

        expect(after.phase, PanelPhase.settling, reason: 'stash from $phase');
        expect(after.placement, _stashed, reason: 'stash from $phase');
      }
    });

    test('is refused while hidden or already parked', () {
      expect(
        _phaseAfter(
          PanelPhase.hidden,
          const PanelStashRequested(PanelEdge.start),
        ),
        PanelPhase.hidden,
      );
      expect(
        _phaseAfter(
          PanelPhase.stashed,
          const PanelStashRequested(PanelEdge.start),
          placement: _stashed,
        ),
        PanelPhase.stashed,
      );
    });

    test('moving an expanded panel to a park closes it too', () {
      final after = panelTransition(
        _status(PanelPhase.expanded),
        const PanelMoveRequested(_stashed),
        _behavior,
      );

      expect(after.phase, PanelPhase.settling);
      expect(after.placement, _stashed);
    });

    test('unstash settles to the given target', () {
      final after = panelTransition(
        _status(PanelPhase.stashed, _stashed),
        const PanelUnstashRequested(_otherCorner),
        _behavior,
      );

      expect(after.phase, PanelPhase.settling);
      expect(after.placement, _otherCorner);
    });

    test('unstash outside a stash is ignored', () {
      expect(
        _phaseAfter(
          PanelPhase.collapsed,
          const PanelUnstashRequested(_otherCorner),
        ),
        PanelPhase.collapsed,
      );
    });
  });

  group('expandOnUnstash', () {
    const behavior = PanelBehavior(expandOnUnstash: true);

    test('opens the panel on the way out of a park', () {
      expect(
        _phaseAfter(
          PanelPhase.stashed,
          const PanelUnstashRequested(_otherCorner),
          behavior: behavior,
          placement: _stashed,
        ),
        PanelPhase.expanding,
      );
      expect(
        _phaseAfter(
          PanelPhase.dragging,
          const PanelDragSettled(_otherCorner),
          behavior: behavior,
          placement: _stashed,
        ),
        PanelPhase.expanding,
        reason: 'dragging the tab out is the same journey',
      );
    });

    test('shortens only that journey, leaving the stage in place', () {
      expect(
        _phaseAfter(
          PanelPhase.dragging,
          const PanelDragSettled(_otherCorner),
          behavior: behavior,
        ),
        PanelPhase.settling,
        reason: 'a move between corners still rests collapsed',
      );
      expect(
        _phaseAfter(
          PanelPhase.expanded,
          const PanelCollapseRequested(),
          behavior: behavior,
        ),
        PanelPhase.collapsing,
        reason: 'the collapsed stage is still somewhere to close to',
      );
    });

    test('arriving at a park still settles', () {
      expect(
        _phaseAfter(
          PanelPhase.dragging,
          const PanelDragSettled(_stashed),
          behavior: behavior,
          placement: _stashed,
        ),
        PanelPhase.settling,
      );
    });
  });

  group('without a collapsed stage', () {
    const behavior = PanelBehavior(collapsible: false);

    test('leaving a park opens the panel instead of settling', () {
      expect(
        _phaseAfter(
          PanelPhase.stashed,
          const PanelUnstashRequested(_otherCorner),
          behavior: behavior,
          placement: _stashed,
        ),
        PanelPhase.expanding,
      );
      expect(
        _phaseAfter(
          PanelPhase.dragging,
          const PanelDragSettled(_otherCorner),
          behavior: behavior,
          placement: _stashed,
        ),
        PanelPhase.expanding,
      );
    });

    test('arriving at a park still settles', () {
      expect(
        _phaseAfter(
          PanelPhase.dragging,
          const PanelDragSettled(_stashed),
          behavior: behavior,
          placement: _stashed,
        ),
        PanelPhase.settling,
      );
    });

    test('collapsing is refused outright', () {
      expect(
        _phaseAfter(
          PanelPhase.expanded,
          const PanelCollapseRequested(),
          behavior: behavior,
        ),
        PanelPhase.expanded,
      );
    });

    test('the collapsed phase is unreachable, whatever it is sent', () {
      final reachable = <PanelStatus>{
        _status(PanelPhase.stashed, _stashed),
        _status(PanelPhase.expanded),
      };
      final pending = [...reachable];

      while (pending.isNotEmpty) {
        final current = pending.removeLast();
        for (final event in events) {
          final next = panelTransition(current, event, behavior);
          if (reachable.add(next)) pending.add(next);
        }
      }

      expect(
        reachable.map((status) => status.phase).toSet(),
        isNot(contains(PanelPhase.collapsed)),
        reason: 'searched ${reachable.length} reachable statuses',
      );
    });
  });

  group('visibility', () {
    test('hide works from every phase', () {
      for (final phase in PanelPhase.values) {
        expect(
          _phaseAfter(phase, const PanelHideRequested()),
          PanelPhase.hidden,
          reason: 'hide from $phase',
        );
      }
    });

    test('show springs a hidden panel back to its placement', () {
      final after = panelTransition(
        _status(PanelPhase.hidden, _otherCorner),
        const PanelShowRequested(),
        _behavior,
      );

      expect(after.phase, PanelPhase.settling);
      expect(after.placement, _otherCorner);
    });

    test('show is ignored when already visible', () {
      expect(
        _phaseAfter(PanelPhase.collapsed, const PanelShowRequested()),
        PanelPhase.collapsed,
      );
    });

    test('dismiss only applies when dismissible', () {
      expect(
        _phaseAfter(PanelPhase.dragging, const PanelDismissRequested()),
        PanelPhase.dragging,
      );
      expect(
        _phaseAfter(
          PanelPhase.dragging,
          const PanelDismissRequested(),
          behavior: const PanelBehavior(dismissible: true),
        ),
        PanelPhase.hidden,
      );
    });
  });

  group('move', () {
    test('settles a visible panel towards the target', () {
      final after = panelTransition(
        _status(PanelPhase.collapsed),
        const PanelMoveRequested(_otherCorner),
        _behavior,
      );

      expect(after.phase, PanelPhase.settling);
      expect(after.placement, _otherCorner);
    });

    test('retargets a hidden panel without revealing it', () {
      final after = panelTransition(
        _status(PanelPhase.hidden),
        const PanelMoveRequested(_otherCorner),
        _behavior,
      );

      expect(after.phase, PanelPhase.hidden);
      expect(after.placement, _otherCorner);
    });

    test('relocates an expanded panel without closing it', () {
      final after = panelTransition(
        _status(PanelPhase.expanded),
        const PanelMoveRequested(_otherCorner),
        _behavior,
      );

      expect(after.phase, PanelPhase.expanded);
      expect(after.placement, _otherCorner);
    });

    test('never fights a live drag', () {
      final before = _status(PanelPhase.dragging);

      expect(
        panelTransition(
          before,
          const PanelMoveRequested(_otherCorner),
          _behavior,
        ),
        before,
      );
    });
  });
}
