---
name: draggable-panel-integration
description: >-
  Use when adding or configuring draggable_panel in a Flutter app: full-window
  hosting, controller lifecycle, scrollable panel content, collapsed and stashed
  stages, placement persistence, and panel themes.
---

# Integrate draggable_panel

Use the public API from `package:draggable_panel/draggable_panel.dart`.
These instructions target the 4.1 floating-window API. Check the consumer's
resolved package version before adapting older integrations; use that version's
README and public declarations for signatures outside this guide.

## Host and content

- Give `DraggablePanel` the whole window, usually through `MaterialApp.builder`.
  Preserve its `child`, which contains the app's Navigator. A panel inside a
  smaller box still calculates placement against the window.
- Supply both `collapsedBuilder` and `expandedBuilder`, even when the collapsed
  stage is disabled. Both faces are laid out up front; `expandedBuilder` runs
  while collapsed too. Keep data fetching and controller creation outside them.
- For a scrollable expanded face, place `PanelDragArea` around a stationary
  header outside the scrollable. With a drag area declared, expanded content
  outside it keeps its gestures; collapsed and stashed faces remain draggable
  everywhere. Without one, the entire expanded face can compete for the drag.
- Use a fixed or fractional `expandedExtent` for a lazy viewport such as a
  `ListView`, so it receives bounded dimensions. Reserve `PanelExtent.content`
  for content that can measure its own size.

This complete example hosts a panel over the Navigator, bounds its list, and
keeps the list's scroll gesture separate from moving the panel:

```dart
import 'package:draggable_panel/draggable_panel.dart';
import 'package:flutter/material.dart';

void main() => runApp(const PanelApp());

class PanelApp extends StatefulWidget {
  const PanelApp({super.key});

  @override
  State<PanelApp> createState() => _PanelAppState();
}

class _PanelAppState extends State<PanelApp> {
  final _panel = DraggablePanelController(
    initialPlacement: const PanelPlacement.corner(PanelCorner.bottomEnd),
  );

  @override
  void dispose() {
    _panel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    builder: (context, child) => DraggablePanel(
      controller: _panel,
      theme: const DraggablePanelThemeData(
        expandedExtent: PanelExtent.fraction(width: 0.8, height: 0.5),
      ),
      collapsedBuilder: (context, status) => const Icon(Icons.list),
      expandedBuilder: (context, status) => Column(
        children: [
          PanelDragArea(
            child: Row(
              children: [
                const Expanded(child: Text('Items')),
                IconButton(
                  key: const ValueKey('panel-close'),
                  tooltip: 'Close panel',
                  onPressed: _panel.collapse,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 20,
              itemBuilder: (context, index) =>
                  ListTile(title: Text('Item $index')),
            ),
          ),
        ],
      ),
      child: child,
    ),
    home: const Scaffold(body: Center(child: Text('App content'))),
  );
}
```

## Commands and ownership

- Omit `controller` when only built-in gestures are needed; the panel creates
  and disposes its own. Otherwise create one per panel in State (or an existing
  lifecycle owner), retain it across builds, and dispose it in that owner.
- Use `expand()`, `collapse()`, `toggle()`, `stash()`, `unstash()`, `moveTo(...)`,
  `hide()`, and `show()` for commands. Configure `behavior` on the widget;
  controller setters marked `@internal` and `dispatch` belong to the package.
- From a descendant widget inside panel content, use
  `DraggablePanelScope.of(context)` to reach the controller. The contexts passed
  to `collapsedBuilder` and `expandedBuilder` can also reach this scope. A context
  from outside the panel cannot access its scope.
- Observe `phaseListenable` or `placementListenable` for their respective values,
  or the controller as a `ValueListenable<PanelStatus>`. Notifications describe
  state transitions, not frame-by-frame position or expansion progress.

## Choose the resting stages

Dragging moves the panel; tapping toggles content. Choose stages with
`PanelBehavior`, rather than implementing a second gesture recognizer:

- Defaults allow stashed tab, collapsed window, and expanded content. Snapping
  uses `PanelSnapPolicy.edges`, keeping the release height at the nearest side.
- `expandOnUnstash: true` opens on leaving a stash, keeping the collapsed stage
  available for closing and other routes.
- `collapsible: false` removes the collapsed stage entirely; closing parks the
  panel. It requires `stashable: true`. Disabling both fails an assertion.
- `stashable: false` removes parking from gestures, idle timers, and commands.
- A collapsed panel parks after five idle seconds and on an outside touch by
  default. Set `idleStashDelay: null` and `stashOnTapOutside: false` when it
  should stay visible. For `copyWith`, use `clearIdleStashDelay: true`; passing
  null there preserves the existing delay.
- Start parked with a controller's
  `initialPlacement: const PanelPlacement.stashed(PanelEdge.end)`.
  `dismissible` controls fling-away hiding and defaults to false.

## Placement, appearance, and presets

- Store placement intent with `onPlacementChanged` and `placement.toJson()`;
  restore through `PanelPlacement.fromJson(...)` as `initialPlacement`. The
  callback reports resting placement, never intermediate drag pixels. Handle
  invalid saved data at the app's persistence boundary (`fromJson` throws
  `FormatException`).
- Use directional `PanelCorner`, `PanelEdge`, or `AlignmentDirectional` when
  placement should follow reading direction; `Alignment` expresses physical
  placement. Let the panel resolve window resize, safe insets, and keyboard
  avoidance instead of caching offsets.
- Theme with `DraggablePanelThemeData` in `ThemeData.extensions` for app-wide
  tokens, or widget `theme:` for local overrides. Null tokens inherit. Set
  `collapsedSize` and `expandedExtent` there rather than wrapping the host in a
  size constraint. For blur, pair `surfaceFilter` with a translucent
  `surfaceColor`. Use `PanelMotionSpec.instant()` if travel should be immediate;
  the package also respects platform reduced motion.
- For an action grid and button rows, use `DraggableActionPanel` with
  `PanelAction` and `PanelActionButton`. A `title`, `onClose`, or `headerBuilder`
  supplies its stationary drag header. `actionTheme:` customizes preset content;
  `theme:` customizes the panel surface. An `expandedBuilder` replaces the
  preset's expanded content entirely.
- Localize `PanelSemantics` labels and hints and the app's own controls.

## Check the integration

Analyze the consumer app and exercise opening, closing, stashing, and restoring.
For scrolling content, verify that the header moves the expanded panel while the
list scrolls. Check small windows, keyboard appearance, RTL placement, and
keyboard/screen-reader controls where the integration uses them. Keep the
consumer's existing state management and persistence tooling.
