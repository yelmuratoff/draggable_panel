import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Marks the part of an expanded panel that drags the whole window.
///
/// An expanded panel and a scrollable inside it want the same gesture: the
/// panel reads a drag as a move, the list reads it as a scroll, and whichever
/// crosses its slop first takes it — so the same swipe scrolls one time and
/// moves the panel the next. Wrapping the panel's chrome — a header, a title
/// bar, a grip — settles it: while the panel is expanded, only a touch landing
/// inside a drag area starts a move, and every other touch belongs to the
/// content.
///
/// ```dart
/// expandedBuilder: (context, status) => Column(
///   children: [
///     PanelDragArea(child: PanelHeader(title: 'Tools')),
///     Expanded(child: ListView(children: items)),
///   ],
/// )
/// ```
///
/// Only a settled expanded panel is restricted: one that is collapsed, parked,
/// or still growing is dragged from anywhere on its surface, and an expanded
/// panel whose content declares no drag area stays draggable everywhere. Keep
/// the area outside the scrollable it protects — one nested inside a `ListView`
/// is back in the same arena the widget exists to leave.
///
/// While a drag area is in force, a tap outside it is left to the content too,
/// so tapping inert space no longer collapses the panel.
final class PanelDragArea extends StatefulWidget {
  const PanelDragArea({required this.child, super.key});

  final Widget child;

  @override
  State<PanelDragArea> createState() => _PanelDragAreaState();
}

/// The drag areas one panel's expanded content currently declares.
@internal
final class PanelDragAreaRegistry {
  final Set<_PanelDragAreaState> _areas = <_PanelDragAreaState>{};

  bool get isEmpty => _areas.isEmpty;

  /// Whether a touch at [globalPosition] landed inside one of them.
  bool contains(Offset globalPosition) =>
      _areas.any((area) => area.containsGlobal(globalPosition));
}

/// Carries the enclosing panel's registry down to its expanded content.
@internal
final class PanelDragAreaScope extends InheritedWidget {
  const PanelDragAreaScope({
    required this.registry,
    required super.child,
    super.key,
  });

  final PanelDragAreaRegistry registry;

  static PanelDragAreaRegistry? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<PanelDragAreaScope>()
      ?.registry;

  @override
  bool updateShouldNotify(PanelDragAreaScope oldWidget) =>
      !identical(oldWidget.registry, registry);
}

class _PanelDragAreaState extends State<PanelDragArea> {
  PanelDragAreaRegistry? _registry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final registry = PanelDragAreaScope.maybeOf(context);
    if (identical(registry, _registry)) return;
    _registry?._areas.remove(this);
    _registry = registry?.._areas.add(this);
  }

  @override
  void dispose() {
    _registry?._areas.remove(this);
    super.dispose();
  }

  /// Whether [globalPosition] falls inside this area's box.
  bool containsGlobal(Offset globalPosition) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return false;
    return (Offset.zero & box.size).contains(box.globalToLocal(globalPosition));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
