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
  final DraggablePanelController controller = DraggablePanelController();

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
                child: const Text('Tap'),
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
                icon: Icons.list,
                onTap: (context) {},
              ),
              DraggablePanelItem(
                enableBadge: false,
                icon: Icons.list,
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
              // (
              //   icon: Icons.copy,
              //   onTap: (context) {},
              //   label: 'Push token',
              // ),
              // (
              //   icon: Icons.copy,
              //   onTap: (context) {},
              //   label: 'Push token',
              // ),
              // (
              //   icon: Icons.copy,
              //   onTap: (context) {},
              //   label: 'Push token',
              // ),
            ],
            controller: controller,
            child: child,
          ),
        );
      },
    );
  }
}
