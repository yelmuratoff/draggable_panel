/// The discrete stage a panel is in.
///
/// Phases are mutually exclusive and gate which transitions are legal.
/// Continuous values — the panel's live offset and its expansion progress —
/// deliberately live in the motion layer instead, so moving the panel does not
/// produce a new phase on every frame.
enum PanelPhase {
  /// Off-stage entirely.
  hidden,

  /// Resting, settled, showing its collapsed content.
  collapsed,

  /// A pointer currently owns the panel.
  dragging,

  /// A spring is carrying the panel to a resting placement.
  settling,

  /// Parked off-screen against an edge, leaving a grab tab visible.
  stashed,

  /// Growing from collapsed towards expanded.
  expanding,

  /// Resting, settled, showing its expanded content.
  expanded,

  /// Shrinking from expanded back towards collapsed.
  collapsing;

  /// Whether the panel is settled rather than moving under a spring or finger.
  bool get isResting =>
      this == hidden ||
      this == collapsed ||
      this == stashed ||
      this == expanded;

  /// Whether the panel occupies its expanded rect, or is on the way there.
  bool get isExpanding => this == expanding || this == expanded;

  /// Whether any part of the panel is on-screen.
  bool get isVisible => this != hidden;
}
