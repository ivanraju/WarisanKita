import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeViewModel extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeViewModel() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('is_dark_mode') ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    } catch (_) {}
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_dark_mode', isDark);
    } catch (_) {}
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF004D40),
        primary: const Color(0xFF004D40),
        secondary: const Color(0xFFFF7043),
        tertiary: const Color(0xFFFFD54F),
        surface: const Color(0xFFFFFFFF),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        labelStyle: const TextStyle(color: Color(0xFF475569)),
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIconColor: const Color(0xFF004D40),
        suffixIconColor: const Color(0xFF004D40),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF34D399),
        primary: const Color(0xFF34D399),
        secondary: const Color(0xFFFFD54F),
        tertiary: const Color(0xFFFFD54F),
        surface: const Color(0xFF0D2825),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF041412), // Deep Heritage Emerald Midnight
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: const Color(0xFF0D2825),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF041412),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIconColor: const Color(0xFFFFD54F),
        suffixIconColor: const Color(0xFFFFD54F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1E3A34)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1E3A34)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFFD54F), width: 1.8),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF0D2825),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF041412),
        foregroundColor: Color(0xFFFFD54F),
        elevation: 0,
      ),
    );
  }
}
