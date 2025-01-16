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
  final DraggablePanelController controller = DraggablePanelController();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {},
                child: const Text('Tap'),
              ),
            ],
          ),
        ),
      ),
      builder: (context, child) {
        return DraggablePanel(
          items: [
            (
              enableBadge: false,
              icon: Icons.list,
              onTap: (context) {},
            ),
            (
              enableBadge: false,
              icon: Icons.color_lens,
              onTap: (context) {},
            ),
            (
              enableBadge: false,
              icon: Icons.zoom_in,
              onTap: (context) {},
            ),
            (
              enableBadge: false,
              icon: Icons.token,
              onTap: (context) {},
            ),
            (
              enableBadge: false,
              icon: Icons.list,
              onTap: (context) {},
            ),
            (
              enableBadge: false,
              icon: Icons.list,
              onTap: (context) {},
            ),
            // (
            //   enableBadge: false,
            //   icon: Icons.color_lens,
            //   onTap: (context) {},
            // ),
            // (
            //   enableBadge: false,
            //   icon: Icons.zoom_in,
            //   onTap: (context) {},
            // ),
            // (
            //   enableBadge: false,
            //   icon: Icons.token,
            //   onTap: (context) {},
            // ),
            // (
            //   enableBadge: false,
            //   icon: Icons.list,
            //   onTap: (context) {},
            // ),
            // (
            //   enableBadge: false,
            //   icon: Icons.zoom_in,
            //   onTap: (context) {},
            // ),
            // (
            //   enableBadge: false,
            //   icon: Icons.token,
            //   onTap: (context) {},
            // ),
            // (
            //   enableBadge: false,
            //   icon: Icons.list,
            //   onTap: (context) {},
            // ),
            // (
            //   enableBadge: false,
            //   icon: Icons.zoom_in,
            //   onTap: (context) {},
            // ),
            // (
            //   enableBadge: false,
            //   icon: Icons.token,
            //   onTap: (context) {},
            // ),
            // (
            //   enableBadge: false,
            //   icon: Icons.list,
            //   onTap: (context) {},
            // ),
            // (
            //   enableBadge: false,
            //   icon: Icons.zoom_in,
            //   onTap: (context) {},
            // ),
            // (
            //   enableBadge: false,
            //   icon: Icons.token,
            //   onTap: (context) {},
            // ),
            // (
            //   enableBadge: false,
            //   icon: Icons.list,
            //   onTap: (context) {},
            // ),
            // (
            //   enableBadge: false,
            //   icon: Icons.zoom_in,
            //   onTap: (context) {},
            // ),
            // (
            //   enableBadge: false,
            //   icon: Icons.token,
            //   onTap: (context) {},
            // ),
            // (
            //   enableBadge: false,
            //   icon: Icons.list,
            //   onTap: (context) {},
            // ),
          ],
          buttons: [
            (
              icon: Icons.copy,
              onTap: (context) {
                // Hide
                controller.toggle(context);
              },
              label: 'Push token',
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
          child: child!,
        );
      },
    );
  }
}
