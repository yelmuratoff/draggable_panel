# draggable_panel

[![pub package](https://img.shields.io/pub/v/draggable_panel.svg)](https://pub.dev/packages/draggable_panel)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A floating panel window for Flutter.

Collapsed, it is a small window you can drag anywhere. Release it and it springs
to the nearest side — chosen by where your momentum was _heading_, not where your
finger happened to let go. Flick it sideways past the edge and it parks
off-screen with a grab tab showing. Tap it and it grows in place into a full
panel, anchored at the corner it already occupies; tap again and it shrinks
back, reversible mid-flight.

No third-party dependencies.

| Floating                                                                           | Open                                                                  | Parked                                                                  |
| ---------------------------------------------------------------------------------- | --------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| ![A collapsed panel over a scrolling page](assets/screenshots/floating-window.png) | ![The panel grown in place](assets/screenshots/expanded-in-place.png) | ![The panel parked as a tab](assets/screenshots/parked-at-the-edge.png) |

## Getting started

```yaml
dependencies:
  draggable_panel: 4.0.0-beta.9
```

Pinned rather than `^`: a caret on a pre-release only sets a floor, and would
pull in whatever sorts above it.

Mount it above your app's content, usually through `MaterialApp.builder`:

```dart
MaterialApp(
  builder: (context, child) => DraggablePanel(
    collapsedBuilder: (context, status) => const Icon(Icons.play_arrow),
    expandedBuilder: (context, status) => const MiniPlayer(),
    child: child,
  ),
  home: const HomeScreen(),
)
```

Three arguments and you are done. Everything else has a defensible default.

The panel positions itself against the window, so give it the whole window —
`MaterialApp.builder`, or anything else that fills the screen. Mounted inside a
smaller box it will place itself against bounds it does not occupy.

## One gesture, one meaning

Dragging always **moves** the panel — whether it is a tab at the edge, a small
window at a corner, or open and showing content. Tapping toggles its content.
Nothing else is overloaded onto the drag, which is what keeps it predictable.

Everything else falls out of where you let go:

| Release the panel…               | and it…                                                |
| -------------------------------- | ------------------------------------------------------ |
| anywhere on screen               | springs to the nearest side, at the height you left it |
| against a side edge              | parks there, leaving a sliver you can grab             |
| clear off screen (`dismissible`) | goes away                                              |

This holds whether the panel is a small window or open and showing content: an
open panel pushed off the side closes as it goes, arriving at the edge as a tab,
and comes back out at the height it was at.

Where the panel has no small window to rest in — `collapsible: false`, or
`expandOnUnstash: true` on the way out of a park — a tab dragged along to
another edge parks there rather than opening. Aiming at an edge is putting the
panel away; releasing it clear of both edges is taking it out.

So parking and un-parking are not separate gestures — you just push the panel
off the edge, or pull it back. Its content fades with how much of it is on
screen, so a tab reveals what it holds as it emerges instead of arriving blank.

Start parked at an edge:

```dart
DraggablePanelController(
  initialPlacement: const PanelPlacement.stashed(PanelEdge.end),
)
```

## Which stages the panel has

Between parked and open the panel has three resting stages, and two of them are
optional. They are properties of the panel rather than gates on one gesture, so
dropping one removes it from _every_ route — a drag, a tap, the idle timer, a
command — instead of only the one you were thinking of.

| You want                                | Set                                 |
| --------------------------------------- | ----------------------------------- |
| tab → small window → open               | the default                         |
| tab → open, small window kept elsewhere | `expandOnUnstash: true`             |
| tab → open, small window gone entirely  | `collapsible: false`                |
| small window → open, never parks        | `stashable: false`                  |
| no travel animation between them        | `motion: PanelMotionSpec.instant()` |

The middle two are worth telling apart. `expandOnUnstash` shortens **one
journey** — the way out of a park — and leaves the small window as somewhere to
close down to and drag around. `collapsible: false` removes the **stage**, so
the window is gone from every route, including closing.

```dart
DraggablePanel(
  behavior: const PanelBehavior(collapsible: false),
  // …
)
```

`collapsible: false` leaves two stages: the panel grows _while_ it slides out of
the park, in one motion, and closing it — the close control, a tap outside, Esc —
parks it again, because a park is then the only closed stage it has.
`PanelPhase.collapsed` is never entered, which is asserted by an exhaustive
search over every reachable state, not merely intended. Dropping both stages at
once trips an assertion — a compile-time error for the usual `const
PanelBehavior(...)` — because the panel would have nowhere to close to.

The sliver draws its own grab affordance — a curve pointing the way the panel
comes out — which cross-fades into `collapsedBuilder`'s content as you pull, so
nothing appears at a threshold. Retint it with the `handleColor` token, or
replace it outright:

```dart
DraggablePanel(
  handleBuilder: (context, edge) => const Icon(Icons.drag_indicator),
  // …
)
```

## The motion

The feel is not decoration — it is the whole point, and it is built from
published behaviour rather than guesswork.

| Behaviour                      | How                                                                                                                                                                                                                                                |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Where a flick lands            | `projected = position + (velocity / 1000) · rate / (1 − rate)`, `rate = 0.998` — the projection from Apple's _Designing Fluid Interfaces_ (WWDC 2018, session 803). The snap target is chosen against that projected point, not the release point. |
| How it settles                 | A critically damped spring with a 400 ms response, taken from the same session's sample code. Expressed as `SpringDescription.withDurationAndBounce(duration: 400ms)`, which is a bit-exact port of SwiftUI's spring model.                        |
| Dragging past the edge         | The iOS rubber band, `b(x) = (x·d·c) / (d + c·x)` with `c = 0.55`. It asymptotes at one viewport, so the panel resists rather than stopping dead.                                                                                                  |
| Grabbing it mid-flight         | The running simulation is frozen, its velocity handed back, and folded into the next throw with a 100 ms half-life. Grab and hold kills the momentum; grab and flick compounds it.                                                                 |
| Reversing an expansion halfway | Falls out of the spring maths — the new simulation starts from the current value and velocity, so it overshoots, turns around and comes back.                                                                                                      |

Two axes are simulated **independently**, as UIKit's spring timing does. A
release velocity that is not aimed at the target therefore _curves_ into it; a
single interpolated `Offset` would drag the panel along a straight line.

## Performance

Motion is a painting concern here, not a layout one. Position, size, corner
radius, elevation and the cross-fade are all computed inside one `RenderBox`'s
`paint`, driven by a `Listenable` the render object subscribes to directly.

The panel is also its own repaint boundary, so a moving panel never drags the
application behind it into a repaint.

**A frame of motion costs zero widget builds, zero layouts, and no repaint of
your app.** All three are asserted in CI, not merely intended:

```dart
testWidgets('a motion frame rebuilds nothing and lays out nothing', ...);
testWidgets('motion does not repaint the application behind the panel', ...);
```

Your app's subtree is passed straight through as `child` and is never rebuilt by
the panel.

One consequence worth knowing: because both faces are laid out up front, your
`expandedBuilder` runs even while the panel is collapsed. Keep expensive work out
of it, or gate it on `status.phase`.

## Placement survives everything

A resting position is stored as _intent_, never as pixels:

```dart
sealed class PanelPlacement {
  PanelPlacement.corner(PanelCorner corner);
  PanelPlacement.free(AlignmentGeometry alignment);
  PanelPlacement.stashed(PanelEdge edge, {double verticalAlignment});
}
```

Rotation, a window resize, split-screen and the software keyboard are all just a
change of viewport: the panel keeps its corner and springs to wherever that
corner now is. A placement saved on a tablet restores correctly on a phone.

```dart
DraggablePanel(
  onPlacementChanged: (placement) =>
      prefs.setString('panel', jsonEncode(placement.toJson())),
  // …
)
```

`onPlacementChanged` never fires mid-drag, so it is safe to persist directly.

## Controlling it

```dart
final panel = DraggablePanelController(
  initialPlacement: const PanelPlacement.corner(PanelCorner.topEnd),
);

panel.expand();
panel.collapse();    // parks instead, when `collapsible: false`
panel.toggle();
panel.stash();       // park off the nearest edge
panel.unstash();     // opens instead, when `collapsible: false`
panel.moveTo(const PanelPlacement.corner(PanelCorner.bottomStart));
panel.hide();
panel.show();
```

No method takes a screen size: the controller describes intent and the widget
resolves it. It is a `ValueListenable<PanelStatus>`, and exposes two narrower
channels that only fire when their own value changes — `phaseListenable` and
`placementListenable`.

A whole drag gesture produces about three notifications, not one per frame.

From inside your own content, reach the controller without prop-drilling:

```dart
IconButton(
  onPressed: DraggablePanelScope.of(context).collapse,
  icon: const Icon(Icons.close),
)
```

## Behaviour

```dart
DraggablePanel(
  behavior: const PanelBehavior(
    draggable: true,
    tapToExpand: true,
    stashable: true,             // push it against an edge to park it there
    collapsible: true,           // false drops the small window between the two
    expandOnUnstash: false,      // true opens the panel straight out of a park
    dismissible: false,          // an explicit close, not a fling-away
    collapseOnTapOutside: true,
    stashOnTapOutside: true,     // touching the page puts a collapsed panel away
    idleStashDelay: Duration(seconds: 5),  // null to keep it out indefinitely
    avoidKeyboard: true,
    hapticsEnabled: true,
    snapPolicy: PanelSnapPolicy.edges,    // edges | corners | free
  ),
  // …
)
```

`stashable` and `collapsible` are the two optional stages covered above, and
both switch their stage off _everywhere_ rather than on one gesture.

`stashable: false` switches parking off outright — the panel then stays where it
was left, and no idle timer, tap on the page, drag against an edge, keyboard
dismissal, screen-reader action, or `controller.stash()` will put it away.
Parking is on by default.

`collapsible: false` does the same to the small window: pulling the tab out
opens the panel, and `controller.collapse()`, a tap on the page, `Esc`, the
screen reader's dismiss action and the preset's close control all park it
instead. The two cannot both be off — that is an assertion error, since the
panel would have no closed stage left.

## Theming

Material 3 throughout: colours come from the ambient `ColorScheme`, so the panel
sits in your app's surface hierarchy rather than beside it.

Tokens resolve in three layers — built-in defaults, then a
`DraggablePanelThemeData` in `ThemeData.extensions`, then the widget's own
`theme:`. Every token is nullable, meaning "inherit", so a call-site override
never clobbers your app-wide one.

```dart
ThemeData(extensions: [DraggablePanelThemeData(elevation: 10)])
```

Because it is a real `ThemeExtension`, it lerps: switching light↔dark crossfades
the panel along with the rest of the app.

**iOS squircle corners** are one line — Flutter's `RoundedSuperellipseBorder` is
an accurate superellipse, unlike `ContinuousRectangleBorder`:

```dart
DraggablePanelThemeData(
  collapsedShape: const RoundedSuperellipseBorder(
    borderRadius: BorderRadius.all(Radius.circular(20)),
  ),
)
```

**Frosted glass** is the surface seam. Pair the filter with a translucent
colour, or the fill hides the blur:

```dart
DraggablePanelThemeData(
  surfaceFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
  surfaceColor: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
)
```

The filter is clipped to the panel's shape and applied inside `paint`, so it
composes with the morph instead of fighting it. It costs a backdrop pass every
moving frame; the default is null.

**Every visual is a token.** Nothing the panel paints is hardcoded past its
default, so a surface can be retuned without forking a widget or reaching for a
builder:

| Group      | `DraggablePanelThemeData`                                                                   |
| ---------- | ------------------------------------------------------------------------------------------- |
| Shape      | `collapsedShape`, `shape`, `stashedShape`, `clipBehavior`                                   |
| Surface    | `surfaceColor`, `surfaceFilter`, `shadowColor`                                              |
| Elevation  | `elevation`, `draggingElevation`, `expandedElevation`, `stashedElevation`, `stashedOpacity` |
| Size       | `collapsedSize`, `expandedExtent`, `margin`, `minimumTapTarget`                             |
| Parked tab | `stashedSize`, `stashedPeek`, `handleColor`, `handleSize`, `handleStrokeWidth`              |
| Motion     | `motion`                                                                                    |

Each of the three shapes carries its own `side`, so a border follows the panel
through the morph rather than being painted around it.

| Group          | `DraggableActionPanelThemeData`                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Collapsed face | `collapsedIconSize`, `collapsedIconColor`                                                                             |
| Tiles          | `actionSize`, `actionIconSize`, `actionShape`, `actionBackgroundColor`, `actionForegroundColor`, `actionOverlayColor` |
| Captions       | `actionLabelStyle`, `actionLabelSpacing`, `actionLabelMaxLines`, `actionLabelMaxWidth`                                |
| Badges         | `badgeColor`, `badgeSize`, `badgeDotSize`, `badgeTextStyle`, `badgeOffset`                                            |
| Header         | `headerStyle`, `headerSpacing`, `closeIcon`, `closeButtonStyle`                                                       |
| Buttons        | `buttonStyle`, `buttonLabelStyle`, `buttonSpacing`                                                                    |
| Layout         | `contentPadding`, `actionSpacing`, `sectionSpacing`, `maxColumns`                                                     |

Where a token cannot express what you want, a builder replaces the widget
outright: `collapsedBuilder`, `expandedBuilder`, `handleBuilder`,
`headerBuilder`, `actionBuilder`, `buttonBuilder`.

**Retuning the springs** uses the duration-and-bounce model designers reason in:

```dart
DraggablePanelThemeData(
  motion: PanelMotionSpec(
    snapSpring: SpringDescription.withDurationAndBounce(
      duration: const Duration(milliseconds: 320),
      bounce: 0.2,
    ),
    morphSpring: SpringDescription.withDurationAndBounce(
      duration: const Duration(milliseconds: 480),
      bounce: 0.12,
    ),
  ),
)
```

## Accessibility

- Every collapsed panel is a labelled button with a tap action; expanded, it
  gains a dismiss action, so VoiceOver's two-finger scrub collapses it.
- **Custom actions per corner**, plus stash and unstash. This is what makes a
  four-corner drag model operable without dragging at all — they appear in
  VoiceOver's rotor and TalkBack's actions menu.
- When a screen reader is driving, free dragging is disabled outright, because
  the reader owns drag gestures.
- **Keyboard**: `Space`/`Enter` toggles, `Escape` collapses or stashes, and the
  arrow keys walk the panel _between corners_ — through the same spring a fling
  uses, so keyboard motion is identical to touch motion.
- Semantics are annotated on the panel's own rect, not on the full-screen host,
  and the face that is not showing is excluded from the tree entirely.
- Every string is on `PanelSemantics`, ready to localize.

**Reduced motion** (`MediaQuery.disableAnimations`) is honoured automatically:
the panel snaps into place, but its content still cross-fades over 200 ms. Fades
are acceptable where a translation is not. Direct manipulation is unchanged —
dragging is not animation, and the rubber band still resists.

Haptics fire at the moment a decision is _committed_, never when the animation
that follows it ends, and are independent of the motion preference: when motion
is suppressed the haptic carries more of the feedback, not less.

## The action-grid preset

For the common "tools panel" shape, `DraggableActionPanel` builds a balanced
icon grid over a column of buttons — five actions read as `3 + 2`, not `4 + 1`:

```dart
DraggableActionPanel(
  actions: [
    PanelAction(
      icon: Icons.article_outlined,
      tooltip: 'Logs',
      badge: const PanelBadge(label: '3'),
      onPressed: openLogs,
    ),
  ],
  buttons: [
    PanelActionButton(
      icon: Icons.copy,
      label: 'Copy device info',
      onPressed: copyInfo,
    ),
  ],
  child: child,
)
```

It is built entirely on `DraggablePanel`'s public API, with its own
`DraggableActionPanelThemeData`. If it ever needed privileged access to the
core, that would mean the core's API was missing something.

## Testing your integration

Inject an instant motion spec and assert targets rather than trajectories:

```dart
DraggablePanel(
  theme: DraggablePanelThemeData(motion: PanelMotionSpec.instant()),
  // …
)
```

Every settle then completes within a single `pump()`. For gestures, drive them
with explicit timestamps — `tester.fling` synthesises its own cadence and feeds
a velocity tracker whose output varies across Flutter versions:

```dart
await gesture.moveBy(const Offset(-70, -50),
    timeStamp: Duration(milliseconds: 16 * frame));
```

## Requirements

Flutter ≥ 3.32, Dart ≥ 3.8. That floor is what `SpringDescription.withDurationAndBounce`
and `RoundedSuperellipseBorder` need.

## Not in 4.0

- Floating above routes and dialogs. The panel lives in the same subtree as your
  app, so a pushed route covers it. An `Overlay`-hosted variant is planned.
- Dragging the panel open or closed. A drag always _moves_ it; opening and
  closing are a tap, a command, or the close control. Overloading the same drag
  with a second meaning is what the gesture model deliberately avoids.
- Pinch to resize.
- Trackpad scrubbing.

## Migrating from 3.x

The API was rewritten. See [MIGRATION.md](MIGRATION.md).

## License

MIT — see [LICENSE](LICENSE).
