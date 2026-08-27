import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Tokens for the action-grid preset.
///
/// Deliberately separate from `DraggablePanelThemeData`: the core panel knows
/// nothing about grids or buttons, and keeping the two apart is what stops
/// preset concerns leaking into it.
@immutable
final class DraggableActionPanelThemeData
    extends ThemeExtension<DraggableActionPanelThemeData>
    with Diagnosticable {
  const DraggableActionPanelThemeData({
    this.contentPadding,
    this.actionSize,
    this.actionIconSize,
    this.actionSpacing,
    this.actionShape,
    this.actionBackgroundColor,
    this.actionForegroundColor,
    this.badgeColor,
    this.badgeSize,
    this.badgeDotSize,
    this.buttonSpacing,
    this.sectionSpacing,
    this.maxColumns,
    this.buttonStyle,
    this.buttonLabelStyle,
    this.actionLabelStyle,
    this.actionLabelSpacing,
    this.actionLabelMaxLines,
    this.actionLabelMaxWidth,
    this.headerStyle,
    this.headerSpacing,
  });

  /// Built-in tokens, derived from [scheme].
  factory DraggableActionPanelThemeData.defaults(ColorScheme scheme) =>
      DraggableActionPanelThemeData(
        contentPadding: const EdgeInsets.all(12),
        actionSize: 48,
        actionIconSize: 24,
        actionSpacing: 8,
        actionShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        badgeColor: scheme.error,
        badgeSize: 18,
        badgeDotSize: 10,
        buttonSpacing: 8,
        sectionSpacing: 12,
        maxColumns: 4,
        actionBackgroundColor: scheme.surfaceContainerLowest,
        actionForegroundColor: scheme.onSurfaceVariant,
        actionLabelSpacing: 6,
        actionLabelMaxLines: 2,
        headerSpacing: 12,
      );

  /// Resolves defaults, then the app-wide extension, then [override].
  factory DraggableActionPanelThemeData.resolve(
    BuildContext context,
    DraggableActionPanelThemeData? override,
  ) {
    final theme = Theme.of(context);
    return DraggableActionPanelThemeData.defaults(
      theme.colorScheme,
    ).merge(theme.extension<DraggableActionPanelThemeData>()).merge(override);
  }

  final EdgeInsetsGeometry? contentPadding;
  final double? actionSize;

  /// Size of the glyph inside an action's tile.
  ///
  /// Separate from [actionSize] because the tile is the tap target and has a
  /// floor of 48 logical pixels, while the glyph inside it is free.
  final double? actionIconSize;
  final double? actionSpacing;
  final ShapeBorder? actionShape;
  final Color? actionBackgroundColor;
  final Color? actionForegroundColor;
  final Color? badgeColor;

  /// Height of a badge carrying a label.
  final double? badgeSize;

  /// Diameter of a badge with no label.
  final double? badgeDotSize;

  final double? buttonSpacing;

  /// Gap between the action grid and the button column.
  final double? sectionSpacing;

  /// Upper bound on grid columns before actions wrap onto another row.
  final int? maxColumns;

  /// Style of the labelled buttons, including their shape.
  ///
  /// Scoped to the panel, so retuning them does not reach the app's other
  /// `FilledButton`s. Defaults to the ambient `FilledButtonThemeData`.
  final ButtonStyle? buttonStyle;

  final TextStyle? buttonLabelStyle;

  /// Style of the caption under each action. Defaults to `labelSmall`.
  final TextStyle? actionLabelStyle;

  /// Gap between an action's tile and its caption.
  final double? actionLabelSpacing;

  /// How many lines a caption may wrap onto before it is elided.
  final int? actionLabelMaxLines;

  /// Widest a caption may get before it wraps.
  ///
  /// This is what bounds a grid column, so one long label cannot stretch the
  /// whole panel. Defaults to twice [actionSize].
  final double? actionLabelMaxWidth;

  /// Style of the header title. Defaults to `titleSmall`.
  final TextStyle? headerStyle;

  /// Gap between the header and the content below it.
  final double? headerSpacing;

  DraggableActionPanelThemeData merge(DraggableActionPanelThemeData? other) =>
      other == null
      ? this
      : copyWith(
          contentPadding: other.contentPadding,
          actionSize: other.actionSize,
          actionIconSize: other.actionIconSize,
          actionSpacing: other.actionSpacing,
          actionShape: other.actionShape,
          actionBackgroundColor: other.actionBackgroundColor,
          actionForegroundColor: other.actionForegroundColor,
          badgeColor: other.badgeColor,
          badgeSize: other.badgeSize,
          badgeDotSize: other.badgeDotSize,
          buttonSpacing: other.buttonSpacing,
          sectionSpacing: other.sectionSpacing,
          maxColumns: other.maxColumns,
          actionLabelStyle: other.actionLabelStyle,
          actionLabelSpacing: other.actionLabelSpacing,
          actionLabelMaxLines: other.actionLabelMaxLines,
          actionLabelMaxWidth: other.actionLabelMaxWidth,
          headerStyle: other.headerStyle,
          headerSpacing: other.headerSpacing,
          buttonStyle: other.buttonStyle,
          buttonLabelStyle: other.buttonLabelStyle,
        );

  @override
  DraggableActionPanelThemeData copyWith({
    EdgeInsetsGeometry? contentPadding,
    double? actionSize,
    double? actionIconSize,
    double? actionSpacing,
    ShapeBorder? actionShape,
    Color? actionBackgroundColor,
    Color? actionForegroundColor,
    Color? badgeColor,
    double? badgeSize,
    double? badgeDotSize,
    double? buttonSpacing,
    double? sectionSpacing,
    int? maxColumns,
    TextStyle? actionLabelStyle,
    double? actionLabelSpacing,
    int? actionLabelMaxLines,
    double? actionLabelMaxWidth,
    TextStyle? headerStyle,
    double? headerSpacing,
    ButtonStyle? buttonStyle,
    TextStyle? buttonLabelStyle,
  }) => DraggableActionPanelThemeData(
    contentPadding: contentPadding ?? this.contentPadding,
    actionSize: actionSize ?? this.actionSize,
    actionIconSize: actionIconSize ?? this.actionIconSize,
    actionSpacing: actionSpacing ?? this.actionSpacing,
    actionShape: actionShape ?? this.actionShape,
    actionBackgroundColor: actionBackgroundColor ?? this.actionBackgroundColor,
    actionForegroundColor: actionForegroundColor ?? this.actionForegroundColor,
    badgeColor: badgeColor ?? this.badgeColor,
    badgeSize: badgeSize ?? this.badgeSize,
    badgeDotSize: badgeDotSize ?? this.badgeDotSize,
    buttonSpacing: buttonSpacing ?? this.buttonSpacing,
    sectionSpacing: sectionSpacing ?? this.sectionSpacing,
    maxColumns: maxColumns ?? this.maxColumns,
    actionLabelStyle: actionLabelStyle ?? this.actionLabelStyle,
    actionLabelSpacing: actionLabelSpacing ?? this.actionLabelSpacing,
    actionLabelMaxLines: actionLabelMaxLines ?? this.actionLabelMaxLines,
    actionLabelMaxWidth: actionLabelMaxWidth ?? this.actionLabelMaxWidth,
    headerStyle: headerStyle ?? this.headerStyle,
    headerSpacing: headerSpacing ?? this.headerSpacing,
    buttonStyle: buttonStyle ?? this.buttonStyle,
    buttonLabelStyle: buttonLabelStyle ?? this.buttonLabelStyle,
  );

  @override
  DraggableActionPanelThemeData lerp(
    DraggableActionPanelThemeData? other,
    double t,
  ) {
    if (other == null) return this;
    return DraggableActionPanelThemeData(
      contentPadding: EdgeInsetsGeometry.lerp(
        contentPadding,
        other.contentPadding,
        t,
      ),
      actionSize: lerpDouble(actionSize, other.actionSize, t),
      actionIconSize: lerpDouble(actionIconSize, other.actionIconSize, t),
      actionSpacing: lerpDouble(actionSpacing, other.actionSpacing, t),
      actionShape: ShapeBorder.lerp(actionShape, other.actionShape, t),
      actionBackgroundColor: Color.lerp(
        actionBackgroundColor,
        other.actionBackgroundColor,
        t,
      ),
      actionForegroundColor: Color.lerp(
        actionForegroundColor,
        other.actionForegroundColor,
        t,
      ),
      badgeColor: Color.lerp(badgeColor, other.badgeColor, t),
      badgeSize: lerpDouble(badgeSize, other.badgeSize, t),
      badgeDotSize: lerpDouble(badgeDotSize, other.badgeDotSize, t),
      buttonSpacing: lerpDouble(buttonSpacing, other.buttonSpacing, t),
      sectionSpacing: lerpDouble(sectionSpacing, other.sectionSpacing, t),
      maxColumns: t < 0.5 ? maxColumns : other.maxColumns,
      actionLabelStyle: TextStyle.lerp(
        actionLabelStyle,
        other.actionLabelStyle,
        t,
      ),
      actionLabelSpacing: lerpDouble(
        actionLabelSpacing,
        other.actionLabelSpacing,
        t,
      ),
      actionLabelMaxLines: t < 0.5
          ? actionLabelMaxLines
          : other.actionLabelMaxLines,
      actionLabelMaxWidth: lerpDouble(
        actionLabelMaxWidth,
        other.actionLabelMaxWidth,
        t,
      ),
      headerStyle: TextStyle.lerp(headerStyle, other.headerStyle, t),
      headerSpacing: lerpDouble(headerSpacing, other.headerSpacing, t),
      buttonStyle: ButtonStyle.lerp(buttonStyle, other.buttonStyle, t),
      buttonLabelStyle: TextStyle.lerp(
        buttonLabelStyle,
        other.buttonLabelStyle,
        t,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DraggableActionPanelThemeData &&
          other.contentPadding == contentPadding &&
          other.actionSize == actionSize &&
          other.actionIconSize == actionIconSize &&
          other.actionSpacing == actionSpacing &&
          other.actionShape == actionShape &&
          other.actionBackgroundColor == actionBackgroundColor &&
          other.actionForegroundColor == actionForegroundColor &&
          other.badgeColor == badgeColor &&
          other.badgeSize == badgeSize &&
          other.badgeDotSize == badgeDotSize &&
          other.buttonSpacing == buttonSpacing &&
          other.sectionSpacing == sectionSpacing &&
          other.maxColumns == maxColumns &&
          other.actionLabelStyle == actionLabelStyle &&
          other.actionLabelSpacing == actionLabelSpacing &&
          other.actionLabelMaxLines == actionLabelMaxLines &&
          other.actionLabelMaxWidth == actionLabelMaxWidth &&
          other.headerStyle == headerStyle &&
          other.headerSpacing == headerSpacing &&
          other.buttonStyle == buttonStyle &&
          other.buttonLabelStyle == buttonLabelStyle;

  @override
  int get hashCode => Object.hashAll([
    contentPadding,
    actionSize,
    actionIconSize,
    actionSpacing,
    actionShape,
    actionBackgroundColor,
    actionForegroundColor,
    badgeColor,
    badgeSize,
    badgeDotSize,
    buttonSpacing,
    sectionSpacing,
    maxColumns,
    actionLabelStyle,
    actionLabelSpacing,
    actionLabelMaxLines,
    actionLabelMaxWidth,
    headerStyle,
    headerSpacing,
    buttonStyle,
    buttonLabelStyle,
  ]);
}
