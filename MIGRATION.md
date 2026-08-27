# Migrating from 3.x to 4.0

4.0 is a rewrite. The panel changed from an edge-docked rail that slid a menu
sideways into a free-floating Picture-in-Picture window that grows in place, and
the API changed with it.

The nearest one-for-one path is `DraggableActionPanel`, the action-grid preset:
it keeps the icons-and-buttons shape v3 had.

## Widgets

| 3.x | 4.0 |
| --- | --- |
| `DraggablePanel(items:, buttons:, child:)` | `DraggableActionPanel(actions:, buttons:, child:)` |
| `DraggablePanel(child:)` with custom builders | `DraggablePanel(collapsedBuilder:, expandedBuilder:, child:)` |
| `icon:` | the widget returned by `collapsedBuilder`, or `DraggableActionPanel.icon` |
| `panelHeight:` | `theme.expandedExtent: PanelExtent.fixed(...)` |

## Models

| 3.x | 4.0 |
| --- | --- |
| `DraggablePanelItem` | `PanelAction` |
| `enableBadge` + `badgeLabel` + `badgeColor` | `badge: PanelBadge(label: ...)` |
| `description` | `tooltip` |
| `DraggablePanelButtonItem` | `PanelActionButton` |
| `onTap: (context) { … }` | `onPressed: () { … }` — use `DraggablePanelScope.of(context)` for the controller |

## Builders

v3 had seven builder seams. The core now takes two, and the ultimate escape
hatch is "stop using the preset and use `DraggablePanel` directly".

| 3.x | 4.0 |
| --- | --- |
| `handleBuilder` | `collapsedBuilder` — it *is* the collapsed window now |
| `panelContentBuilder` | `expandedBuilder` |
| `itemBuilder`, `itemFrameBuilder` | build your own `expandedBuilder` |
| `buttonBuilder`, `buttonFrameBuilder` | build your own `expandedBuilder` |
| `panelBuilder` | build your own `expandedBuilder` |
| `onShowTooltip` | `PanelAction.tooltip` uses the standard `Tooltip` |

## Controller

Every method that took a screen width is gone: the controller describes intent
and the widget resolves it against the current viewport.

| 3.x | 4.0 |
| --- | --- |
| `controller.toggle(context)` | `controller.toggle()` |
| `forceDock(w)`, `hidePanel(w)`, `togglePanel(w)`, `toggleMainButton(w)`, `relayout(w)`, `recomputeDockSide(w)` | removed — layout is not controller API |
| `setPosition(x:, y:)` | `moveTo(PanelPlacement)` |
| `initialPosition: (x:, y:)` | `initialPlacement: PanelPlacement.corner(...)` |
| `addPositionListener` | `placementListenable`, or `onPlacementChanged` |
| `tapToToggle` | `PanelBehavior.tapToExpand` |
| `draggable` | `PanelBehavior.draggable` |
| `closeOnTapOutside` | `PanelBehavior.collapseOnTapOutside` |
| `dockType`, `dockOffset` | `theme.margin` |
| `panelAnimDuration`, `dockAnimDuration`, `movementSpeed` | removed — they were already deprecated no-ops |

New: `expand()`, `collapse()`, `stash()`, `unstash()`, `hide()`, `show()`.

### Persistence is the breaking change most worth reading

`onPositionChanged(double x, double y)` became
`onPlacementChanged(PanelPlacement)`, on purpose. Pixels do not survive rotation
or a different device; a corner does.

```dart
// 3.x — restores off-screen if the window changed size
onPositionChanged: (x, y) => prefs.setDouble('x', x);

// 4.0
onPlacementChanged: (p) => prefs.setString('panel', jsonEncode(p.toJson())),
// …
initialPlacement: PanelPlacement.fromJson(jsonDecode(saved)),
```

There is no automatic conversion from a stored pixel pair. Drop the old value
and let the panel start at its default corner.

## Theme

`DraggablePanelTheme` became `DraggablePanelThemeData`, a real `ThemeExtension`
with nullable tokens. Register it app-wide via `ThemeData.extensions`, or pass
it to the widget — both work, and a call-site override no longer clobbers the
app-wide one.

| 3.x | 4.0 |
| --- | --- |
| `draggableButtonWidth` / `draggableButtonHeight` | `collapsedSize` |
| `draggableButtonColor`, `panelBackgroundColor` | `surfaceColor` |
| `panelBorderRadius`, `panelBorder` | `collapsedShape` / `shape` (a `ShapeBorder`) |
| `panelBoxShadow` | `elevation`, `draggingElevation`, `expandedElevation`, `shadowColor` |
| `panelWidth` | `expandedExtent` |
| `panelContentPadding`, `itemSpacing`, `buttonSpacing`, `sectionSpacing` | `DraggableActionPanelThemeData` |
| `itemTheme`, `buttonTheme`, `handleTheme`, `tooltipTheme` | `DraggableActionPanelThemeData` (flattened) |
| `DraggablePanelMotion` (durations + curves) | `PanelMotionSpec` (springs) |

Motion has no mechanical mapping: durations and curves became springs, because a
tween cannot carry entry velocity or be redirected. Re-tune with
`SpringDescription.withDurationAndBounce(duration:, bounce:)`.

## Removed with no replacement

- `MultiValueListenableBuilder` — a generic utility with no business in this
  package's public API. Copy it into your project if you use it.
- `TooltipSnackBar` — the preset uses the standard `Tooltip`.
- `DockType`, `PanelState` — replaced by `theme.margin` and `PanelPhase`.

## Requirements

Flutter ≥ 3.32, Dart ≥ 3.8. v3 declared `flutter: any` while already requiring
3.16 for its Material 3 colours; 4.0 states its floor honestly.
