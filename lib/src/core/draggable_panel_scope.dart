import 'package:draggable_panel/src/controller/draggable_panel_controller.dart';
import 'package:flutter/widgets.dart';

/// Exposes the enclosing panel's controller to its own content.
///
/// Lets a close button inside an expanded panel reach
/// `DraggablePanelScope.of(context).collapse()` without the surrounding app
/// having to thread a controller down to it.
final class DraggablePanelScope extends InheritedWidget {
  const DraggablePanelScope({
    required this.controller,
    required super.child,
    super.key,
  });

  final DraggablePanelController controller;

  /// The controller of the nearest enclosing panel.
  ///
  /// Throws [FlutterError] when called outside a panel's content.
  static DraggablePanelController of(BuildContext context) {
    final controller = maybeOf(context);
    if (controller == null) {
      throw FlutterError(
        'DraggablePanelScope.of() was called outside a DraggablePanel.\n'
        "Only the widgets built by a panel's collapsedBuilder or "
        'expandedBuilder can reach its controller this way.',
      );
    }
    return controller;
  }

  /// The controller of the nearest enclosing panel, or null outside one.
  static DraggablePanelController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<DraggablePanelScope>()
      ?.controller;

  @override
  bool updateShouldNotify(DraggablePanelScope oldWidget) =>
      !identical(oldWidget.controller, controller);
}
