import 'package:draggable_panel/src/theme/draggable_panel_button_theme_data.dart';
import 'package:draggable_panel/src/theme/draggable_panel_handle_theme_data.dart';
import 'package:draggable_panel/src/theme/draggable_panel_item_theme_data.dart';
import 'package:draggable_panel/src/theme/draggable_panel_tooltip_theme_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Defines the visual properties of a [DraggablePanel].
///
/// Customize colors, sizes, and spacing at the panel level.
/// For fine-grained control over individual elements, use sub-themes:
/// [itemTheme], [buttonTheme], [tooltipTheme], [handleTheme].
@immutable
class DraggablePanelTheme {
  const DraggablePanelTheme({
    this.draggableButtonWidth = 35.0,
    this.draggableButtonHeight = 70.0,
    this.draggableButtonColor,
    this.panelWidth = 200.0,
    this.panelBackgroundColor,
    this.panelBorder,
    this.panelBorderRadius = const BorderRadius.all(Radius.circular(16)),
    this.panelBoxShadow,
    this.panelContentPadding = const EdgeInsets.all(8),
    this.panelItemColor,
    this.panelButtonColor,
    this.foregroundColor,
    this.itemSpacing = 8.0,
    this.buttonSpacing = 6.0,
    this.sectionSpacing = 8.0,
    this.itemTheme,
    this.buttonTheme,
    this.tooltipTheme,
    this.handleTheme,
  });

  // -- Draggable button --

  /// Width of the draggable button.
  final double draggableButtonWidth;

  /// Height of the draggable button.
  final double draggableButtonHeight;

  /// Background color of the draggable button.
  final Color? draggableButtonColor;

  // -- Panel --

  /// Width of the expanded panel.
  final double panelWidth;

  /// Background color of the panel.
  final Color? panelBackgroundColor;

  /// Border of the panel.
  final BoxBorder? panelBorder;

  /// Border radius of the panel.
  final BorderRadiusGeometry panelBorderRadius;

  /// Shadow of the panel.
  final List<BoxShadow>? panelBoxShadow;

  /// Padding inside the panel around its content.
  final EdgeInsets panelContentPadding;

  // -- Colors --

  /// Background color of item cells in the grid.
  final Color? panelItemColor;

  /// Background color of action buttons.
  final Color? panelButtonColor;

  /// Foreground color for icons and text.
  final Color? foregroundColor;

  // -- Layout spacing --

  /// Spacing between item cells (horizontal and vertical).
  final double itemSpacing;

  /// Spacing between action buttons.
  final double buttonSpacing;

  /// Spacing between the items section and the buttons section.
  final double sectionSpacing;

  // -- Sub-themes --

  /// Theme for item cells. Uses defaults when null.
  final DraggablePanelItemThemeData? itemTheme;

  /// Theme for action buttons. Uses defaults when null.
  final DraggablePanelButtonThemeData? buttonTheme;

  /// Theme for tooltip snackbars. Uses defaults when null.
  final DraggablePanelTooltipThemeData? tooltipTheme;

  /// Theme for the drag handle. Uses defaults when null.
  final DraggablePanelHandleThemeData? handleTheme;

  // -- Resolved sub-themes --

  DraggablePanelItemThemeData get effectiveItemTheme =>
      itemTheme ?? const DraggablePanelItemThemeData();

  DraggablePanelButtonThemeData get effectiveButtonTheme =>
      buttonTheme ?? const DraggablePanelButtonThemeData();

  DraggablePanelTooltipThemeData get effectiveTooltipTheme =>
      tooltipTheme ?? const DraggablePanelTooltipThemeData();

  DraggablePanelHandleThemeData get effectiveHandleTheme =>
      handleTheme ?? const DraggablePanelHandleThemeData();

  DraggablePanelTheme copyWith({
    double? draggableButtonWidth,
    double? draggableButtonHeight,
    Color? draggableButtonColor,
    double? panelWidth,
    Color? panelBackgroundColor,
    BoxBorder? panelBorder,
    BorderRadiusGeometry? panelBorderRadius,
    List<BoxShadow>? panelBoxShadow,
    EdgeInsets? panelContentPadding,
    Color? panelItemColor,
    Color? panelButtonColor,
    Color? foregroundColor,
    double? itemSpacing,
    double? buttonSpacing,
    double? sectionSpacing,
    DraggablePanelItemThemeData? itemTheme,
    DraggablePanelButtonThemeData? buttonTheme,
    DraggablePanelTooltipThemeData? tooltipTheme,
    DraggablePanelHandleThemeData? handleTheme,
  }) =>
      DraggablePanelTheme(
        draggableButtonWidth:
            draggableButtonWidth ?? this.draggableButtonWidth,
        draggableButtonHeight:
            draggableButtonHeight ?? this.draggableButtonHeight,
        draggableButtonColor:
            draggableButtonColor ?? this.draggableButtonColor,
        panelWidth: panelWidth ?? this.panelWidth,
        panelBackgroundColor:
            panelBackgroundColor ?? this.panelBackgroundColor,
        panelBorder: panelBorder ?? this.panelBorder,
        panelBorderRadius: panelBorderRadius ?? this.panelBorderRadius,
        panelBoxShadow: panelBoxShadow ?? this.panelBoxShadow,
        panelContentPadding: panelContentPadding ?? this.panelContentPadding,
        panelItemColor: panelItemColor ?? this.panelItemColor,
        panelButtonColor: panelButtonColor ?? this.panelButtonColor,
        foregroundColor: foregroundColor ?? this.foregroundColor,
        itemSpacing: itemSpacing ?? this.itemSpacing,
        buttonSpacing: buttonSpacing ?? this.buttonSpacing,
        sectionSpacing: sectionSpacing ?? this.sectionSpacing,
        itemTheme: itemTheme ?? this.itemTheme,
        buttonTheme: buttonTheme ?? this.buttonTheme,
        tooltipTheme: tooltipTheme ?? this.tooltipTheme,
        handleTheme: handleTheme ?? this.handleTheme,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DraggablePanelTheme &&
        other.draggableButtonWidth == draggableButtonWidth &&
        other.draggableButtonHeight == draggableButtonHeight &&
        other.draggableButtonColor == draggableButtonColor &&
        other.panelWidth == panelWidth &&
        other.panelBackgroundColor == panelBackgroundColor &&
        other.panelBorder == panelBorder &&
        other.panelBorderRadius == panelBorderRadius &&
        listEquals(other.panelBoxShadow, panelBoxShadow) &&
        other.panelContentPadding == panelContentPadding &&
        other.panelItemColor == panelItemColor &&
        other.panelButtonColor == panelButtonColor &&
        other.foregroundColor == foregroundColor &&
        other.itemSpacing == itemSpacing &&
        other.buttonSpacing == buttonSpacing &&
        other.sectionSpacing == sectionSpacing &&
        other.itemTheme == itemTheme &&
        other.buttonTheme == buttonTheme &&
        other.tooltipTheme == tooltipTheme &&
        other.handleTheme == handleTheme;
  }

  @override
  int get hashCode =>
      draggableButtonWidth.hashCode ^
      draggableButtonHeight.hashCode ^
      draggableButtonColor.hashCode ^
      panelWidth.hashCode ^
      panelBackgroundColor.hashCode ^
      panelBorder.hashCode ^
      panelBorderRadius.hashCode ^
      panelBoxShadow.hashCode ^
      panelContentPadding.hashCode ^
      panelItemColor.hashCode ^
      panelButtonColor.hashCode ^
      foregroundColor.hashCode ^
      itemSpacing.hashCode ^
      buttonSpacing.hashCode ^
      sectionSpacing.hashCode ^
      itemTheme.hashCode ^
      buttonTheme.hashCode ^
      tooltipTheme.hashCode ^
      handleTheme.hashCode;
}
