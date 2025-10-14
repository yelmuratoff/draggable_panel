import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MultiValueListenableBuilder extends StatefulWidget {
  const MultiValueListenableBuilder({
    required this.valueListenables,
    required this.builder,
    super.key,
  });

  final List<ValueListenable<dynamic>> valueListenables;
  final WidgetBuilder builder;

  @override
  State<MultiValueListenableBuilder> createState() =>
      _MultiValueListenableBuilderState();
}

class _MultiValueListenableBuilderState
    extends State<MultiValueListenableBuilder> {
  Listenable? _mergedListenable;

  @override
  void initState() {
    super.initState();
    _updateListeners(widget.valueListenables);
  }

  void _onUpdated() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant MultiValueListenableBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.valueListenables, oldWidget.valueListenables)) {
      _updateListeners(widget.valueListenables);
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
  void dispose() {
    _mergedListenable?.removeListener(_onUpdated);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
