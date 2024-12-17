import 'package:flutter/widgets.dart';

class DraggablePanelButton {
  const DraggablePanelButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final void Function(BuildContext context) onTap;
}
