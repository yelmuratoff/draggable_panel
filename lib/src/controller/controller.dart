import 'package:draggable_panel/src/enums/dock_type.dart';
import 'package:draggable_panel/src/enums/panel_state.dart';
import 'package:flutter/material.dart';

/// Signature for position change listeners.
typedef PositionListener = void Function(double x, double y);

/// A controller to manage the state and behavior of a draggable panel.
///
/// The [DraggablePanelController] provides functionality for:
/// - Tracking and updating panel position
/// - Handling docking behavior based on specified [DockType]
/// - Managing panel state transitions (open/closed)
/// - Animating the panel movements
/// - Position change notifications for persistence
///
/// - Parameters:
///   - initialPosition: The initial position (x, y) of the panel
///   - initialPanelState: The initial state (open/closed)
///   - panelAnimDuration: Duration of panel animations in milliseconds (default: 300)
///   - dockType: How the panel docks ([DockType.inside] or [DockType.outside])
///   - dockOffset: Offset from screen edge when docking (default: 10.0)
///   - dockAnimDuration: Duration of docking animation in milliseconds
/// - Usage example:
///   ```dart
///   final controller = DraggablePanelController(
///     initialPosition: (x: 100, y: 200),
///     initialPanelState: PanelState.closed,
///     dockType: DockType.inside,
///   );
///
///   // Listen to position changes
///   controller.addPositionListener((x, y) {
///     // Save to local storage
///     prefs.setDouble('panel_x', x);
///     prefs.setDouble('panel_y', y);
///   });
///   ```
final class DraggablePanelController extends ChangeNotifier {
  /// Constructor to initialize the draggable panel controller with optional parameters.
  ///
  /// - Parameters:
  ///   - initialPosition: Starting position as (x, y) record
  ///   - initialPanelState: Starting state (open/closed)
  ///   - panelAnimDuration: Animation duration in ms (default: 300)
  ///   - dockType: Docking behavior (default: [DockType.inside])
  ///   - dockOffset: Edge offset in pixels (default: 10.0)
  ///   - dockAnimDuration: Dock animation duration in ms
  DraggablePanelController({
    this.initialPosition,
    this.initialPanelState,
    this.panelAnimDuration = 300,
    this.dockType = DockType.inside,
    this.dockOffset = 10.0,
    this.dockAnimDuration,
  }) {
    _panelState = initialPanelState ?? PanelState.closed;
    _draggablePositionLeft = initialPosition?.x ?? 0.0;
    _draggablePositionTop = initialPosition?.y ?? 200.0;
  }
  //
  // <--- Parameters --->
  //

  /// The initial position of the panel, defined by its x and y coordinates.
  final ({double x, double y})? initialPosition;

  /// The initial state of the panel.
  /// - [PanelState.open]: The panel is open when initialized.
  /// - [PanelState.closed]: The panel is closed when initialized.
  final PanelState? initialPanelState;

  /// The duration (in milliseconds) of the panel's open/close animation.
  final int panelAnimDuration;

  /// The docking type of the panel.
  /// - [DockType.inside]: The panel docks closer to the screen edges.
  /// - [DockType.outside]: The panel docks slightly away from the screen edges.
  final DockType? dockType;

  /// The offset used when docking the panel.
  /// Default value is `10.0`.
  final double dockOffset;

  /// The duration (in milliseconds) of the docking animation.
  final int? dockAnimDuration;

  //
  // <--- Local Variables --->
  //

  /// Current state of the panel.
  PanelState _panelState = PanelState.closed;

  /// Vertical position of the draggable panel.
  double _draggablePositionTop = 0;

  /// Horizontal position of the draggable panel.
  double _draggablePositionLeft = 0;

  /// The horizontal position of the hidden panel.
  double _panelPositionLeft = 0;

  /// The vertical drag offset.
  double _panOffsetTop = 0;

  /// The horizontal drag offset.
  double _panOffsetLeft = 0;

  /// The speed of the panel's movement.
  int _movementSpeed = 0;

  /// Whether the panel is being dragged.
  bool _isDragging = false;

  /// The width of the button associated with the panel.
  double _buttonWidth = 0;

  /// Constant width of the panel.
  static const double _panelWidth = 200;

  /// Whether the draggable is docked on the right edge. This avoids side
  /// flipping during window resizes; updated in [forceDock].
  bool _isDockedRight = false;

  /// Listeners that are notified when the draggable position (x, y) changes.
  final List<PositionListener> _positionListeners = <PositionListener>[];

  /// Add a listener that is called whenever the draggable position (x, y) changes.
  void addPositionListener(PositionListener listener) {
    if (!_positionListeners.contains(listener)) {
      _positionListeners.add(listener);
    }
  }

  /// Remove a previously added position listener.
  void removePositionListener(PositionListener listener) {
    _positionListeners.remove(listener);
  }

  void _notifyPositionListeners() {
    final x = _draggablePositionLeft;
    final y = _draggablePositionTop;
    for (final listener in _positionListeners) {
      listener(x, y);
    }
  }

  //
  // <--- Getters and Setters --->
  //

  double get panelWidth => _panelWidth;
  PanelState get panelState => _panelState;
  double get draggablePositionTop => _draggablePositionTop;
  double get draggablePositionLeft => _draggablePositionLeft;
  double get panelPositionLeft => _panelPositionLeft;
  double get panOffsetTop => _panOffsetTop;
  double get panOffsetLeft => _panOffsetLeft;
  int get movementSpeed => _movementSpeed;
  bool get isDragging => _isDragging;
  double get buttonWidth => _buttonWidth;
  bool get isDockedRight => _isDockedRight;

  set panelState(PanelState value) {
    _updateValue(() => _panelState = value, _panelState, value);
  }

  set draggablePositionTop(double value) {
    if (_draggablePositionTop == value) return;
    _draggablePositionTop = value;
    _notifyPositionListeners();
    notifyListeners();
  }

  set draggablePositionLeft(double value) {
    if (_draggablePositionLeft == value) return;
    _draggablePositionLeft = value;
    _notifyPositionListeners();
    notifyListeners();
  }

  set panelPositionLeft(double value) {
    _updateValue(() => _panelPositionLeft = value, _panelPositionLeft, value);
  }

  set panOffsetTop(double value) {
    _updateValue(() => _panOffsetTop = value, _panOffsetTop, value);
  }

  set panOffsetLeft(double value) {
    _updateValue(() => _panOffsetLeft = value, _panOffsetLeft, value);
  }

  set movementSpeed(int value) {
    _updateValue(() => _movementSpeed = value, _movementSpeed, value);
  }

  set isDragging(bool value) {
    _updateValue(() => _isDragging = value, _isDragging, value);
  }

  set buttonWidth(double value) {
    _updateValue(() => _buttonWidth = value, _buttonWidth, value);
  }

  /// Helper method to reduce boilerplate in setters.
  void _updateValue<T>(VoidCallback update, T oldValue, T newValue) {
    if (oldValue == newValue) return;
    update();
    notifyListeners();
  }

  /// Sets both position coordinates atomically with a single notification.
  ///
  /// - Parameters:
  ///   - x: Horizontal position
  ///   - y: Vertical position
  /// - Return: void
  /// - Edge case notes: Only notifies listeners if at least one value changed
  void setPosition({required double x, required double y}) {
    if (_draggablePositionLeft == x && _draggablePositionTop == y) return;
    _draggablePositionLeft = x;
    _draggablePositionTop = y;
    _notifyPositionListeners();
    notifyListeners();
  }

  //
  // <--- Action Methods --->
  //

  /// Force the panel to dock to the nearest screen edge.
  ///
  /// - Parameters:
  ///   - pageWidth: The width of the page/screen
  /// - Return: void
  /// - Usage example: controller.forceDock(MediaQuery.sizeOf(context).width)
  /// - Edge case notes: Updates dock side and positions in a single notification
  void forceDock(double pageWidth) {
    final center = _draggablePositionLeft + (_buttonWidth / 2);
    final dockRight = center >= pageWidth / 2;
    final newButtonLeft = dockRight
        ? (pageWidth - _buttonWidth) - _dockBoundary
        : 0.0 + _dockBoundary;
    final newPanelLeft = dockRight ? pageWidth + _buttonWidth : -_buttonWidth;

    movementSpeed = dockAnimDuration ?? 300;

    if (_draggablePositionLeft == newButtonLeft &&
        _panelPositionLeft == newPanelLeft &&
        _isDockedRight == dockRight) {
      return;
    }

    _isDockedRight = dockRight;
    _draggablePositionLeft = newButtonLeft;
    _panelPositionLeft = newPanelLeft;
    _notifyPositionListeners();
    notifyListeners();
  }

  /// Helper to calculate the dock boundary based on [DockType].
  DockType get _effectiveDockType => dockType ?? DockType.inside;

  double get _dockBoundary =>
      _effectiveDockType == DockType.inside ? -dockOffset : dockOffset;

  /// Public accessor for the dock boundary used by widgets to apply consistent constraints.
  double get dockBoundary => _dockBoundary;

  /// Hide the panel completely off-screen.
  ///
  /// - Parameters:
  ///   - pageWidth: The width of the page/screen
  /// - Return: void
  /// - Usage example: controller.hidePanel(MediaQuery.sizeOf(context).width)
  void hidePanel(double pageWidth) {
    final newPanelLeft =
        _isDockedRight ? pageWidth + _panelWidth : -_panelWidth;
    if (_panelPositionLeft == newPanelLeft) return;
    _panelPositionLeft = newPanelLeft;
    notifyListeners();
  }

  /// Toggle the panel's position between open and closed.
  ///
  /// - Parameters:
  ///   - pageWidth: The width of the page/screen
  /// - Return: void
  /// - Usage example: controller.togglePanel(MediaQuery.sizeOf(context).width)
  void togglePanel(double pageWidth) {
    final isOpen = _panelState == PanelState.open;
    final newPanelLeft = isOpen
        ? (_isDockedRight ? pageWidth - _panelWidth - buttonWidth : buttonWidth)
        : (_isDockedRight ? pageWidth : -_panelWidth);
    if (_panelPositionLeft == newPanelLeft) return;
    _panelPositionLeft = newPanelLeft;
    notifyListeners();
  }

  /// Asynchronously toggle the main button state and update the panel's docked position.
  ///
  /// - Parameters:
  ///   - pageWidth: The width of the page/screen
  /// - Return: `Future<void>`
  /// - Usage example: await controller.toggleMainButton(MediaQuery.sizeOf(context).width)
  Future<void> toggleMainButton(double pageWidth) async {
    if (_panelState == PanelState.open) {
      panelState = PanelState.closed;
      forceDock(pageWidth);
      return;
    }

    panelState = PanelState.open;
    final newLeft = _isDockedRight ? pageWidth + _buttonWidth : -_buttonWidth;
    if (_draggablePositionLeft == newLeft) return;

    _draggablePositionLeft = newLeft;
    _notifyPositionListeners();
    notifyListeners();
  }

  /// Recompute dock side based on current button position and page width without
  /// moving it to a new edge. Useful during window resize.
  ///
  /// - Parameters:
  ///   - pageWidth: The width of the page/screen
  /// - Return: void
  /// - Edge case notes: Does not notify listeners; caller handles notification
  void recomputeDockSide(double pageWidth) {
    final center = _draggablePositionLeft + (_buttonWidth / 2);
    _isDockedRight = center >= pageWidth / 2;
  }

  /// Toggle the panel's behavior based on its initial state.
  ///
  /// - Parameters:
  ///   - context: The current BuildContext
  /// - Return: void
  /// - Usage example: controller.toggle(context)
  void toggle(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (_panelState == PanelState.open) {
      panelState = PanelState.closed;
      isDragging = false;
      forceDock(width);
      hidePanel(width);
    } else {
      toggleMainButton(width);
      togglePanel(width);
    }
  }
}
