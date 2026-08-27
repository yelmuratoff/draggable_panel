import 'package:draggable_panel/src/model/panel_phase.dart';
import 'package:draggable_panel/src/model/panel_placement.dart';
import 'package:draggable_panel/src/model/panel_status.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// Fires haptic feedback at the moments a panel commits to something.
///
/// Feedback is emitted when the decision is taken, not when the animation that
/// follows it ends — a haptic that lags its cause reads as system lag, and
/// firing at commit also makes it immune to the animation being interrupted.
///
/// Corner snapping is deliberately silent: the system Picture-in-Picture window
/// is, and a critically damped spring has no impact for a tap to sync with.
final class PanelHaptics {
  PanelHaptics({this.minimumInterval = const Duration(milliseconds: 80)});

  /// Floor between two taps, so a run of transitions cannot buzz continuously.
  final Duration minimumInterval;

  Duration _lastFiredAt = Duration.zero;
  bool _hasFired = false;

  /// Emits feedback for the transition from [previous] to [next], if any.
  ///
  /// Does nothing when [enabled] is false. Note that this is independent of any
  /// reduced-motion preference: when motion is suppressed the haptic carries
  /// more of the feedback, not less.
  void onTransition(
    PanelStatus? previous,
    PanelStatus next, {
    required bool enabled,
  }) {
    if (!enabled || previous == null) return;
    if (previous.phase == next.phase && previous.placement == next.placement) {
      return;
    }

    final effect = _effectFor(previous, next);
    if (effect == null) return;

    final now = SchedulerBinding.instance.currentSystemFrameTimeStamp;
    if (_hasFired && now - _lastFiredAt < minimumInterval) return;
    _hasFired = true;
    _lastFiredAt = now;
    effect();
  }

  /// Clears the rate limit so a fresh gesture is never muted by the last one.
  void reset() => _hasFired = false;

  VoidCallback? _effectFor(PanelStatus previous, PanelStatus next) {
    final becomingStashed =
        next.placement is StashedPlacement &&
        previous.placement is! StashedPlacement;
    final leavingStash =
        previous.placement is StashedPlacement &&
        next.placement is! StashedPlacement;

    if (next.phase == PanelPhase.settling && becomingStashed) {
      return HapticFeedback.mediumImpact;
    }
    if (next.phase == PanelPhase.settling && leavingStash) {
      return HapticFeedback.lightImpact;
    }
    if (previous.phase != next.phase) {
      return switch (next.phase) {
        PanelPhase.expanding ||
        PanelPhase.collapsing => HapticFeedback.lightImpact,
        PanelPhase.hidden => HapticFeedback.selectionClick,
        _ => null,
      };
    }
    return null;
  }
}
