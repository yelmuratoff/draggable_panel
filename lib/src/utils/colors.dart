import 'package:flutter/material.dart';

Color adjustColorBrightness(Color color, double brightness) {
  assert(
    brightness >= 0.0 && brightness <= 1.0,
    'Brightness must be between 0.0 and 1.0',
  );

  // Interpolate each channel towards 1.0 (white) by the given brightness factor.
  final red = (color.r * brightness) + (1.0 - brightness);
  final green = (color.g * brightness) + (1.0 - brightness);
  final blue = (color.b * brightness) + (1.0 - brightness);

  return color.withValues(alpha: color.a, red: red, green: green, blue: blue);
}

Color adjustColorDarken(Color color, double darken) {
  assert(darken >= 0.0 && darken <= 1.0, 'Darken must be between 0.0 and 1.0');

  // Scale channels towards 0.0 (black) by the darken factor using normalized channels.
  final red = color.r * (1.0 - darken);
  final green = color.g * (1.0 - darken);
  final blue = color.b * (1.0 - darken);

  return color.withValues(alpha: color.a, red: red, green: green, blue: blue);
}

Color adjustColor({
  required Color color,
  required double value,
  required bool isDark,
}) {
  if (isDark) {
    return adjustColorDarken(color, value);
  } else {
    return adjustColorBrightness(color, value);
  }
}
