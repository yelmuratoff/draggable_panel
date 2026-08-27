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
    this.collapsedIconSize,
    this.collapsedIconColor,
    this.actionSize,
    this.actionIconSize,
    this.actionSpacing,
    this.actionShape,
    this.actionBackgroundColor,
    this.actionForegroundColor,
    this.actionOverlayColor,
    this.badgeColor,
    this.badgeSize,
    this.badgeDotSize,
    this.badgeTextStyle,
    this.badgeForegroundColor,
    this.badgeOffset,
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
    this.closeIcon,
    this.closeButtonStyle,
  });

  /// Built-in tokens, derived from [scheme].
  factory DraggableActionPanelThemeData.defaults(ColorScheme scheme) =>
      DraggableActionPanelThemeData(
        contentPadding: const EdgeInsets.all(12),
        collapsedIconSize: 24,
        collapsedIconColor: scheme.onSurface,
        actionSize: 48,
        actionIconSize: 24,
        actionSpacing: 8,
        actionShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        badgeColor: scheme.error,
        badgeSize: 18,
        badgeDotSize: 10,
        badgeOffset: Offset.zero,
        buttonSpacing: 8,
        sectionSpacing: 12,
        maxColumns: 4,
        actionBackgroundColor: scheme.surfaceContainerLowest,
        actionForegroundColor: scheme.onSurfaceVariant,
        actionLabelSpacing: 6,
        actionLabelMaxLines: 2,
        headerSpacing: 12,
        closeIcon: Icons.close_rounded,
        closeButtonStyle: IconButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          iconSize: 20,
          visualDensity: VisualDensity.compact,
        ),
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

  /// Size of the glyph on the collapsed face.
  final double? collapsedIconSize;

  /// Colour of that glyph.
  final Color? collapsedIconColor;

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

  /// Ink drawn over a tile as it is pressed, hovered, or focused.
  final WidgetStateProperty<Color?>? actionOverlayColor;

  final Color? badgeColor;

  /// Height of a badge carrying a label.
  final double? badgeSize;

  /// Diameter of a badge with no label.
  final double? badgeDotSize;

  /// Style of a badge's label. Defaults to Material's own badge text style.
  ///
  /// Material resolves a badge's text colour separately, so a colour set here
  /// only lands through [badgeForegroundColor].
  final TextStyle? badgeTextStyle;

  /// Colour of a badge's label. Defaults to `onError`, matching [badgeColor].
  final Color? badgeForegroundColor;

  /// Shifts a badge in from the top-end corner of its tile.
  ///
  /// `dx` insets it from the end edge and `dy` from the top; negative values
  /// hang it over the corner. A round [actionShape] usually wants a few pixels
  /// here, since the corner it hugs is empty.
  final Offset? badgeOffset;

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

  /// Glyph on the header's close control.
  final IconData? closeIcon;

  /// Style of that control, including its shape, size, and colours.
  final ButtonStyle? closeButtonStyle;

  DraggableActionPanelThemeData merge(DraggableActionPanelThemeData? other) =>
      other == null
      ? this
      : copyWith(
          contentPadding: other.contentPadding,
          collapsedIconSize: other.collapsedIconSize,
          collapsedIconColor: other.collapsedIconColor,
          actionSize: other.actionSize,
          actionIconSize: other.actionIconSize,
          actionSpacing: other.actionSpacing,
          actionShape: other.actionShape,
          actionBackgroundColor: other.actionBackgroundColor,
          actionForegroundColor: other.actionForegroundColor,
          actionOverlayColor: other.actionOverlayColor,
          badgeColor: other.badgeColor,
          badgeSize: other.badgeSize,
          badgeDotSize: other.badgeDotSize,
          badgeTextStyle: other.badgeTextStyle,
          badgeForegroundColor: other.badgeForegroundColor,
          badgeOffset: other.badgeOffset,
          buttonSpacing: other.buttonSpacing,
          sectionSpacing: other.sectionSpacing,
          maxColumns: other.maxColumns,
          actionLabelStyle: other.actionLabelStyle,
          actionLabelSpacing: other.actionLabelSpacing,
          actionLabelMaxLines: other.actionLabelMaxLines,
          actionLabelMaxWidth: other.actionLabelMaxWidth,
          headerStyle: other.headerStyle,
          headerSpacing: other.headerSpacing,
          closeIcon: other.closeIcon,
          closeButtonStyle: other.closeButtonStyle,
          buttonStyle: other.buttonStyle,
          buttonLabelStyle: other.buttonLabelStyle,
        );

  @override
  DraggableActionPanelThemeData copyWith({
    EdgeInsetsGeometry? contentPadding,
    double? collapsedIconSize,
    Color? collapsedIconColor,
    double? actionSize,
    double? actionIconSize,
    double? actionSpacing,
    ShapeBorder? actionShape,
    Color? actionBackgroundColor,
    Color? actionForegroundColor,
    WidgetStateProperty<Color?>? actionOverlayColor,
    Color? badgeColor,
    double? badgeSize,
    double? badgeDotSize,
    TextStyle? badgeTextStyle,
    Color? badgeForegroundColor,
    Offset? badgeOffset,
    double? buttonSpacing,
    double? sectionSpacing,
    int? maxColumns,
    TextStyle? actionLabelStyle,
    double? actionLabelSpacing,
    int? actionLabelMaxLines,
    double? actionLabelMaxWidth,
    TextStyle? headerStyle,
    double? headerSpacing,
    IconData? closeIcon,
    ButtonStyle? closeButtonStyle,
    ButtonStyle? buttonStyle,
    TextStyle? buttonLabelStyle,
  }) => DraggableActionPanelThemeData(
    contentPadding: contentPadding ?? this.contentPadding,
    collapsedIconSize: collapsedIconSize ?? this.collapsedIconSize,
    collapsedIconColor: collapsedIconColor ?? this.collapsedIconColor,
    actionSize: actionSize ?? this.actionSize,
    actionIconSize: actionIconSize ?? this.actionIconSize,
    actionSpacing: actionSpacing ?? this.actionSpacing,
    actionShape: actionShape ?? this.actionShape,
    actionBackgroundColor: actionBackgroundColor ?? this.actionBackgroundColor,
    actionForegroundColor: actionForegroundColor ?? this.actionForegroundColor,
    actionOverlayColor: actionOverlayColor ?? this.actionOverlayColor,
    badgeColor: badgeColor ?? this.badgeColor,
    badgeSize: badgeSize ?? this.badgeSize,
    badgeDotSize: badgeDotSize ?? this.badgeDotSize,
    badgeTextStyle: badgeTextStyle ?? this.badgeTextStyle,
    badgeForegroundColor: badgeForegroundColor ?? this.badgeForegroundColor,
    badgeOffset: badgeOffset ?? this.badgeOffset,
    buttonSpacing: buttonSpacing ?? this.buttonSpacing,
    sectionSpacing: sectionSpacing ?? this.sectionSpacing,
    maxColumns: maxColumns ?? this.maxColumns,
    actionLabelStyle: actionLabelStyle ?? this.actionLabelStyle,
    actionLabelSpacing: actionLabelSpacing ?? this.actionLabelSpacing,
    actionLabelMaxLines: actionLabelMaxLines ?? this.actionLabelMaxLines,
    actionLabelMaxWidth: actionLabelMaxWidth ?? this.actionLabelMaxWidth,
    headerStyle: headerStyle ?? this.headerStyle,
    headerSpacing: headerSpacing ?? this.headerSpacing,
    closeIcon: closeIcon ?? this.closeIcon,
    closeButtonStyle: closeButtonStyle ?? this.closeButtonStyle,
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
      collapsedIconSize: lerpDouble(
        collapsedIconSize,
        other.collapsedIconSize,
        t,
      ),
      collapsedIconColor: Color.lerp(
        collapsedIconColor,
        other.collapsedIconColor,
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
      actionOverlayColor: t < 0.5
          ? actionOverlayColor
          : other.actionOverlayColor,
      badgeColor: Color.lerp(badgeColor, other.badgeColor, t),
      badgeSize: lerpDouble(badgeSize, other.badgeSize, t),
      badgeDotSize: lerpDouble(badgeDotSize, other.badgeDotSize, t),
      badgeTextStyle: TextStyle.lerp(badgeTextStyle, other.badgeTextStyle, t),
      badgeForegroundColor: Color.lerp(
        badgeForegroundColor,
        other.badgeForegroundColor,
        t,
      ),
      badgeOffset: Offset.lerp(badgeOffset, other.badgeOffset, t),
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
      closeIcon: t < 0.5 ? closeIcon : other.closeIcon,
      closeButtonStyle: ButtonStyle.lerp(
        closeButtonStyle,
        other.closeButtonStyle,
        t,
      ),
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
          other.collapsedIconSize == collapsedIconSize &&
          other.collapsedIconColor == collapsedIconColor &&
          other.actionSize == actionSize &&
          other.actionIconSize == actionIconSize &&
          other.actionSpacing == actionSpacing &&
          other.actionShape == actionShape &&
          other.actionBackgroundColor == actionBackgroundColor &&
          other.actionForegroundColor == actionForegroundColor &&
          other.actionOverlayColor == actionOverlayColor &&
          other.badgeColor == badgeColor &&
          other.badgeSize == badgeSize &&
          other.badgeDotSize == badgeDotSize &&
          other.badgeTextStyle == badgeTextStyle &&
          other.badgeForegroundColor == badgeForegroundColor &&
          other.badgeOffset == badgeOffset &&
          other.buttonSpacing == buttonSpacing &&
          other.sectionSpacing == sectionSpacing &&
          other.maxColumns == maxColumns &&
          other.actionLabelStyle == actionLabelStyle &&
          other.actionLabelSpacing == actionLabelSpacing &&
          other.actionLabelMaxLines == actionLabelMaxLines &&
          other.actionLabelMaxWidth == actionLabelMaxWidth &&
          other.headerStyle == headerStyle &&
          other.headerSpacing == headerSpacing &&
          other.closeIcon == closeIcon &&
          other.closeButtonStyle == closeButtonStyle &&
          other.buttonStyle == buttonStyle &&
          other.buttonLabelStyle == buttonLabelStyle;

  @override
  int get hashCode => Object.hashAll([
    contentPadding,
    collapsedIconSize,
    collapsedIconColor,
    actionSize,
    actionIconSize,
    actionSpacing,
    actionShape,
    actionBackgroundColor,
    actionForegroundColor,
    actionOverlayColor,
    badgeColor,
    badgeSize,
    badgeDotSize,
    badgeTextStyle,
    badgeForegroundColor,
    badgeOffset,
    buttonSpacing,
    sectionSpacing,
    maxColumns,
    actionLabelStyle,
    actionLabelSpacing,
    actionLabelMaxLines,
    actionLabelMaxWidth,
    headerStyle,
    headerSpacing,
    closeIcon,
    closeButtonStyle,
    buttonStyle,
    buttonLabelStyle,
  ]);
}
