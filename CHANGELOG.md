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