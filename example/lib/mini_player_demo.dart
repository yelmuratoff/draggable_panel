import 'package:draggable_panel/draggable_panel.dart';
import 'package:flutter/material.dart';

/// A mini player floating over a scrolling page.
class MiniPlayerDemo extends StatefulWidget {
  const MiniPlayerDemo({super.key});

  @override
  State<MiniPlayerDemo> createState() => _MiniPlayerDemoState();
}

class _MiniPlayerDemoState extends State<MiniPlayerDemo> {
  final _controller = DraggablePanelController();
  bool _playing = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayback() => setState(() => _playing = !_playing);

  @override
  Widget build(BuildContext context) => DraggablePanel(
    controller: _controller,
    theme: const DraggablePanelThemeData(
      collapsedSize: Size(132, 78),
      expandedExtent: PanelExtent.content(maxWidth: 340),
    ),
    collapsedBuilder: (context, status) => _Artwork(playing: _playing),
    expandedBuilder: (context, status) =>
        _PlayerCard(playing: _playing, onTogglePlayback: _togglePlayback),
    child: Scaffold(
      appBar: AppBar(title: const Text('Mini player')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 30,
        itemBuilder: (context, index) => ListTile(
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text('Track ${index + 1}'),
          subtitle: const Text('Drag the player, flick it to a corner'),
        ),
      ),
    ),
  );
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.playing});

  final bool playing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.primaryContainer,
      child: Center(
        child: Icon(
          playing ? Icons.graphic_eq : Icons.pause,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.playing, required this.onTogglePlayback});

  final bool playing;
  final VoidCallback onTogglePlayback;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Now playing',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: DraggablePanelScope.of(context).collapse,
                icon: const Icon(Icons.close),
                tooltip: 'Collapse',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Container(
              height: 96,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.album_outlined,
                size: 48,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const IconButton(
                onPressed: null,
                icon: Icon(Icons.skip_previous),
              ),
              IconButton.filled(
                onPressed: onTogglePlayback,
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              ),
              const IconButton(onPressed: null, icon: Icon(Icons.skip_next)),
            ],
          ),
        ],
      ),
    );
  }
}
