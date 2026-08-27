import 'package:draggable_panel/draggable_panel.dart';
import 'package:flutter/material.dart';

/// The bar shown on the sliver of a stashed panel that stays on screen.
///
/// A stashed panel keeps only `stashedPeek` logical pixels visible, so content
/// centred in the collapsed face falls off the edge and the tab reads as blank.
/// This aligns a grip to whichever side is still showing.
class EdgeGrip extends StatelessWidget {
  const EdgeGrip({required this.edge, super.key});

  /// The edge the panel is parked against. The visible sliver is opposite it.
  final PanelEdge edge;

  @override
  Widget build(BuildContext context) => Align(
    alignment: edge == PanelEdge.end
        ? AlignmentDirectional.centerStart
        : AlignmentDirectional.centerEnd,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: 4,
        height: 28,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  );
}

/// Renders [whenVisible], or a grip while the panel is parked at an edge.
Widget collapsedFace(PanelStatus status, Widget whenVisible) =>
    switch (status.placement) {
      StashedPlacement(:final edge) => EdgeGrip(edge: edge),
      _ => whenVisible,
    };
