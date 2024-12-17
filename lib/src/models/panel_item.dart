import 'package:flutter/material.dart';

class DraggablePanelItem {
  const DraggablePanelItem({
    required this.icon,
    required this.onTap,
    this.enableBadge = false,
  });

  final IconData icon;
  final bool enableBadge;
  final void Function(BuildContext context) onTap;
}
