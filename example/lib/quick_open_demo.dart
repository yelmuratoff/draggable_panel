import 'package:draggable_panel/draggable_panel.dart';
import 'package:flutter/material.dart';

/// The same tools panel with only the way out of the park shortened.
///
/// `expandOnUnstash: true` opens the grid straight from the tab, but unlike
/// `collapsible: false` it keeps the collapsed window: close the panel and it
/// lands there, ready to be dragged around or pushed back off the edge. The
/// phase readout below names whichever stage the panel is in, so the one the
/// `Tab panel` demo does without is visible here.
class QuickOpenDemo extends StatefulWidget {
  const QuickOpenDemo({super.key});

  @override
  State<QuickOpenDemo> createState() => _QuickOpenDemoState();
}

class _QuickOpenDemoState extends State<QuickOpenDemo> {
  final _controller = DraggablePanelController(
    initialPlacement: const PanelPlacement.stashed(PanelEdge.end),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DraggableActionPanel(
    controller: _controller,
    behavior: const PanelBehavior(expandOnUnstash: true),
    theme: const DraggablePanelThemeData(collapsedSize: Size(56, 56)),
    title: 'Developer tools',
    onClose: _controller.collapse,
    actions: [
      PanelAction(
        icon: Icons.article_outlined,
        label: 'Logs',
        badge: const PanelBadge(label: '3'),
        onPressed: _controller.collapse,
      ),
      PanelAction(
        icon: Icons.speed_outlined,
        label: 'Performance',
        onPressed: _controller.collapse,
      ),
      PanelAction(
        icon: Icons.palette_outlined,
        label: 'Theme',
        onPressed: _controller.collapse,
      ),
      PanelAction(
        icon: Icons.storage_outlined,
        label: 'Storage',
        onPressed: _controller.collapse,
      ),
    ],
    child: Scaffold(
      appBar: AppBar(title: const Text('Quick open')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tap the tab: it opens the grid without stopping at the '
                'small window. Close the panel and the small window is '
                'still there — drag it about, or push it back off the edge.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const Text('Stage'),
              const SizedBox(height: 8),
              ListenableBuilder(
                listenable: _controller.phaseListenable,
                builder: (context, _) => Text(
                  _controller.phase.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
