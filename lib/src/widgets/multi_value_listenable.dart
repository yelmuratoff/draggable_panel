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
  @override
  void initState() {
    super.initState();
    _registerListeners(widget.valueListenables);
  }

  void _onUpdated() {
    if (!mounted) return;
    setState(() {});
  }

  void _registerListeners(Iterable<ValueListenable<dynamic>> listenables) {
    for (final listenable in listenables) {
      listenable.addListener(_onUpdated);
    }
  }

  @override
  void didUpdateWidget(covariant MultiValueListenableBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.valueListenables, oldWidget.valueListenables)) {
      _deregisterListeners(oldWidget.valueListenables);
      _registerListeners(widget.valueListenables);
    }
  }

  void _deregisterListeners(Iterable<ValueListenable<dynamic>> listenables) {
    for (final listenable in listenables) {
      listenable.removeListener(_onUpdated);
    }
  }

  @override
  void dispose() {
    _deregisterListeners(widget.valueListenables);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
