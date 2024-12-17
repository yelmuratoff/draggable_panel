<div align="center">
<p align="center">
    <a href="https://github.com/yelmuratoff/ispect" align="center">
        <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400px">
    </a>
</p>
</div>

<h2 align="center"> A versatile and customizable Draggable Panel 🚀 </h2>

<p align="center">
DraggablePanel is a versatile and interactive widget for Flutter that allows you to create floating, draggable panels that can dock to the nearest edge of the screen. The panel is ideal for displaying additional content, actions, or tools that can be accessed on demand.

Your feedback is highly valued as it will help shape future updates and ensure the package remains relevant and useful. 😊

   <br>
   <span style="font-size: 0.9em"> Show some ❤️ and <a href="https://github.com/yelmuratoff/ispect.git">star the repo</a> to support the project! </span>
</p>

<p align="center">
  <a href="https://pub.dev/packages/draggable_panel"><img src="https://img.shields.io/pub/v/draggable_panel.svg" alt="Pub"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://github.com/yelmuratoff/draggable_panel"><img src="https://hits.dwyl.com/yelmuratoff/draggable_panel.svg?style=flat" alt="Repository views"></a>
  <a href="https://github.com/yelmuratoff/draggable_panel"><img src="https://img.shields.io/github/stars/yelmuratoff/draggable_panel?style=social" alt="Pub"></a>
</p>
<p align="center">
  <a href="https://pub.dev/packages/draggable_panel/score"><img src="https://img.shields.io/pub/likes/draggable_panel?logo=flutter" alt="Pub likes"></a>
  <a href="https://pub.dev/packages/draggable_panel/score"><img src="https://img.shields.io/pub/popularity/draggable_panel?logo=flutter" alt="Pub popularity"></a>
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
  draggable_panel: ^0.0.1
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
          items: [
            DraggablePanelItem(
              icon: Icons.list,
              onTap: (context) {},
            ),
            DraggablePanelItem(
              icon: Icons.color_lens,
              onTap: (context) {},
            ),
            DraggablePanelItem(
              icon: Icons.zoom_in,
              onTap: (context) {},
            ),
            DraggablePanelItem(
              icon: Icons.token,
              onTap: (context) {},
            ),
          ],
          buttons: [
            DraggablePanelButton(
              icon: Icons.copy,
              onTap: (context) {},
              label: 'Push token',
            ),
          ],
          child: child!,
        );
      },
```

Please, check the [example](https://github.com/yelmuratoff/draggable_panel/tree/main/example) for more details.

<br>
<div align="center" >
  <p>Thanks to all contributors of this package</p>
  <a href="https://github.com/yelmuratoff/draggable_panel/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=yelmuratoff/draggable_panel" />
  </a>
</div>
<br>