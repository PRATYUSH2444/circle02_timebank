import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF4F46E5),
      secondary: Color(0xFF22D3EE),
    ),
    scaffoldBackgroundColor: const Color(0xFF0F172A),
  );
}