part of '../draggable_panel.dart';

class _PanelButton extends StatelessWidget {
  const _PanelButton({
    required Color itemColor,
    required this.pageWidth,
    required this.onTap,
    required this.icon,
    required this.label,
  }) : _itemColor = itemColor;

  final Color _itemColor;
  final double pageWidth;
  final VoidCallback onTap;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 45,
          minHeight: 45,
          minWidth: double.infinity,
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            top: 4,
            left: 8,
            right: 8,
          ),
          child: MaterialButton(
            onPressed: onTap,
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
        ),
      );
}
