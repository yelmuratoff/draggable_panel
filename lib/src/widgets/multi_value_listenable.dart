import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A widget that rebuilds when any of multiple [ValueListenable]s change.
///
/// This is useful when you need to listen to multiple independent
/// [ValueListenable] objects and rebuild the UI when any of them changes.
final class MultiValueListenableBuilder extends StatefulWidget {
  /// Creates a multi-value listenable builder.
  ///
  /// - [valueListenables]: The list of listenables to observe.
  /// - [builder]: The builder function called when any listenable changes.
  const MultiValueListenableBuilder({
    required this.valueListenables,
    required this.builder,
    super.key,
  });

  /// The list of [ValueListenable] objects to observe for changes.
  final List<ValueListenable<dynamic>> valueListenables;

  /// The builder function that creates the widget tree.
  final WidgetBuilder builder;

  @override
  State<MultiValueListenableBuilder> createState() =>
      _MultiValueListenableBuilderState();
}

final class _MultiValueListenableBuilderState
    extends State<MultiValueListenableBuilder> {
  Listenable? _mergedListenable;

  @override
  void initState() {
    super.initState();
    _updateListeners(widget.valueListenables);
  }

  @override
  void didUpdateWidget(covariant MultiValueListenableBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.valueListenables, oldWidget.valueListenables)) {
      _updateListeners(widget.valueListenables);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _mergedListenable?.removeListener(_onUpdated);
    super.dispose();
  }

  void _onUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  void _updateListeners(List<ValueListenable<dynamic>> listenables) {
    _mergedListenable?.removeListener(_onUpdated);
    if (listenables.isEmpty) {
      _mergedListenable = null;
      return;
    }
    _mergedListenable = Listenable.merge(listenables)..addListener(_onUpdated);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
