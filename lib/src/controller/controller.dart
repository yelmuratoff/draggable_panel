import 'package:draggable_panel/src/enums/dock_type.dart';
import 'package:draggable_panel/src/enums/panel_state.dart';
import 'package:flutter/material.dart';

/// A controller to manage the state and behavior of a draggable panel.
///
/// The [DraggablePanelController] provides functionality for:
/// - Tracking and updating panel position.
/// - Handling docking behavior based on specified [DockType].
/// - Managing panel state transitions (open/closed).
/// - Animating the panel movements.
final class DraggablePanelController extends ChangeNotifier {
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

  /// Constructor to initialize the draggable panel controller with optional parameters.
  ///
  /// Defaults:
  /// - [panelAnimDuration]: 300 ms.
  /// - [dockType]: [DockType.inside].
  /// - [dockOffset]: 10.0.
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
  // <--- Local Variables --->
  //

  /// Current state of the panel.
  PanelState _panelState = PanelState.closed;

  /// Vertical position of the draggable panel.
  double _draggablePositionTop = 0.0;

  /// Horizontal position of the draggable panel.
  double _draggablePositionLeft = 0.0;

  /// The horizontal position of the hidden panel.
  double _panelPositionLeft = 0.0;

  /// The vertical drag offset.
  double _panOffsetTop = 0.0;

  /// The horizontal drag offset.
  double _panOffsetLeft = 0.0;

  /// The speed of the panel's movement.
  int _movementSpeed = 0;

  /// Whether the panel is being dragged.
  bool _isDragging = false;

  /// The width of the button associated with the panel.
  double _buttonWidth = 0.0;

  /// Constant width of the panel.
  static const double _panelWidth = 200;

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

  set panelState(PanelState value) {
    _panelState = value;
    notifyListeners();
  }

  set draggablePositionTop(double value) {
    _draggablePositionTop = value;
    notifyListeners();
  }

  set draggablePositionLeft(double value) {
    _draggablePositionLeft = value;
    notifyListeners();
  }

  set panelPositionLeft(double value) {
    _panelPositionLeft = value;
    notifyListeners();
  }

  set panOffsetTop(double value) {
    _panOffsetTop = value;
    notifyListeners();
  }

  set panOffsetLeft(double value) {
    _panOffsetLeft = value;
    notifyListeners();
  }

  set movementSpeed(int value) {
    _movementSpeed = value;
    notifyListeners();
  }

  set isDragging(bool value) {
    _isDragging = value;
    notifyListeners();
  }

  set buttonWidth(double value) {
    _buttonWidth = value;
    notifyListeners();
  }

  //
  // <--- Action Methods --->
  //

  /// Force the panel to dock to the nearest screen edge.
  ///
  /// - [pageWidth]: The width of the page/screen.
  void forceDock(double pageWidth) {
    // Calculate the center of the panel.
    final center = _draggablePositionLeft + (_buttonWidth / 2);

    // Set the movement speed for docking.
    _movementSpeed = dockAnimDuration ?? 300;

    // Determine docking behavior based on the center position.
    if (center < pageWidth / 2) {
      _draggablePositionLeft = 0.0 + _dockBoundary;
      _panelPositionLeft = -_buttonWidth;
    } else {
      _draggablePositionLeft = (pageWidth - _buttonWidth) - _dockBoundary;
      _panelPositionLeft = pageWidth + _buttonWidth;
    }
    notifyListeners();
  }

  /// Helper to calculate the dock boundary based on [DockType].
  double get _dockBoundary {
    return (dockType == DockType.inside) ? -dockOffset : dockOffset;
  }

  /// Hide the panel completely off-screen.
  ///
  /// - [pageWidth]: The width of the page/screen.
  void hidePanel(double pageWidth) {
    _panelPositionLeft = _draggablePositionLeft > pageWidth / 2
        ? pageWidth + _panelWidth
        : -_panelWidth;
    notifyListeners();
  }

  /// Toggle the panel's position between open and closed.
  ///
  /// - [pageWidth]: The width of the page/screen.
  void togglePanel(double pageWidth) {
    if (_panelState == PanelState.open) {
      _panelPositionLeft = _draggablePositionLeft > pageWidth / 2
          ? pageWidth - _panelWidth - buttonWidth
          : buttonWidth;
    } else {
      _panelPositionLeft =
          _draggablePositionLeft > pageWidth / 2 ? pageWidth : -_panelWidth;
    }
    notifyListeners();
  }

  /// Asynchronously toggle the main button state and update the panel's docked position.
  ///
  /// - [pageWidth]: The width of the page/screen.
  Future<void> toggleMainButton(double pageWidth) async {
    if (_panelState == PanelState.open) {
      _panelState = PanelState.closed;
      forceDock(pageWidth);
    } else {
      _panelState = PanelState.open;
      _draggablePositionLeft = _draggablePositionLeft > pageWidth / 2
          ? pageWidth + _buttonWidth
          : -_buttonWidth;
    }
    notifyListeners();
  }

  /// Toggle the panel's behavior based on its initial state.
  ///
  /// - [context]: The current [BuildContext].
  void toggle(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (initialPanelState == PanelState.open) {
      toggleMainButton(width);
      togglePanel(width);
    } else {
      _isDragging = false;
      forceDock(width);
      hidePanel(width);
    }
    notifyListeners();
  }

  /// Copy the current controller state.
  /// Used to create a new instance of the controller.
  DraggablePanelController copy() {
    return DraggablePanelController(
      initialPosition: (x: _draggablePositionLeft, y: _draggablePositionTop),
      initialPanelState: _panelState,
      panelAnimDuration: panelAnimDuration,
      dockType: dockType,
      dockOffset: dockOffset,
      dockAnimDuration: dockAnimDuration,
    );
  }
}
