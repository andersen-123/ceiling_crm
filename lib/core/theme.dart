import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1E88E5); // синий
  static const Color accent = Color(0xFF43A047); // зелёный

  static final ThemeData lightTheme = ThemeData(
    primaryColor: primary,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: accent,
    ),
    brightness: Brightness.light,
  );

  static final ThemeData darkTheme = ThemeData(
    primaryColor: primary,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: accent,
    ),
    brightness: Brightness.dark,
  );
}
