## 4.0.0-beta.7

Added

- `PanelBehavior.expandOnUnstash` opens the panel on its way out of a park,
  without removing the collapsed stage the way `collapsible: false` does. It
  shortens one journey rather than dropping a stage: the tab grows straight
  into the open panel, while the small window stays somewhere to close down to
  and drag around. Reach for it when a park is how the panel is put away and
  taking it out always means using it. The new `Quick open` demo in `example/`
  shows it beside `Tab panel`, which drops the stage outright, so the two are
  easy to tell apart.

Changed

- A `.pubignore` trims the published archive from 2 MB to 100 KB by leaving out
  the golden reference images, the repository's screenshots, and the example's
  platform scaffolding. The library, the example's source, and the behavioural
  tests all still ship.

## 4.0.0-beta.6

Added

- Swiping an open panel sideways parks it, exactly as swiping the collapsed
  window does. The panel closes and travels in one gesture: the position spring
  carries it into the edge while the morph spring runs it back down to its tab,
  so there is no "collapse, then slide" seam. `stash()` and
  `moveTo(PanelPlacement.stashed(…))` now accept an expanded panel for the same
  reason — what a park leaves behind is a tab, so an open panel closes on the
  way. The tab lands at the height the collapsed face already occupied, so
  pulling it back out returns the panel where it lived.
- `PanelBehavior.collapsible` makes the collapsed window an optional *stage*,
  the pair of the existing `stashable`. Turn it off and the panel has two
  stages instead of three: it grows while it slides out of a park rather than
  resting as a small window first, and every way of closing it parks it again.
  The rule lives in one place — every journey between resting places now runs
  through a single function in the state machine — so `PanelPhase.collapsed`
  becomes unreachable rather than merely unusual, which a search over every
  reachable state asserts. Dropping `collapsible` and `stashable` together is
  an assertion error, since the panel would have no closed stage left. The new
  `Tab panel` demo in `example/` shows the two-stage panel.

Fixed

- An expanded panel could not be dragged at all. The drag deliberately changes
  no phase, so nothing rebuilt the surface and it never learned a finger had
  the panel — leaving the containment that holds an open panel inside its
  bounds to cancel every pixel the drag moved. Dragging an open window now
  tracks the finger one-to-one, with the iOS rubber band past the bounds.
- The panel's rect stepped when an expansion finished off-screen. Growth
  suppressed the tab shrink outright, so the instant expansion reached zero the
  rect jumped the whole way from the collapsed box to the tab. The two now
  blend, which is what lets a closing panel arrive at its park continuously.

## 4.0.0-beta.5

Fixed

- `stashedOpacity` changed almost entirely in the last few pixels of a park.
  beta.4 put the fade on `emergence`, which only starts once the panel crosses
  the screen edge — the stretch a settling spring crawls through — so the alpha
  held at full while the panel visibly travelled and then dropped at the end.
  `PanelFrame` now carries `parkedFade`, measured from the bounds the panel
  rests in rather than from the edge, so the fade spans the whole journey.
  `emergence` is unchanged and still drives the shape morph.

## 4.0.0-beta.4

Fixed

- `stashedOpacity` stepped rather than faded. It was read off the panel's phase,
  which flips in one frame, while the rect, the shape, and the handle all
  cross-fade along the continuous emergence — so a panel set to fade as it
  parked slid smoothly and then blinked to its parked alpha at the end. The
  surface now folds the parked fade in along that same emergence, leaving the
  phase to carry visibility alone. A panel left at the default `1` is unchanged.

## 4.0.0-beta.3

Fixed

- An action's badge was all but invisible. It wrapped the glyph, so Material
  anchored it to the 24-pixel icon rather than the tile — a 6-pixel dot landed on
  the icon's own strokes, and the tile's `Clip.antiAlias` ate whatever crossed
  its rounded corner. The badge now rides the tile's top-end corner, above the
  clip, at 18 pixels with a label and 10 as a dot.
- A `ShapeBorder` carrying a `side` had its outline honoured but its stroke
  dropped: the surface only ever asked the shape for `getOuterPath`, never
  painted it. Panel borders now draw, over the content clip so the stroke is not
  halved, and the shape resolves against the ambient `TextDirection`, which a
  `BorderRadiusDirectional` needs.

Added

- `badgeSize` and `badgeDotSize` on `DraggableActionPanelThemeData`, joining
  `badgeColor`.
- `buttonStyle` on `DraggableActionPanelThemeData`, so the panel's buttons can
  take their own shape without retuning every `FilledButton` in the app.
- `handleBuilder` on `DraggableActionPanel`, which the preset accepted nowhere
  and so could not reach `DraggablePanel`.
- A token for every remaining visual, so nothing the panel paints is fixed past
  its default. On `DraggablePanelThemeData`: `stashedShape`, which carries into
  `collapsedShape` as the tab is drawn out, plus `handleSize` and
  `handleStrokeWidth`. On `DraggableActionPanelThemeData`: `collapsedIconSize`,
  `collapsedIconColor`, `actionOverlayColor`, `badgeTextStyle`,
  `badgeForegroundColor`, `badgeOffset`, `closeIcon`, and `closeButtonStyle`.
- `PanelBadge.foregroundColor`, for a badge whose colour needs its own label
  colour. Material resolves a badge's text colour outside its text style, so one
  set through `badgeTextStyle` alone was being dropped.

## 4.0.0-beta.2

Fixed

- Panel content threw `No Overlay widget found` when the panel was mounted
  through `MaterialApp.builder`. That is the position the README recommends, and
  it sits above the `Navigator` that owns the app's only `Overlay`, so every
  `Overlay.of` caller in a panel face — `Tooltip`, `DropdownButton`,
  `PopupMenuButton` — had nowhere to render. `DraggableActionPanel` wraps every
  action and button in a `Tooltip`, so its whole grid failed there. The panel now
  hosts an unclipped `Overlay` for its faces. Neither the example nor the tests
  had mounted a panel that way, which is why the suite stayed green.

## 4.0.0-beta.1

A rewrite. The panel is now a floating window: drag it
anywhere, release it and it springs to the nearest corner by projected velocity,
flick it past an edge to park it off-screen, tap it to grow in place into a full
panel. Material 3 visuals, Apple-grade motion.

Breaking changes

- `DraggablePanel` now takes `collapsedBuilder` + `expandedBuilder` and arbitrary
  content. The icons-and-buttons shape lives on as the `DraggableActionPanel`
  preset. See `MIGRATION.md` for the full mapping.
- `onPositionChanged(x, y)` became `onPlacementChanged(PanelPlacement)`. Pixels
  do not survive rotation or a different device; a corner does. Stored pixel
  positions cannot be converted and should be dropped.
- Every controller method that took a screen width is gone. `forceDock`,
  `hidePanel`, `togglePanel`, `toggleMainButton`, `relayout` and
  `recomputeDockSide` were layout math leaking into a state object.
- `DraggablePanelTheme` became `DraggablePanelThemeData`, a `ThemeExtension`
  with nullable tokens, so a call-site override no longer clobbers an app-wide
  one. Sub-themes flattened into `DraggableActionPanelThemeData`.
- `DraggablePanelMotion` (durations and curves) became `PanelMotionSpec`
  (springs). There is no mechanical mapping — a tween cannot carry entry
  velocity or be redirected mid-flight.
- Removed: `MultiValueListenableBuilder`, `TooltipSnackBar`, `DockType`,
  `PanelState`, and the already-deprecated `panelAnimDuration`,
  `dockAnimDuration` and `movementSpeed`.
- Minimum Flutter is now 3.32 (Dart 3.8). 3.x declared `flutter: any` while
  already requiring 3.16 for its Material 3 colours.

Added

- Spring physics throughout: velocity projection from WWDC18 session 803,
  Apple's critically damped 400 ms PiP spring, and the iOS rubber band.
- Four-corner snapping, edge stashing, and grow-in-place expansion anchored at
  the occupied corner.
- Interruptible motion: grabbing a moving panel freezes it and folds its
  momentum into the next throw; reversing an expansion halfway works.
- `PanelPlacement` — resolution-independent resting positions with JSON
  round-tripping.
- Full accessibility: per-corner custom semantics actions, keyboard corner
  navigation, dismiss action, screen-reader-aware drag suppression, and honoured
  reduced-motion.
- Committed-moment haptics, independent of the motion preference.
- `DraggablePanelScope` for reaching the controller from panel content.
- `PanelBehavior` for interaction flags, `PanelSemantics` for localizable copy.
- Edge parking: push the panel against a side and it stays there as a grab-able
  sliver; pull it back out and it returns. Both are ordinary drags rather than
  separate gestures. Start parked with
  `initialPlacement: PanelPlacement.stashed(...)`.
- `stashedSize` — the size a parked panel takes, `35x70` by default. A tab is
  taller than it is wide, so it reads as something to pull rather than as the
  panel with most of it missing. The panel shrinks into it as it is pushed off
  the edge and unfolds out of it as it is drawn back.
- A parked panel draws its own grab affordance on the tab: a curve leaning the
  way it comes out. Retint it with `handleColor`, resize the curve on
  `PanelEdgeHandle`, or replace the whole thing with `handleBuilder`.
- `PanelAction.label` — a caption under each icon, so the grid is readable by
  someone who has not memorised the glyphs. Tuned by `actionLabelStyle`,
  `actionLabelSpacing`, `actionLabelMaxLines` and `actionLabelMaxWidth`, the
  last of which bounds a grid column so one long label cannot stretch the panel.
- `actionIconSize` — the glyph inside a tile, separate from `actionSize` because
  the tile is the tap target and has a 48-pixel floor while the glyph does not.
- The preset's default collapsed icon is now `Icons.zoom_out_map_rounded`. `Icons.apps`
  described what the panel held, but the contents belong to the caller; an
  expand glyph says what a tap does.
- `DraggableActionPanel.title` and `onClose` put a header above the grid, giving
  the panel a visible way out instead of only a tap on the page.
- A grid row fills to `maxColumns` before the next one starts. Five actions are
  4 + 1; the old layout balanced them into 3 + 2, which made the row count less
  predictable than the column count.
- Grid columns are equal shares of the row, so they line up between rows and a
  full row leaves no slack at its trailing end. The grid never claims more
  columns than it has actions, and the panel's width follows: two actions make a
  two-column panel, not a mostly empty four.
- Content taller than the panel's height cap scrolls instead of overflowing.
- `actionBuilder`, `buttonBuilder`, `headerBuilder` and `expandedBuilder` on the
  preset, plus `ActionCell`, `ActionButtonRow`, `ActionPanelHeader` and
  `ActionPanelContent` exported, so any part can be replaced or reused.
- `idleStashDelay` — a collapsed panel parks itself after five seconds
  untouched. Null keeps it out until it is put away by hand; an expanded panel
  never parks on its own, since someone is reading it.
- `stashOnTapOutside` — touching anywhere off a collapsed panel parks it. The
  touch is observed rather than intercepted, so whatever it landed on still
  gets its own gesture.
- Emerging from a park is a slide, not a cross-fade. The handle and the
  collapsed face both hold still against the screen while the panel slides out
  from under them, so the handle leaves through the edge exactly as the face
  arrives, and neither is ever a translucent ghost of the other.
- An expanded panel released on the far side stays there. Which side it settles
  on was decided from the collapsed box the origin describes, whose centre sits
  a window's width away from the panel's own — so on a phone-width screen a
  window carried to the left flew back to the right, while a desktop window was
  wide enough for the same arithmetic to land right by accident.
- Carrying an expanded panel to the other side no longer jerks. The origin
  describes the collapsed box and the expanded rect hangs off it by the anchor,
  so swapping sides used to move the window by the whole difference in size the
  instant the placement changed — a jump of a window's width, then a spring back
  over it. The driver is now rebased through the anchor change, and an expanded
  drag is bounded by the size it actually occupies rather than by the collapsed
  one.
- A panel dragged to the other side now parks on that side. `stash()` without an
  edge read a free placement as the end edge whatever the panel's alignment, so
  one pulled across to the left flew back to the right.
- Pulling a parked panel out is one-to-one from the first pixel. The rubber
  band used to resist straight to the resting bounds, which yanked a parked
  panel inwards the moment a drag registered, and the platform pan slop was
  wider than the whole pull-out.
- `stashedElevation` — a parked panel is tucked into the screen edge, so it
  casts a lighter shadow than one resting in the open. `stashedPeek` is now
  measured from the screen edge, not from inside `margin`, so the visible sliver
  is exactly the token.
- `surfaceFilter` — a frosted-glass seam applied inside the shape clip, so it
  composes with the morph rather than fighting it.
- `expandTravelFraction` — how far a drag must travel to open or close.

Changed

- Motion is paint-only and isolated behind its own repaint boundary. A frame of
  movement costs zero widget builds, zero layouts, and no repaint of the
  application behind the panel — all three asserted by regression tests.
- The host app subtree is never rebuilt by panel motion.
- Rotation, resize, split-screen and the keyboard now re-place the panel by
  re-resolving its placement, carrying velocity, instead of teleporting it.
- The panel keeps clear of the software keyboard while expanded.

Fixed

- Panel content now sits inside a transparent `Material`, so a bare `Text` in a
  builder inherits the app's text style instead of rendering as oversized debug
  type, and an `InkWell` finds something to ink on.
- Drag velocity is no longer discarded on release; a flick and a slow drop now
  differ.
- Bounds resist instead of clamping dead.
- Theme changes crossfade the panel along with the rest of the app.
- `panelSwitchInCurve` / `panelSwitchOutCurve` were inert public API in 3.x.

## 3.0.0

Major release: open/hide stability, adaptive content-sized layout, and end-to-end customization.

Fixes

- Deterministic button hide/reveal — no more late or missing hide on open.
- Resize (keyboard/rotation/split-screen) no longer pulls a hidden button back on-screen.
- Single-frame open (removed the `await` between hide and reveal).
- Off-screen position no longer persisted via position listeners.
- No crash with an empty `items` list.

Layout

- Panel sizes to its content in both axes; `panelWidth` is now the maximum.
- Item grid balances columns so the last row isn't half-empty; height caps to free space and scrolls.
- Panel anchors flush to the button's inner edge.

Customization

- Motion via `DraggablePanelTheme.motion` (durations + curves).
- Behavior flags on the controller: `tapToToggle`, `draggable`, `closeOnTapOutside`.
- Content builders: `itemBuilder`, `buttonBuilder`, `handleBuilder`.
- Shell builders: `itemFrameBuilder`, `buttonFrameBuilder`.
- Panel builders: `panelBuilder` (surface), `panelContentBuilder` (layout).
- Custom tooltip via `onShowTooltip`.
- Per-item styling on `DraggablePanelItem`: `color`, `foregroundColor`, `badgeColor`, `badgeLabel`.
- New theme tokens: handle drag icon/size, item `iconSize`, button `labelStyle`, tooltip text style.

Breaking changes

- Durations moved to `DraggablePanelTheme.motion`; controller `panelAnimDuration`/`dockAnimDuration` deprecated (no effect).
- `DraggablePanelController.movementSpeed` deprecated in favor of `animateMovement`.
- `DraggablePanelController.toggleMainButton` now returns `void` instead of `Future<void>`.

## 2.0.2

- Fixed tooltip text color not adapting to light/dark theme.

## 2.0.0

- Sub-themes for items, buttons, tooltip, and drag handle.
- Layout properties: `panelWidth`, `panelContentPadding`, `itemSpacing`, `buttonSpacing`, `sectionSpacing`.
- Material 3 dark theme support with surface-based default colors.
- Border no longer affects content layout.
- No breaking changes — existing code works without modifications.

## 1.4.3

Fixes

- **Fixed panel overflow when `panelBorder` is set**: Panel height now accounts for border width when calculating items per row.

## 1.4.2

Major theme refactor and customization improvements.

What's new

- **DraggablePanelTheme**: Introduced a comprehensive theme class to centralize all styling properties.
- **Enhanced Customization**: You can now customize every aspect of the panel, including button colors, shadows, borders, and more, via the `theme` property.
- **Simplified API**: Removed individual style arguments from `DraggablePanel` in favor of the `theme` object, making the API cleaner and more consistent.

Improvements

- Added widget tests to ensure reliability.
- Updated documentation with new usage examples.

## 1.3.1

Code quality improvements and enhanced documentation.

What's new

- **Enhanced documentation**: comprehensive dartdoc comments with usage examples and parameter descriptions across all public APIs.
- **Improved tooltips**: better theme adaptation and modern appearance for item/button tooltips.

Improvements

- Better code organization and widget decomposition for improved maintainability.
- Optimized performance with reduced widget rebuilds and better const usage.
- Enhanced position listener handling with improved lifecycle safety.
- Stricter code quality with comprehensive lint rules and zero analysis issues.

Migration notes

- No breaking changes. All existing code works as expected.

## 1.2.0

Desktop/Web resize stability, auto-docking, and controller improvements.

What's new

- Auto-dock on window resize: the draggable button now snaps to the nearest edge when the window is resized on desktop/web, matching the expected behavior.
- Stable dock side: introduced `isDockedRight` in `DraggablePanelController` to track the docked side explicitly. This prevents side flipping during resizes and ensures consistent alignment when the button is off-screen.
- Resize handling in widget: `DraggablePanel` now observes `didChangeMetrics` and reclamps/repositions without long animations during resize.

Changes

- `DraggablePanelController`:
  - Added `bool get isDockedRight` and internal tracking updated in `forceDock()`.
  - `hidePanel()`, `togglePanel()`, and `toggleMainButton()` now use `isDockedRight` instead of recomputing side from current left/width.
  - Added `recomputeDockSide(pageWidth)` helper for future scenarios where side needs recalculation without moving.
- `DraggablePanel`:
  - Uses `controller.isDockedRight` in UI instead of deducing side via `left > width/2`.
  - On init, initial position is clamped and, if closed, docked and panel hidden off-screen on the correct side.
  - On resize, positions are clamped, side is docked, and open/closed panel positions recalculated accordingly with zero-duration movement during the resize frame.

Fixes

- Panel and button no longer drift or jump when resizing the window; the open panel stays aligned to its edge, and the closed panel remains fully off-screen on the correct side.
- Prevented duplicate/misleading side calculations that caused inconsistencies during transitions.

Performance and cleanup

- Reduced unnecessary rebuilds during resize by batching updates and suppressing long animations for these events.
- Minor readability improvements (clearer border condition, removal of unused code, better ordering of resize operations).

Migration notes

- No breaking API changes. If you previously derived side from `draggablePositionLeft`, consider reading `controller.isDockedRight` for consistency with the new logic.

## 1.1.0

- Added: Position change listener API in `DraggablePanelController` (`addPositionListener` / `removePositionListener`).
- Added: Public `dockBoundary` getter for consistent boundary logic across widget and controller.
- Changed: `toggle()` now respects current `panelState` (not `initialPanelState`). Auto-toggle on mount removed to preserve user state. Initial position is clamped and (when starting closed) docked to the nearest edge.
- Fixed: Panel no longer resets to default after visibility toggles; duplicate position callbacks removed; unified docking logic.
- Performance: Batched x/y updates during drag via `setPosition(x, y)`; reduced redundant notifications and rebuilds; lifecycle safety (mounted checks) and controller rewire in `didUpdateWidget`.

## 1.0.6

- Added tooltip snackbar when long press on the panel buttons and items.
- Records replaced by `DraggablePanelItem` and `DraggablePanelButton` models with `description` field for tooltips.

## 1.0.3

- Removed `copy` method from `DraggablePanelController`. It was not necessary.
  Issue was fixed by another way. Please if you use your own `DraggablePanelController` don't forget to dispose it.

## 1.0.2

- Added `copy` method to `DraggablePanelController`. It fixes the issue when you hide and re-show the panel.

## 1.0.1

- In this update, I added the `DraggablePanelController` to give you the ability to control the panel directly outside of this widget.
  Just create it and pass it to the `DraggablePanel` widget. See example.

## 1.0.0

- Changed alignment of `Wrap` inside DraggablePanel.

## 0.0.9

- Added new optional param `panelHeight`. This param is used to set the height of the panel. If not set, the panel will take the height of the child widget based on item's and button's length.

## 0.0.8

- The panel size calculation has been changed.

## 0.0.6

- Added web support with essential configuration for PWA functionality.
- Improved draggable panel logic by introducing better state management and optimizing boundary checks.
- Fixed issues with initial panel positioning and docking behavior.
- Simplified and cleaned up redundant code for better maintainability.

## 0.0.5

- Now `child` is nullable in `DraggablePanel` widget. This is useful when you want to use `DraggablePanel` inside other stack widgets.

## 0.0.4

- The `DraggablePanelItem` and `DraggablePanelButton` models were removed and replaced with `Record`.
  This was done to make the package easier to use. If you were using `DraggablePanel` in a package, you would need to import models for others that use your same package. Now, this is not necessary.

## 0.0.3

- Initial release.
