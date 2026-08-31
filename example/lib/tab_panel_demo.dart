import 'package:draggable_panel/draggable_panel.dart';
import 'package:flutter/material.dart';

/// The same tools panel with its collapsed stage switched off.
///
/// `collapsible: false` leaves the panel two stages instead of three: it opens
/// as it comes out of the park rather than resting as a small window first, and
/// every way of closing it — the header control, a tap outside, Esc — parks it
/// again.
///
/// It also holds more actions than it can show, so the grid scrolls: the header
/// the preset builds is the panel's [PanelDragArea], and moving the panel means
/// dragging that rather than the grid.
class TabPanelDemo extends StatefulWidget {
  const TabPanelDemo({super.key});

  @override
  State<TabPanelDemo> createState() => _TabPanelDemoState();
}

class _TabPanelDemoState extends State<TabPanelDemo> {
  final _controller = DraggablePanelController(
    initialPlacement: const PanelPlacement.stashed(PanelEdge.end),
  );
  String _lastAction = 'none';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _run(String name) {
    setState(() => _lastAction = name);
    _controller.collapse();
  }

  @override
  Widget build(BuildContext context) => DraggableActionPanel(
    controller: _controller,
    behavior: const PanelBehavior(collapsible: false),
    theme: const DraggablePanelThemeData(collapsedSize: Size(56, 56)),
    title: 'Developer tools',
    onClose: _controller.collapse,
    actions: [
      PanelAction(
        icon: Icons.article_outlined,
        label: 'Logs',
        badge: const PanelBadge(label: '3'),
        onPressed: () => _run('Logs'),
      ),
      PanelAction(
        icon: Icons.speed_outlined,
        label: 'Performance',
        onPressed: () => _run('Performance'),
      ),
      PanelAction(
        icon: Icons.palette_outlined,
        label: 'Theme',
        onPressed: () => _run('Theme'),
      ),
      PanelAction(
        icon: Icons.storage_outlined,
        label: 'Storage',
        onPressed: () => _run('Storage'),
      ),
      PanelAction(
        icon: Icons.wifi_outlined,
        label: 'Network',
        onPressed: () => _run('Network'),
      ),
      PanelAction(
        icon: Icons.terminal_outlined,
        label: 'Console',
        onPressed: () => _run('Console'),
      ),
      PanelAction(
        icon: Icons.account_tree_outlined,
        label: 'Inspector',
        onPressed: () => _run('Inspector'),
      ),
      PanelAction(
        icon: Icons.cached_outlined,
        label: 'Cache',
        onPressed: () => _run('Cache'),
      ),
      PanelAction(
        icon: Icons.dataset_outlined,
        label: 'Database',
        onPressed: () => _run('Database'),
      ),
      PanelAction(
        icon: Icons.flag_outlined,
        label: 'Feature flags',
        onPressed: () => _run('Feature flags'),
      ),
      PanelAction(
        icon: Icons.link_outlined,
        label: 'Deep links',
        onPressed: () => _run('Deep links'),
      ),
      PanelAction(
        icon: Icons.notifications_outlined,
        label: 'Notifications',
        onPressed: () => _run('Notifications'),
      ),
      PanelAction(
        icon: Icons.lock_outlined,
        label: 'Permissions',
        onPressed: () => _run('Permissions'),
      ),
      PanelAction(
        icon: Icons.phone_iphone_outlined,
        label: 'Device info',
        onPressed: () => _run('Device info'),
      ),
      PanelAction(
        icon: Icons.language_outlined,
        label: 'Locale',
        onPressed: () => _run('Locale'),
      ),
      PanelAction(
        icon: Icons.insights_outlined,
        label: 'Analytics',
        onPressed: () => _run('Analytics'),
      ),
      PanelAction(
        icon: Icons.bug_report_outlined,
        label: 'Crashes',
        onPressed: () => _run('Crashes'),
      ),
      PanelAction(
        icon: Icons.dns_outlined,
        label: 'Environment',
        onPressed: () => _run('Environment'),
      ),
      PanelAction(
        icon: Icons.accessibility_new_outlined,
        label: 'Accessibility',
        onPressed: () => _run('Accessibility'),
      ),
      PanelAction(
        icon: Icons.history_outlined,
        label: 'Sessions',
        onPressed: () => _run('Sessions'),
      ),
    ],
    buttons: [
      PanelActionButton(
        icon: Icons.copy_outlined,
        label: 'Copy device info',
        onPressed: () => _run('Copy device info'),
      ),
    ],
    child: Scaffold(
      appBar: AppBar(title: const Text('Tab panel')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pull the tab out — it opens on the way.'),
            const SizedBox(height: 24),
            const Text('Last action'),
            const SizedBox(height: 8),
            Text(_lastAction, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    ),
  );
}
