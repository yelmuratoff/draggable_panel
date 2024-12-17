part of '../draggable_panel.dart';

class _HidePanel extends StatelessWidget {
  const _HidePanel({
    required Color itemColor,
    required ValueNotifier<double> positionLeft,
    required ValueNotifier<double> panOffsetLeft,
    required this.pageWidth,
    required this.onTap,
  })  : _itemColor = itemColor,
        _positionLeft = positionLeft,
        _panOffsetLeft = panOffsetLeft;

  final Color _itemColor;
  final ValueNotifier<double> _positionLeft;
  final ValueNotifier<double> _panOffsetLeft;
  final double pageWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 45,
        ),
        child: SizedBox(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
            child: MaterialButton(
              onPressed: onTap,
              color: _itemColor,
              highlightElevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              elevation: 0,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if ((_positionLeft.value + _panOffsetLeft.value) < pageWidth / 2) ...[
                      const Flexible(
                        flex: 2,
                        child: Icon(
                          Icons.undo_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const Flexible(
                        child: SizedBox(
                          width: 12,
                        ),
                      ),
                    ],
                    Flexible(
                      flex: 2,
                      child: Text(
                        'Hide',
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if ((_positionLeft.value + _panOffsetLeft.value) > pageWidth / 2) ...[
                      const Flexible(
                        child: SizedBox(
                          width: 12,
                        ),
                      ),
                      const Flexible(
                        flex: 2,
                        child: Icon(
                          Icons.redo_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
