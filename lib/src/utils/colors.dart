import 'package:flutter/material.dart';

Color adjustColorBrightness(Color color, double brightness) {
  assert(
    brightness >= 0.0 && brightness <= 1.0,
    'Brightness must be between 0.0 and 1.0',
  );
  return Color.lerp(
        Colors.white,
        color,
        brightness,
      ) ??
      color;
}

Color adjustColorDarken(Color color, double darken) {
  assert(
    darken >= 0.0 && darken <= 1.0,
    'Darken must be between 0.0 and 1.0',
  );
  return Color.lerp(
        color,
        Colors.black,
        darken,
      ) ??
      color;
}

Color adjustColor({
  required Color color,
  required double value,
  required bool isDark,
}) =>
    isDark
        ? adjustColorDarken(color, value)
        : adjustColorBrightness(color, value);
