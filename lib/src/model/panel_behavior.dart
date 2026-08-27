import 'package:flutter/foundation.dart';

/// Where a panel is allowed to come to rest after a drag.
enum PanelSnapPolicy {
  /// Settles into the nearest of the four corners.
  corners,

  /// Settles against the nearest side at whatever height it was left.
  ///
  /// The default: a panel parks anywhere down the edge rather than being
  /// herded into one of four corners.
  edges,

  /// Stays wherever momentum carries it, within bounds.
  free,
}

/// Which interactions a panel accepts.
///
/// These are configuration, not state: they gate which transitions are legal
/// but never change on their own.
@immutable
final class PanelBehavior {
  const PanelBehavior({
    this.draggable = true,
    this.tapToExpand = true,
    this.stashable = true,
    this.dismissible = false,
    this.collapseOnTapOutside = true,
    this.stashOnTapOutside = true,
    this.idleStashDelay = const Duration(seconds: 5),
    this.avoidKeyboard = true,
    this.hapticsEnabled = true,
    this.snapPolicy = PanelSnapPolicy.edges,
  });

  /// Whether the collapsed panel can be dragged around.
  final bool draggable;

  /// Whether tapping the collapsed panel expands it.
  final bool tapToExpand;

  /// Whether dragging the panel against a side edge parks it there.
  ///
  /// A parked panel keeps its size and simply sits mostly off-screen, so
  /// dragging it back out returns exactly what was put away.
  final bool stashable;

  /// Whether flinging the panel clear of the viewport hides it.
  ///
  /// Off by default: system Picture-in-Picture uses an explicit close control
  /// rather than a fling-away, because an accidental dismissal is expensive.
  final bool dismissible;

  /// Whether tapping outside an expanded panel collapses it.
  final bool collapseOnTapOutside;

  /// Whether touching anywhere off a collapsed panel parks it at its edge.
  ///
  /// Observed rather than intercepted, so the touch still reaches whatever it
  /// landed on.
  final bool stashOnTapOutside;

  /// How long a collapsed panel waits, untouched, before parking itself.
  ///
  /// Null keeps it out until it is put away by hand. Only a collapsed panel
  /// parks on its own: an expanded one is holding content someone is reading.
  final Duration? idleStashDelay;

  /// Whether the panel keeps clear of the software keyboard while expanded.
  final bool avoidKeyboard;

  /// Whether committed transitions fire haptic feedback.
  ///
  /// Independent of reduced motion: when animation is suppressed the haptic
  /// carries more of the feedback, not less.
  final bool hapticsEnabled;

  /// Where the panel settles after a drag.
  final PanelSnapPolicy snapPolicy;

  PanelBehavior copyWith({
    bool? draggable,
    bool? tapToExpand,
    bool? stashable,
    bool? dismissible,
    bool? collapseOnTapOutside,
    bool? stashOnTapOutside,
    Duration? idleStashDelay,
    bool? avoidKeyboard,
    bool? hapticsEnabled,
    PanelSnapPolicy? snapPolicy,
  }) => PanelBehavior(
    draggable: draggable ?? this.draggable,
    tapToExpand: tapToExpand ?? this.tapToExpand,
    stashable: stashable ?? this.stashable,
    dismissible: dismissible ?? this.dismissible,
    collapseOnTapOutside: collapseOnTapOutside ?? this.collapseOnTapOutside,
    stashOnTapOutside: stashOnTapOutside ?? this.stashOnTapOutside,
    idleStashDelay: idleStashDelay ?? this.idleStashDelay,
    avoidKeyboard: avoidKeyboard ?? this.avoidKeyboard,
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    snapPolicy: snapPolicy ?? this.snapPolicy,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PanelBehavior &&
          other.draggable == draggable &&
          other.tapToExpand == tapToExpand &&
          other.stashable == stashable &&
          other.dismissible == dismissible &&
          other.collapseOnTapOutside == collapseOnTapOutside &&
          other.stashOnTapOutside == stashOnTapOutside &&
          other.idleStashDelay == idleStashDelay &&
          other.avoidKeyboard == avoidKeyboard &&
          other.hapticsEnabled == hapticsEnabled &&
          other.snapPolicy == snapPolicy;

  @override
  int get hashCode => Object.hash(
    draggable,
    tapToExpand,
    stashable,
    dismissible,
    collapseOnTapOutside,
    stashOnTapOutside,
    idleStashDelay,
    avoidKeyboard,
    hapticsEnabled,
    snapPolicy,
  );
}
