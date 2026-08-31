/// A floating panel window that can be dragged, parked and grown in place.
library;

export 'src/controller/draggable_panel_controller.dart';
export 'src/core/draggable_panel.dart';
export 'src/core/draggable_panel_scope.dart';
export 'src/core/panel_edge_handle.dart';
export 'src/core/panel_semantics.dart';
export 'src/model/panel_behavior.dart';
export 'src/model/panel_corner.dart';
export 'src/model/panel_edge.dart';
export 'src/model/panel_extent.dart';
export 'src/model/panel_phase.dart';
export 'src/model/panel_placement.dart';
export 'src/model/panel_status.dart';
export 'src/model/panel_viewport.dart';
export 'src/motion/panel_motion_spec.dart' show PanelMotionSpec;
export 'src/presets/action_panel/action_grid.dart'
    show
        ActionButtonRow,
        ActionCell,
        ActionPanelContent,
        ActionPanelHeader,
        PanelActionBuilder,
        PanelActionButtonBuilder;
export 'src/presets/action_panel/action_panel_theme_data.dart';
export 'src/presets/action_panel/draggable_action_panel.dart';
export 'src/presets/action_panel/panel_action.dart';
export 'src/theme/draggable_panel_theme_data.dart';
