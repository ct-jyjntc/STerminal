import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const _darkSurface = Color(0xFF1E1F25);
  static const _darkBackground = Color(0xFF17181D);

  static final _darkScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF4DD0E1),
    brightness: Brightness.dark,
  ).copyWith(
    primary: const Color(0xFF4DD0E1),
    secondary: const Color(0xFF00BCD4),
    surface: _darkSurface,
    error: const Color(0xFFFF5370),
  );

  static final _lightScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF00796B),
    brightness: Brightness.light,
  ).copyWith(
    surface: const Color(0xFFF7F9FB),
    secondary: const Color(0xFF00A8A0),
  );

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: _darkScheme,
      scaffoldBackgroundColor: _darkBackground,
      cardColor: const Color(0xFF242631),
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white.withAlpha((0.9 * 255).round()),
        displayColor: Colors.white,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF2C2F3C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: const Color(0xFF2F3240),
        labelStyle: const TextStyle(color: Colors.white),
      ),
    );
  }

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: _lightScheme,
      scaffoldBackgroundColor: const Color(0xFFF2F5F9),
      cardColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: _lightScheme.surface,
        foregroundColor: const Color(0xFF1F2A37),
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: const Color(0xFF1F2A37),
        displayColor: const Color(0xFF1F2A37),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: const Color(0xFFE3E8F0),
        labelStyle: const TextStyle(color: Color(0xFF1F2A37)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFF1F3F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
      ),
      dividerColor: Colors.black12,
    );
  }
}
