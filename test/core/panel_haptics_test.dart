import 'package:draggable_panel/src/core/panel_haptics.dart';
import 'package:draggable_panel/src/model/panel_corner.dart';
import 'package:draggable_panel/src/model/panel_edge.dart';
import 'package:draggable_panel/src/model/panel_phase.dart';
import 'package:draggable_panel/src/model/panel_placement.dart';
import 'package:draggable_panel/src/model/panel_status.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _corner = PanelPlacement.corner(PanelCorner.bottomEnd);
const _otherCorner = PanelPlacement.corner(PanelCorner.topStart);
const _stashed = PanelPlacement.stashed(PanelEdge.start);

PanelStatus _status(PanelPhase phase, [PanelPlacement placement = _corner]) =>
    PanelStatus(phase: phase, placement: placement);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> fired;

  setUp(() {
    fired = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            fired.add((call.arguments as String?) ?? 'vibrate');
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  /// Fires a transition and returns the effects it produced.
  Future<List<String>> transition(
    PanelStatus from,
    PanelStatus to, {
    bool enabled = true,
    PanelHaptics? haptics,
  }) async {
    (haptics ?? PanelHaptics()).onTransition(from, to, enabled: enabled);
    await Future<void>.delayed(Duration.zero);
    return fired;
  }

  group('which transitions speak', () {
    test('committing to a stash is a medium impact', () async {
      expect(
        await transition(
          _status(PanelPhase.dragging),
          _status(PanelPhase.settling, _stashed),
        ),
        ['HapticFeedbackType.mediumImpact'],
      );
    });

    test('leaving a stash is a light impact', () async {
      expect(
        await transition(
          _status(PanelPhase.stashed, _stashed),
          _status(PanelPhase.settling, _otherCorner),
        ),
        ['HapticFeedbackType.lightImpact'],
      );
    });

    test('expanding and collapsing are light impacts', () async {
      expect(
        await transition(
          _status(PanelPhase.collapsed),
          _status(PanelPhase.expanding),
        ),
        ['HapticFeedbackType.lightImpact'],
      );

      fired.clear();
      expect(
        await transition(
          _status(PanelPhase.expanded),
          _status(PanelPhase.collapsing),
        ),
        ['HapticFeedbackType.lightImpact'],
      );
    });

    test('hiding is a selection click', () async {
      expect(
        await transition(
          _status(PanelPhase.collapsed),
          _status(PanelPhase.hidden),
        ),
        ['HapticFeedbackType.selectionClick'],
      );
    });
  });

  group('which transitions stay silent', () {
    test('a corner snap says nothing', () async {
      expect(
        await transition(
          _status(PanelPhase.dragging),
          _status(PanelPhase.settling, _otherCorner),
        ),
        isEmpty,
      );
    });

    test('arriving at rest says nothing — the commit already spoke', () async {
      expect(
        await transition(
          _status(PanelPhase.settling),
          _status(PanelPhase.collapsed),
        ),
        isEmpty,
      );
      expect(
        await transition(
          _status(PanelPhase.expanding),
          _status(PanelPhase.expanded),
        ),
        isEmpty,
      );
    });

    test('picking the panel up says nothing', () async {
      expect(
        await transition(
          _status(PanelPhase.collapsed),
          _status(PanelPhase.dragging),
        ),
        isEmpty,
      );
    });

    test('an unchanged status says nothing', () async {
      expect(
        await transition(
          _status(PanelPhase.collapsed),
          _status(PanelPhase.collapsed),
        ),
        isEmpty,
      );
    });

    test('the very first status says nothing', () async {
      PanelHaptics().onTransition(
        null,
        _status(PanelPhase.expanding),
        enabled: true,
      );
      await Future<void>.delayed(Duration.zero);

      expect(fired, isEmpty);
    });

    test('disabled haptics say nothing', () async {
      expect(
        await transition(
          _status(PanelPhase.collapsed),
          _status(PanelPhase.expanding),
          enabled: false,
        ),
        isEmpty,
      );
    });
  });

  group('rate limiting', () {
    test('a burst of transitions cannot buzz continuously', () async {
      final haptics = PanelHaptics();

      await transition(
        _status(PanelPhase.collapsed),
        _status(PanelPhase.expanding),
        haptics: haptics,
      );
      await transition(
        _status(PanelPhase.expanding),
        _status(PanelPhase.collapsing),
        haptics: haptics,
      );
      await transition(
        _status(PanelPhase.collapsing),
        _status(PanelPhase.expanding),
        haptics: haptics,
      );

      expect(
        fired,
        hasLength(1),
        reason: 'only the first of a rapid burst should be felt',
      );
    });

    test('reset lets a fresh gesture speak again', () async {
      final haptics = PanelHaptics();

      await transition(
        _status(PanelPhase.collapsed),
        _status(PanelPhase.expanding),
        haptics: haptics,
      );
      haptics.reset();
      await transition(
        _status(PanelPhase.expanding),
        _status(PanelPhase.collapsing),
        haptics: haptics,
      );

      expect(fired, hasLength(2));
    });
  });
}
