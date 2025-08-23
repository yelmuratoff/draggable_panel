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