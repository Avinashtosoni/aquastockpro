import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode state notifier
class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const String _themeKey = 'theme_mode';
  final SharedPreferences? _prefs;

  ThemeNotifier(this._prefs) : super(_loadTheme(_prefs));

  static ThemeMode _loadTheme(SharedPreferences? prefs) {
    final themeString = prefs?.getString(_themeKey);
    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Set the theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs?.setString(_themeKey, mode.name);
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    if (state == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }

  /// Check if current mode is dark
  bool get isDarkMode => state == ThemeMode.dark;
  
  /// Check if using system theme
  bool get isSystemTheme => state == ThemeMode.system;
}

/// Provider for SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

/// Theme mode provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});

/// Convenience provider to check if dark mode
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeProvider);
  return themeMode == ThemeMode.dark;
});
