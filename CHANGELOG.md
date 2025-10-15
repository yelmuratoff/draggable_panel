## 1.3.0

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