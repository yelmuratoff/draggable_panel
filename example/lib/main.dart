import 'package:draggable_panel/draggable_panel.dart';
import 'package:draggable_panel_example/mini_player_demo.dart';
import 'package:draggable_panel_example/tab_panel_demo.dart';
import 'package:draggable_panel_example/theming_demo.dart';
import 'package:draggable_panel_example/tools_demo.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

/// Demonstrates the three shapes a [DraggablePanel] usually takes.
class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleBrightness() => setState(() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  });

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'draggable_panel',
    theme: ThemeData(colorSchemeSeed: Colors.indigo),
    darkTheme: ThemeData(
      colorSchemeSeed: Colors.indigo,
      brightness: Brightness.dark,
    ),
    themeMode: _themeMode,
    routes: {
      '/player': (_) => const MiniPlayerDemo(),
      '/tools': (_) => const ToolsDemo(),
      '/tab': (_) => const TabPanelDemo(),
      '/theming': (_) => const ThemingDemo(),
    },
    home: _HomeScreen(onToggleBrightness: _toggleBrightness),
  );
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen({required this.onToggleBrightness});

  final VoidCallback onToggleBrightness;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('draggable_panel'),
      actions: [
        IconButton(
          onPressed: onToggleBrightness,
          icon: const Icon(Icons.brightness_6_outlined),
          tooltip: 'Toggle brightness',
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _DemoTile(
          route: '/player',
          icon: Icons.play_circle_outline,
          title: 'Mini player',
          subtitle: 'Picture-in-Picture window over a scrolling page',
        ),
        _DemoTile(
          route: '/tools',
          icon: Icons.build_outlined,
          title: 'Developer tools',
          subtitle: 'An action grid that expands from the corner',
        ),
        _DemoTile(
          route: '/tab',
          icon: Icons.chevron_left_outlined,
          title: 'Tab panel',
          subtitle: 'The same grid with its collapsed stage switched off',
        ),
        _DemoTile(
          route: '/theming',
          icon: Icons.tune_outlined,
          title: 'Theming playground',
          subtitle: 'Shape, elevation and spring tuning side by side',
        ),
      ],
    ),
  );
}

class _DemoTile extends StatelessWidget {
  const _DemoTile({
    required this.route,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final String route;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).pushNamed(route),
    ),
  );
}
