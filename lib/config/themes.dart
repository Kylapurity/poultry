import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF5E4935);
  static const Color accentColor = Color(0xFF8BAF7C);
  static const Color backgroundColor = Colors.white;
  static const Color textDarkColor = Color(0xFF3A3A3A);
  static const Color textLightColor = Color(0xFF7A7A7A);

  static ThemeData themeData = ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
    ),
    fontFamily: 'Lexend',
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textDarkColor, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: textDarkColor, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: textDarkColor, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: textDarkColor, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: textDarkColor, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: textDarkColor, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: textDarkColor),
      bodyMedium: TextStyle(color: textDarkColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}