import 'package:flutter/foundation.dart';

/// A projection of another [Listenable] that notifies only when the projected
/// value actually changes.
///
/// Lets a listener depend on one narrow aspect of a larger object — a panel's
/// placement, say — without waking every time some unrelated part of it moves.
final class DerivedNotifier<T> extends ChangeNotifier
    implements ValueListenable<T> {
  DerivedNotifier(this._source, this._project) : _value = _project() {
    _source.addListener(_recompute);
  }

  final Listenable _source;
  final T Function() _project;

  T _value;

  @override
  T get value => _value;

  void _recompute() {
    final next = _project();
    if (next == _value) return;
    _value = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _source.removeListener(_recompute);
    super.dispose();
  }
}
