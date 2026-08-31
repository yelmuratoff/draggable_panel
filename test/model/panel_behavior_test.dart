import 'package:draggable_panel/src/model/panel_behavior.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('stages', () {
    test('a panel with no collapsed stage must be stashable', () {
      expect(
        () => PanelBehavior(collapsible: false, stashable: false),
        throwsA(isA<AssertionError>()),
        reason: 'it would have no closed stage left to reach',
      );
    });

    test('either stage may be dropped on its own', () {
      expect(() => const PanelBehavior(collapsible: false), returnsNormally);
      expect(() => const PanelBehavior(stashable: false), returnsNormally);
    });
  });

  group('value semantics', () {
    test('copyWith carries every field through', () {
      const original = PanelBehavior();
      final changed = original.copyWith(collapsible: false);

      expect(changed.collapsible, isFalse);
      expect(changed, isNot(original));
      expect(changed.copyWith(collapsible: true), original);
    });

    test('copyWith switches the idle timer off, which a null cannot say', () {
      const original = PanelBehavior();
      expect(original.idleStashDelay, isNotNull);

      expect(
        original.copyWith(clearIdleStashDelay: true).idleStashDelay,
        isNull,
      );
      expect(
        original.copyWith(hapticsEnabled: false).idleStashDelay,
        original.idleStashDelay,
        reason: 'an untouched delay survives an unrelated copyWith',
      );
    });

    test('copyWith retunes the idle delay', () {
      const delay = Duration(seconds: 30);
      final changed = const PanelBehavior().copyWith(idleStashDelay: delay);

      expect(changed.idleStashDelay, delay);
    });
  });
}
