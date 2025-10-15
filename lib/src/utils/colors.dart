import 'package:flutter/material.dart';

/// Adjusts the brightness of a color by blending it with white.
///
/// - Parameters:
///   - color: The base color to adjust
///   - brightness: A value between 0.0 (black) and 1.0 (original color)
/// - Return: A brighter version of the input color
/// - Usage example:
///   ```dart
///   final lightBlue = adjustColorBrightness(Colors.blue, 0.8);
///   ```
/// - Edge case notes: Asserts that brightness is within valid range [0.0, 1.0]
Color adjustColorBrightness(Color color, double brightness) {
  assert(
    brightness >= 0.0 && brightness <= 1.0,
    'Brightness must be between 0.0 and 1.0',
  );
  return Color.lerp(Colors.white, color, brightness) ?? color;
}

/// Darkens a color by blending it with black.
///
/// - Parameters:
///   - color: The base color to adjust
///   - darken: A value between 0.0 (original color) and 1.0 (black)
/// - Return: A darker version of the input color
/// - Usage example:
///   ```dart
///   final darkBlue = adjustColorDarken(Colors.blue, 0.3);
///   ```
/// - Edge case notes: Asserts that darken is within valid range [0.0, 1.0]
Color adjustColorDarken(Color color, double darken) {
  assert(
    darken >= 0.0 && darken <= 1.0,
    'Darken must be between 0.0 and 1.0',
  );
  return Color.lerp(color, Colors.black, darken) ?? color;
}

/// Adjusts a color based on the current theme brightness.
///
/// - Parameters:
///   - color: The base color to adjust
///   - value: The adjustment value (0.0 to 1.0)
///   - isDark: Whether the current theme is dark
/// - Return: A color adjusted for the current theme
/// - Usage example:
///   ```dart
///   final adjustedColor = adjustColor(
///     color: Colors.blue,
///     value: 0.5,
///     isDark: Theme.of(context).brightness == Brightness.dark,
///   );
///   ```
Color adjustColor({
  required Color color,
  required double value,
  required bool isDark,
}) =>
    isDark
        ? adjustColorDarken(color, value)
        : adjustColorBrightness(color, value);
