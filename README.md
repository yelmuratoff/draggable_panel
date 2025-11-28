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
  draggable_panel: ^1.4.0
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
      draggableButtonIconColor: Colors.white,
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