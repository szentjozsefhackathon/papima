import 'package:PapIma/database/DatabaseHelper.dart';
import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  late ThemeMode _themeMode = ThemeMode.system;

  @override
  ThemeProvider() {
    DatabaseHelper().database.then((db) async {
      final result = await db.query('settings', where: 'key = ?', whereArgs: ['theme']);
      switch (result.first['value']) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'system':
        default:
          _themeMode = ThemeMode.system;
          break;
      }
      notifyListeners();

    });
  }

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    DatabaseHelper().saveSetting('theme', mode.toString().split('.').last);
    _themeMode = mode;
    notifyListeners();
  }
}
