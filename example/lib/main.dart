import 'package:draggable_panel/draggable_panel.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    const App(),
  );
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool isEnabled = true;
  bool isDarkMode = false;
  bool useCustomTheme = false;
  final controller = DraggablePanelController(initialPosition: (x: 40, y: 100));

  @override
  void initState() {
    super.initState();

    controller.addPositionListener(_positionChanged);
    controller.setPosition(x: 500, y: 500);
  }

  void _positionChanged(double x, double y) {
    debugPrint('Position changed: ($x, $y)');
  }

  @override
  void dispose() {
    super.dispose();
    controller.removePositionListener(_positionChanged);
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isEnabled = !isEnabled;
                  });
                },
                child: Text('Panel: ${isEnabled ? "ON" : "OFF"}'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isDarkMode = !isDarkMode;
                  });
                },
                child: Text('Theme: ${isDarkMode ? "Dark" : "Light"}'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    useCustomTheme = !useCustomTheme;
                  });
                },
                child: Text('Colors: ${useCustomTheme ? "Custom" : "Default"}'),
              ),
            ],
          ),
        ),
      ),
      builder: (context, child) {
        return Visibility(
          visible: isEnabled,
          replacement: child!,
          child: DraggablePanel(
            theme: useCustomTheme
                ? DraggablePanelTheme(
                    panelBackgroundColor:
                        const Color(0xFF1E1E1E).withValues(alpha: 0.9),
                    panelBorderRadius: BorderRadius.circular(24),
                    panelBorder: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 2,
                    ),
                    panelWidth: 220,
                    panelContentPadding: const EdgeInsets.all(12),
                    itemSpacing: 10,
                    buttonSpacing: 8,
                    sectionSpacing: 12,
                    panelItemColor:
                        const Color(0xFF1E1E1E).withValues(alpha: 0.7),
                    draggableButtonColor:
                        const Color(0xFF1E1E1E).withValues(alpha: 0.9),
                    foregroundColor: Colors.white,
                    panelBoxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    itemTheme: const DraggablePanelItemThemeData(
                      borderRadius: 16,
                      padding: EdgeInsets.all(10),
                    ),
                    buttonTheme: const DraggablePanelButtonThemeData(
                      height: 48,
                      borderRadius: 20,
                      iconSize: 20,
                    ),
                    handleTheme: const DraggablePanelHandleThemeData(
                      curveStrokeWidth: 4,
                    ),
                    tooltipTheme: const DraggablePanelTooltipThemeData(
                      contentBorderRadius: 20,
                      fontSize: 13,
                    ),
                  )
                : const DraggablePanelTheme(),
            items: [
              DraggablePanelItem(
                enableBadge: false,
                icon: Icons.list,
                onTap: (context) {},
                description: 'This is a list item',
              ),
              DraggablePanelItem(
                enableBadge: false,
                icon: Icons.color_lens,
                onTap: (context) {},
                description: 'This is a color lens item',
              ),
              DraggablePanelItem(
                enableBadge: false,
                icon: Icons.zoom_in,
                onTap: (context) {},
                description: 'This is a zoom in item',
              ),
              DraggablePanelItem(
                enableBadge: false,
                icon: Icons.token,
                onTap: (context) {},
              ),
              DraggablePanelItem(
                enableBadge: false,
                icon: Icons.color_lens,
                onTap: (context) {},
                description: 'This is a color lens item',
              ),
              DraggablePanelItem(
                enableBadge: false,
                icon: Icons.zoom_in,
                onTap: (context) {},
                description: 'This is a zoom in item',
              ),
              DraggablePanelItem(
                enableBadge: false,
                icon: Icons.token,
                onTap: (context) {},
              ),
              DraggablePanelItem(
                enableBadge: false,
                icon: Icons.color_lens,
                onTap: (context) {},
                description: 'This is a color lens item',
              ),
              DraggablePanelItem(
                enableBadge: false,
                icon: Icons.zoom_in,
                onTap: (context) {},
                description: 'This is a zoom in item',
              ),
              DraggablePanelItem(
                enableBadge: false,
                icon: Icons.token,
                onTap: (context) {},
              ),
            ],
            buttons: [
              DraggablePanelButtonItem(
                icon: Icons.copy,
                onTap: (context) {
                  // Hide
                  controller.toggle(context);
                },
                label: 'Push token',
                description: 'This is a push token button',
              ),
              DraggablePanelButtonItem(
                icon: Icons.copy,
                onTap: (context) {
                  // Hide
                  controller.toggle(context);
                },
                label: 'Push token',
                description: 'This is a push token button',
              ),
              DraggablePanelButtonItem(
                icon: Icons.copy,
                onTap: (context) {
                  // Hide
                  controller.toggle(context);
                },
                label: 'Push token',
                description: 'This is a push token button',
              ),
              DraggablePanelButtonItem(
                icon: Icons.copy,
                onTap: (context) {
                  // Hide
                  controller.toggle(context);
                },
                label: 'Push token',
                description: 'This is a push token button',
              ),
              DraggablePanelButtonItem(
                icon: Icons.copy,
                onTap: (context) {
                  // Hide
                  controller.toggle(context);
                },
                label: 'Push token',
                description: 'This is a push token button',
              ),
              DraggablePanelButtonItem(
                icon: Icons.copy,
                onTap: (context) {
                  // Hide
                  controller.toggle(context);
                },
                label: 'Push token',
                description: 'This is a push token button',
              ),
            ],
            controller: controller,
            child: child,
          ),
        );
      },
    );
  }
}
