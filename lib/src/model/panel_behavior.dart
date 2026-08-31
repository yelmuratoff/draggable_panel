import 'package:draggable_panel/src/model/panel_placement.dart';
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
///
/// [stashable] and [collapsible] are the two optional *stages* rather than
/// gates on one gesture: turning either off removes that resting place
/// entirely, and every route into it — a gesture, a timer, a command — lands on
/// the next stage instead.
@immutable
final class PanelBehavior {
  const PanelBehavior({
    this.draggable = true,
    this.tapToExpand = true,
    this.stashable = true,
    this.collapsible = true,
    this.expandOnUnstash = false,
    this.dismissible = false,
    this.collapseOnTapOutside = true,
    this.stashOnTapOutside = true,
    this.idleStashDelay = const Duration(seconds: 5),
    this.avoidKeyboard = true,
    this.hapticsEnabled = true,
    this.snapPolicy = PanelSnapPolicy.edges,
  }) : assert(
         collapsible || stashable,
         'A panel with no collapsed stage must be stashable, because parking '
         'is then the only closed stage it has left.',
       );

  /// Whether the collapsed panel can be dragged around.
  final bool draggable;

  /// Whether tapping the collapsed panel expands it.
  final bool tapToExpand;

  /// Whether dragging the panel against a side edge parks it there.
  ///
  /// A parked panel keeps its size and simply sits mostly off-screen, so
  /// dragging it back out returns exactly what was put away.
  final bool stashable;

  /// Whether the panel has a collapsed resting stage — the small window it
  /// sits in between a park and being open.
  ///
  /// Turn it off and the panel has two stages instead of three: it is either
  /// parked at an edge or open. Coming out of a park it grows while it slides
  /// out, in one motion, and closing it parks it again, because parking is
  /// then its only closed stage. [PanelPhase.collapsed] is never entered.
  ///
  /// Requires [stashable], since the panel would otherwise have nowhere to
  /// close to.
  final bool collapsible;

  /// Whether pulling the panel out of a park opens it, instead of stopping at
  /// the collapsed window on the way.
  ///
  /// Narrower than [collapsible]: the collapsed stage stays, so the panel is
  /// still a small window you can drag around and close back down to. Only the
  /// journey out of a park is shortened — it grows while it slides out, in one
  /// motion. Reach for this when a park is how the panel is put away and taking
  /// it out always means using it; reach for `collapsible: false` when the
  /// small window has no purpose at all.
  ///
  /// Implied by `collapsible: false`, and inert without [stashable].
  final bool expandOnUnstash;

  /// Whether flinging the panel clear of the viewport hides it.
  ///
  /// Off by default: a floating window is better closed through an explicit
  /// control than a fling-away, because an accidental dismissal is expensive.
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

  /// Whether coming to rest anywhere but a park opens the panel, rather than
  /// leaving it as the small window.
  ///
  /// True when the stage model has no collapsed window to arrive in — either
  /// because [collapsible] switched it off, or because the journey leaves a
  /// park and [expandOnUnstash] shortens that one route. The release layer
  /// reads it too: with no window to rest in at a side, coming to rest against
  /// one can only mean parking there.
  @internal
  bool opensOnArrivalFrom(PanelPlacement from) {
    if (!collapsible) return true;
    return expandOnUnstash && from is StashedPlacement;
  }

  /// Returns a copy with the given fields replaced.
  ///
  /// [idleStashDelay] is the one field whose `null` is a value rather than
  /// "leave it alone", so passing null here keeps the current delay. Pass
  /// `clearIdleStashDelay: true` to switch the idle timer off instead.
  PanelBehavior copyWith({
    bool? draggable,
    bool? tapToExpand,
    bool? stashable,
    bool? collapsible,
    bool? expandOnUnstash,
    bool? dismissible,
    bool? collapseOnTapOutside,
    bool? stashOnTapOutside,
    Duration? idleStashDelay,
    bool clearIdleStashDelay = false,
    bool? avoidKeyboard,
    bool? hapticsEnabled,
    PanelSnapPolicy? snapPolicy,
  }) => PanelBehavior(
    draggable: draggable ?? this.draggable,
    tapToExpand: tapToExpand ?? this.tapToExpand,
    stashable: stashable ?? this.stashable,
    collapsible: collapsible ?? this.collapsible,
    expandOnUnstash: expandOnUnstash ?? this.expandOnUnstash,
    dismissible: dismissible ?? this.dismissible,
    collapseOnTapOutside: collapseOnTapOutside ?? this.collapseOnTapOutside,
    stashOnTapOutside: stashOnTapOutside ?? this.stashOnTapOutside,
    idleStashDelay: clearIdleStashDelay
        ? null
        : idleStashDelay ?? this.idleStashDelay,
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
          other.collapsible == collapsible &&
          other.expandOnUnstash == expandOnUnstash &&
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
    collapsible,
    expandOnUnstash,
    dismissible,
    collapseOnTapOutside,
    stashOnTapOutside,
    idleStashDelay,
    avoidKeyboard,
    hapticsEnabled,
    snapPolicy,
  );
}
