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
    this.actionSpacing,
    this.actionShape,
    this.actionBackgroundColor,
    this.actionForegroundColor,
    this.badgeColor,
    this.buttonSpacing,
    this.sectionSpacing,
    this.maxColumns,
    this.buttonLabelStyle,
  });

  /// Built-in tokens, derived from [scheme].
  factory DraggableActionPanelThemeData.defaults(ColorScheme scheme) =>
      DraggableActionPanelThemeData(
        contentPadding: const EdgeInsets.all(12),
        actionSize: 48,
        actionSpacing: 8,
        actionShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        actionBackgroundColor: scheme.secondaryContainer,
        actionForegroundColor: scheme.onSecondaryContainer,
        badgeColor: scheme.error,
        buttonSpacing: 8,
        sectionSpacing: 12,
        maxColumns: 4,
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
  final double? actionSpacing;
  final ShapeBorder? actionShape;
  final Color? actionBackgroundColor;
  final Color? actionForegroundColor;
  final Color? badgeColor;
  final double? buttonSpacing;

  /// Gap between the action grid and the button column.
  final double? sectionSpacing;

  /// Upper bound on grid columns before actions wrap onto another row.
  final int? maxColumns;

  final TextStyle? buttonLabelStyle;

  DraggableActionPanelThemeData merge(DraggableActionPanelThemeData? other) =>
      other == null
      ? this
      : copyWith(
          contentPadding: other.contentPadding,
          actionSize: other.actionSize,
          actionSpacing: other.actionSpacing,
          actionShape: other.actionShape,
          actionBackgroundColor: other.actionBackgroundColor,
          actionForegroundColor: other.actionForegroundColor,
          badgeColor: other.badgeColor,
          buttonSpacing: other.buttonSpacing,
          sectionSpacing: other.sectionSpacing,
          maxColumns: other.maxColumns,
          buttonLabelStyle: other.buttonLabelStyle,
        );

  @override
  DraggableActionPanelThemeData copyWith({
    EdgeInsetsGeometry? contentPadding,
    double? actionSize,
    double? actionSpacing,
    ShapeBorder? actionShape,
    Color? actionBackgroundColor,
    Color? actionForegroundColor,
    Color? badgeColor,
    double? buttonSpacing,
    double? sectionSpacing,
    int? maxColumns,
    TextStyle? buttonLabelStyle,
  }) => DraggableActionPanelThemeData(
    contentPadding: contentPadding ?? this.contentPadding,
    actionSize: actionSize ?? this.actionSize,
    actionSpacing: actionSpacing ?? this.actionSpacing,
    actionShape: actionShape ?? this.actionShape,
    actionBackgroundColor: actionBackgroundColor ?? this.actionBackgroundColor,
    actionForegroundColor: actionForegroundColor ?? this.actionForegroundColor,
    badgeColor: badgeColor ?? this.badgeColor,
    buttonSpacing: buttonSpacing ?? this.buttonSpacing,
    sectionSpacing: sectionSpacing ?? this.sectionSpacing,
    maxColumns: maxColumns ?? this.maxColumns,
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
      buttonSpacing: lerpDouble(buttonSpacing, other.buttonSpacing, t),
      sectionSpacing: lerpDouble(sectionSpacing, other.sectionSpacing, t),
      maxColumns: t < 0.5 ? maxColumns : other.maxColumns,
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
          other.actionSpacing == actionSpacing &&
          other.actionShape == actionShape &&
          other.actionBackgroundColor == actionBackgroundColor &&
          other.actionForegroundColor == actionForegroundColor &&
          other.badgeColor == badgeColor &&
          other.buttonSpacing == buttonSpacing &&
          other.sectionSpacing == sectionSpacing &&
          other.maxColumns == maxColumns &&
          other.buttonLabelStyle == buttonLabelStyle;

  @override
  int get hashCode => Object.hash(
    contentPadding,
    actionSize,
    actionSpacing,
    actionShape,
    actionBackgroundColor,
    actionForegroundColor,
    badgeColor,
    buttonSpacing,
    sectionSpacing,
    maxColumns,
    buttonLabelStyle,
  );
}
