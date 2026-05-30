<div align="center">
<p align="center">
    <a href="https://github.com/yelmuratoff/draggable_panel" align="center">
        <img src="https://github.com/yelmuratoff/draggable_panel/blob/main/assets/draggable_panel.png?raw=true" width="400px">
    </a>
</p>
</div>

<h2 align="center"> A versatile and customizable Draggable Panel 🚀 </h2>

<p align="center">
DraggablePanel is a versatile and interactive widget for Flutter that allows you to create floating, draggable panels that can dock to the nearest edge of the screen. The panel is ideal for displaying additional content, actions, or tools that can be accessed on demand.

Your feedback is highly valued as it will help shape future updates and ensure the package remains relevant and useful. 😊

   <br>
   <span style="font-size: 0.9em"> Show some ❤️ and <a href="https://github.com/yelmuratoff/draggable_panel.git">star the repo</a> to support the project! </span>
</p>

<p align="center">
  <a href="https://pub.dev/packages/draggable_panel"><img src="https://img.shields.io/pub/v/draggable_panel.svg" alt="Pub"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://github.com/yelmuratoff/draggable_panel"><img src="https://img.shields.io/github/stars/yelmuratoff/draggable_panel?style=social" alt="Pub"></a>
</p>
<p align="center">
  <a href="https://pub.dev/packages/draggable_panel/score"><img src="https://img.shields.io/pub/likes/draggable_panel?logo=flutter" alt="Pub likes"></a>
  <a href="https://pub.dev/packages/draggable_panel/score"><img src="https://img.shields.io/pub/points/draggable_panel?logo=flutter" alt="Pub points"></a>
</p>

<br>

## 📜 Showcase

<div align="center">
  <img src="https://github.com/yelmuratoff/draggable_panel/blob/main/assets/idle.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/draggable_panel/blob/main/assets/drag.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/draggable_panel/blob/main/assets/opened.png?raw=true" width="200" style="margin: 5px;" />
</div>

## 📌 Getting Started

Follow these steps to use this package

### Add dependency

```yaml
dependencies:
  draggable_panel: ^3.0.0
```

### Add import package

```dart
import 'package:draggable_panel/draggable_panel.dart';
```

## Easy to use

### Instructions for use:

Simple add `DraggablePanel` to `MaterialApp`'s `builder`.

```dart
builder: (context, child) {
  return DraggablePanel(
    theme: DraggablePanelTheme(
      panelBackgroundColor: const Color(0xFF1E1E1E).withValues(alpha: 0.9),
      panelBorderRadius: BorderRadius.circular(24),
      panelBorder: Border.all(
        color: Colors.white.withValues(alpha: 0.1),
      ),
      panelItemColor: Colors.white,
      draggableButtonColor: const Color(0xFF2196F3),
      foregroundColor: Colors.white,
      panelBoxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    items: [
      DraggablePanelItem(
        enableBadge: false,
        icon: Icons.color_lens,
        onTap: (context) {},
        description: 'Color picker',
      ),
      DraggablePanelItem(
        enableBadge: false,
        icon: Icons.list,
        onTap: (context) {},
      ),
      DraggablePanelItem(
        enableBadge: false,
        icon: Icons.zoom_in,
        onTap: (context) {},
      ),
      DraggablePanelItem(
        enableBadge: false,
        icon: Icons.token,
        onTap: (context) {},
      ),
    ],
    buttons: [
      DraggablePanelButtonItem(
        icon: Icons.copy,
        onTap: (context) {},
        label: 'Push token',
        description: 'Push token to the server',
      ),
    ],
    child: child!,
  );
},
```

### Adaptive layout

The panel sizes itself to its content — no manual height to maintain:

- **Width** hugs a uniform icon grid. It fits as many cells as `panelWidth` allows, then balances them across rows so the last row isn't half-empty (5 items → `3 + 2`, not `4 + 1`), and shrinks the panel to exactly that width. `panelWidth` is the **maximum**. Panels with action buttons, a custom `panelContentBuilder`, or an explicit `panelHeight` use the full `panelWidth`.
- **Height** wraps the content and caps at the free space above/below the button, scrolling beyond it.
- The panel **anchors to the button's inner edge**, so it always sits flush with no gap, and opens on whichever side has more room.

This works for any content, including custom builders. Set `panelHeight` only if you want a fixed height instead.

### Sub-themes for fine-grained control

Customize individual elements without touching the main theme:

```dart
DraggablePanelTheme(
  // Layout
  panelWidth: 220,
  panelContentPadding: const EdgeInsets.all(12),
  itemSpacing: 10,
  buttonSpacing: 8,
  sectionSpacing: 12,

  // Sub-themes (all optional, sensible defaults)
  itemTheme: const DraggablePanelItemThemeData(
    borderRadius: 16,
    padding: EdgeInsets.all(10),
    badgeSize: 12,
  ),
  buttonTheme: const DraggablePanelButtonThemeData(
    height: 48,
    borderRadius: 20,
    iconSize: 20,
    iconSpacing: 12,
  ),
  handleTheme: const DraggablePanelHandleThemeData(
    curveStrokeWidth: 4,
    curveLineSize: Size(20, 65),
  ),
  tooltipTheme: const DraggablePanelTooltipThemeData(
    contentBorderRadius: 20,
    fontSize: 13,
  ),
)
```

### Customizing motion (durations & curves)

Every animation reads its timing from `DraggablePanelTheme.motion`, so the default mechanics are just defaults — retune them without touching the widgets:

```dart
DraggablePanelTheme(
  motion: const DraggablePanelMotion(
    // Button sliding / docking / hiding
    buttonMoveDuration: Duration(milliseconds: 220),
    buttonMoveCurve: Curves.easeOutBack,

    // Panel sliding in and resizing
    panelMoveDuration: Duration(milliseconds: 260),
    panelMoveCurve: Curves.easeOutCubic,

    // Panel content fade
    panelSwitchDuration: Duration(milliseconds: 180),
    panelSwitchInCurve: Curves.easeOut,
    panelSwitchOutCurve: Curves.easeIn,
  ),
)
```

### Customizing behavior

Toggle the interaction mechanics on the controller:

```dart
final controller = DraggablePanelController(
  tapToToggle: true,        // tap the button to open/close
  draggable: true,          // allow dragging the button
  closeOnTapOutside: true,  // tap outside an open panel to close it
  dockType: DockType.inside,
  dockOffset: 10,
);
```

### Full visual control with builders

When theme tokens aren't enough, replace the rendering entirely. Interactions, badges, and the close-on-tap behavior are preserved:

```dart
DraggablePanel(
  // Replace each item's icon with any widget
  itemBuilder: (context, item) => Image.asset('assets/${item.icon}.png'),

  // Replace each action button's icon + label row
  buttonBuilder: (context, button) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [const CircularProgressIndicator(), Text(button.label)],
  ),

  // Replace the whole draggable handle
  handleBuilder: (context, {required isDragging, required isDockedRight}) =>
      Icon(isDragging ? Icons.open_with : Icons.menu),

  child: child,
)
```

### Replacing the whole shell

`itemBuilder` / `buttonBuilder` swap the content but keep the default frame. To replace the frame itself (badge, ink-well, `FilledButton`), use the frame builders. They receive a render object with the resolved content, callbacks, colors, and theme — wire them into any widget you like:

```dart
DraggablePanel(
  itemFrameBuilder: (context, render) => GestureDetector(
    onTap: render.onTap,
    onLongPress: render.onLongPress,
    child: Container(
      decoration: BoxDecoration(
        color: render.color,
        shape: BoxShape.circle, // your own shape instead of the default cell
      ),
      padding: const EdgeInsets.all(10),
      child: render.content,
    ),
  ),

  buttonFrameBuilder: (context, render) => OutlinedButton(
    onPressed: render.onTap,
    onLongPress: render.onLongPress,
    child: render.content,
  ),

  child: child,
)
```

### Replacing the panel surface and layout

`panelBuilder` swaps the visible sheet (the decorated container); `panelContentBuilder` swaps how items and buttons are arranged. Slide/dock positioning, fade, and tap-to-close are always kept.

```dart
DraggablePanel(
  // Your own surface: glassmorphism, custom shape, a Material Card, ...
  // The panel sizes to its content, so cap height at surface.maxHeight and
  // make it scrollable so it never overflows the screen.
  panelBuilder: (context, surface) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: surface.width,
          maxHeight: surface.maxHeight,
        ),
        child: ColoredBox(
          color: surface.color.withValues(alpha: 0.6),
          child: SingleChildScrollView(
            child: Padding(
              padding: surface.theme.panelContentPadding,
              child: surface.content,
            ),
          ),
        ),
      ),
    ),
  ),

  // Your own layout. buildItem/buildButton return fully wired widgets.
  // Use a shrink-wrapping layout (Wrap/Column) so the panel hugs its content.
  panelContentBuilder: (context, content) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final item in content.items) content.buildItem(context, item),
    ],
  ),

  child: child,
)
```

> Keep the surface at `surface.width` so docking stays aligned with the button.

### Custom tooltip mechanism

By default the long-press tooltip is a floating `SnackBar` (needs a `Scaffold`). Replace it with your own presentation:

```dart
DraggablePanel(
  onShowTooltip: (context, data) {
    // data.message, data.icon, data.backgroundColor, ...
    showDialog(
      context: context,
      builder: (_) => AlertDialog(content: Text(data.message)),
    );
  },
  child: child,
)
```

### Per-item styling

Each item can override the global colors and configure its badge:

```dart
DraggablePanelItem(
  icon: Icons.notifications,
  enableBadge: true,
  color: Colors.indigo,            // cell background
  foregroundColor: Colors.white,   // icon color
  badgeColor: Colors.red,          // badge color
  badgeLabel: '3',                 // text badge instead of a dot
  onTap: (context) {},
)
```

### Smaller visual tokens

Previously hardcoded visuals are now themeable: `handleTheme.dragIndicatorIcon` / `dragIndicatorSize`, `itemTheme.iconSize`, `buttonTheme.labelStyle`, and `tooltipTheme.textStyle` / `maxLines` / `iconSpacing` / `iconBorderRadius`.

### Using a controller (recommended for advanced control)

Create a controller once and pass it to the widget. You can preset position/state and listen to position changes.

```dart
final controller = DraggablePanelController(
  initialPosition: (x: 20, y: 300),
  // initialPanelState: PanelState.open, // optional: start opened
);

@override
void initState() {
  super.initState();
  controller.addPositionListener((x, y) {
    // persist position, analytics, etc.
  });
}

// In MaterialApp.builder
builder: (context, child) => DraggablePanel(
  controller: controller,
  onPositionChanged: (x, y) {
    // Called when position settles (not during active dragging)
  },
  items: const [],
  buttons: const [],
  child: child!,
),
```

Tips:

- When the panel starts in the closed state (default), it will be docked to the nearest screen edge on first layout, so the button never “floats” mid-screen.
- The widget doesn’t auto-toggle on mount. Use `controller.toggle(context)` when you need to programmatically open/close it.
- Position callbacks: use `controller.addPositionListener` for all position updates; `onPositionChanged` is fired when not dragging (settled updates).

Please, check the [example](https://github.com/yelmuratoff/draggable_panel/tree/main/example) for more details.

<br>
<div align="center" >
  <p>Thanks to all contributors of this package</p>
  <a href="https://github.com/yelmuratoff/draggable_panel/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=yelmuratoff/draggable_panel" />
  </a>
</div>
<br>
