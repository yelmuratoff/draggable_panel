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
    _registerListeners();
  }

  void _onUpdated() {
    if (!mounted) return;
    setState(() {});
  }

  void _registerListeners() {
    for (final listenable in widget.valueListenables) {
      listenable.addListener(_onUpdated);
    }
  }

  @override
  void didUpdateWidget(covariant MultiValueListenableBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.valueListenables, oldWidget.valueListenables)) {
      _deregisterListeners();
      _registerListeners();
    }
  }

  void _deregisterListeners() {
    for (final listenable in widget.valueListenables) {
      listenable.removeListener(_onUpdated);
    }
  }

  @override
  void dispose() {
    _deregisterListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
