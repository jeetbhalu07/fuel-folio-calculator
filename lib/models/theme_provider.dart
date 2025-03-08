
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  final SharedPreferences prefs;
  ThemeMode _themeMode;
  
  ThemeProvider(this.prefs) : _themeMode = ThemeMode.system {
    _loadThemeMode();
  }
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  void _loadThemeMode() {
    final savedThemeMode = prefs.getString('themeMode');
    if (savedThemeMode != null) {
      _themeMode = savedThemeMode == 'dark' 
          ? ThemeMode.dark 
          : savedThemeMode == 'light' 
              ? ThemeMode.light 
              : ThemeMode.system;
      notifyListeners();
    }
  }
  
  void setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    
    String themeValue;
    switch (mode) {
      case ThemeMode.dark:
        themeValue = 'dark';
        break;
      case ThemeMode.light:
        themeValue = 'light';
        break;
      default:
        themeValue = 'system';
    }
    
    await prefs.setString('themeMode', themeValue);
    notifyListeners();
  }
  
  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }
}
