part of '../draggable_panel.dart';

class _PanelButton extends StatelessWidget {
  const _PanelButton({
    required Color itemColor,
    required this.pageWidth,
    required this.onTap,
    required this.icon,
    required this.label,
    this.onLongPress,
  }) : _itemColor = itemColor;

  final Color _itemColor;
  final double pageWidth;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 45,
        width: double.maxFinite,
        child: MaterialButton(
          onPressed: onTap,
          onLongPress: onLongPress,
          color: _itemColor,
          highlightElevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          elevation: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const Flexible(
                child: SizedBox(
                  width: 12,
                ),
              ),
              Flexible(
                flex: 6,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
