import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: Color(0xFF2DE2E6),
      secondary: Color(0xFF7D3CF8),
      surface: Colors.black,
      onSurface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.black,
      cardColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white70)),
    );
  }

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: Color(0xFF0EA5A8),
      secondary: Color(0xFF6D28D9),
      surface: Colors.white,
      onSurface: Color(0xFF0F172A),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Color(0xFF0F172A),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Color(0xFF334155)),
      ),
    );
  }
}
