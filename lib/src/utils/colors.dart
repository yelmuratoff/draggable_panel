import 'package:flutter/material.dart';

/// Adjusts the brightness of a color by blending it with white.
///
/// - [color]: The base color to adjust.
/// - [brightness]: A value between 0.0 (black) and 1.0 (original color).
///
/// Returns a brighter version of the input color.
Color adjustColorBrightness(Color color, double brightness) {
  assert(
    brightness >= 0.0 && brightness <= 1.0,
    'Brightness must be between 0.0 and 1.0',
  );
  return Color.lerp(Colors.white, color, brightness) ?? color;
}

/// Darkens a color by blending it with black.
///
/// - [color]: The base color to adjust.
/// - [darken]: A value between 0.0 (original color) and 1.0 (black).
///
/// Returns a darker version of the input color.
Color adjustColorDarken(Color color, double darken) {
  assert(
    darken >= 0.0 && darken <= 1.0,
    'Darken must be between 0.0 and 1.0',
  );
  return Color.lerp(color, Colors.black, darken) ?? color;
}

/// Adjusts a color based on the current theme brightness.
///
/// - [color]: The base color to adjust.
/// - [value]: The adjustment value (0.0 to 1.0).
/// - [isDark]: Whether the current theme is dark.
///
/// Returns a color adjusted for the current theme.
Color adjustColor({
  required Color color,
  required double value,
  required bool isDark,
}) =>
    isDark
        ? adjustColorDarken(color, value)
        : adjustColorBrightness(color, value);
