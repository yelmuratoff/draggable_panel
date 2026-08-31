import 'dart:ui' show ImageFilter;

import 'package:draggable_panel/draggable_panel.dart';
import 'package:flutter/material.dart';

/// Retunes the panel's shape and springs live, so the difference is felt
/// rather than described.
class ThemingDemo extends StatefulWidget {
  const ThemingDemo({super.key});

  @override
  State<ThemingDemo> createState() => _ThemingDemoState();
}

class _ThemingDemoState extends State<ThemingDemo> {
  /// Starts parked at the edge, so the first thing you can do is pull it open.
  final _controller = DraggablePanelController(
    initialPlacement: const PanelPlacement.stashed(PanelEdge.end),
  );

  bool _squircle = false;
  bool _frosted = false;
  bool _stashable = true;
  double _responseMs = 400;
  double _bounce = 0;
  double _elevation = 6;

  DraggablePanelThemeData _themeOf(BuildContext context) =>
      DraggablePanelThemeData(
        collapsedShape: _shape(20),
        shape: _shape(28),
        elevation: _elevation,
        surfaceFilter: _frosted
            ? ImageFilter.blur(sigmaX: 24, sigmaY: 24)
            : null,
        surfaceColor: _frosted
            ? Theme.of(
                context,
              ).colorScheme.surfaceContainerHigh.withValues(alpha: 0.6)
            : null,
        collapsedSize: const Size(72, 72),
        expandedExtent: const PanelExtent.content(maxWidth: 300),
        motion: PanelMotionSpec(
          snapSpring: SpringDescription.withDurationAndBounce(
            duration: Duration(milliseconds: _responseMs.round()),
            bounce: _bounce,
          ),
        ),
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// `RoundedSuperellipseBorder` is Flutter's iOS-accurate squircle, available
  /// since 3.32; the default stays a plain rounded rectangle to match Material.
  ShapeBorder _shape(double radius) => _squircle
      ? RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(radius))
      : RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

  @override
  Widget build(BuildContext context) => DraggablePanel(
    controller: _controller,
    theme: _themeOf(context),
    behavior: PanelBehavior(stashable: _stashable),
    collapsedBuilder: (context, status) =>
        Icon(Icons.tune, color: Theme.of(context).colorScheme.onSurface),
    expandedBuilder: (context, status) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Phase', style: Theme.of(context).textTheme.labelMedium),
          Text(
            status.phase.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              '${status.placement}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    ),
    child: Scaffold(
      appBar: AppBar(title: const Text('Theming playground')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          SwitchListTile(
            value: _squircle,
            onChanged: (value) => setState(() => _squircle = value),
            title: const Text('iOS squircle corners'),
            subtitle: const Text('RoundedSuperellipseBorder'),
          ),
          SwitchListTile(
            value: _frosted,
            onChanged: (value) => setState(() => _frosted = value),
            title: const Text('Frosted glass'),
            subtitle: const Text('surfaceFilter + translucent surfaceColor'),
          ),
          SwitchListTile(
            value: _stashable,
            onChanged: (value) => setState(() => _stashable = value),
            title: const Text('Stash off the edge'),
            subtitle: const Text('Flick sideways to park it'),
          ),
          _Slider(
            label: 'Spring response',
            value: _responseMs,
            min: 150,
            max: 900,
            display: '${_responseMs.round()} ms',
            onChanged: (value) => setState(() => _responseMs = value),
          ),
          _Slider(
            label: 'Bounce',
            value: _bounce,
            max: 0.6,
            display: _bounce.toStringAsFixed(2),
            onChanged: (value) => setState(() => _bounce = value),
          ),
          _Slider(
            label: 'Elevation',
            value: _elevation,
            max: 24,
            display: _elevation.toStringAsFixed(0),
            onChanged: (value) => setState(() => _elevation = value),
          ),
        ],
      ),
    ),
  );
}

class _Slider extends StatelessWidget {
  const _Slider({
    required this.label,
    required this.value,
    required this.max,
    required this.display,
    required this.onChanged,
    this.min = 0,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('$label — $display'),
      ),
      Slider(
        value: value,
        min: min,
        max: max,
        label: display,
        onChanged: onChanged,
      ),
    ],
  );
}
