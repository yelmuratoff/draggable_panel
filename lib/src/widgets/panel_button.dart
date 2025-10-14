part of '../draggable_panel.dart';

final class _PanelButton extends StatelessWidget {
  const _PanelButton({
    required this.itemColor,
    required this.onTap,
    required this.icon,
    required this.label,
    this.onLongPress,
  });

  final Color itemColor;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 45,
        width: double.maxFinite,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: itemColor,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            elevation: 0,
          ),
          onPressed: onTap,
          onLongPress: onLongPress,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
}
