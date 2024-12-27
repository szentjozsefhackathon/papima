import 'package:PapIma/database/DatabaseHelper.dart';
import 'package:flutter/material.dart';

class DailyGoalProvider extends ChangeNotifier {
  late bool _enabled = false;
  late int _dailyGoal = 100;

  @override
  DailyGoalProvider() {
    DatabaseHelper().database.then((db) async {
      var result = await db.query('settings', where: 'key = ?', whereArgs: ['dailyGoal']);
      if (result.isNotEmpty) {
        _dailyGoal = int.parse(result.first['value'].toString());
      }
      result = await db.query('settings', where: 'key = ?', whereArgs: ['dailyGoalEnabled']);
      if (result.isNotEmpty) _enabled = result.first['value'] == '1';
      notifyListeners();
    });
  }

  int get dailyGoal => _dailyGoal;
  bool get enabled => _enabled;

  void setDailyGoal(int dailyGoal) {
    DatabaseHelper().saveSetting('dailyGoal', dailyGoal.toString());
    _dailyGoal = dailyGoal;
    notifyListeners();
  }

  void setEnabled(bool enabled) {
    DatabaseHelper().saveSetting('dailyGoalEnabled', enabled ? '1' : '0');
    _enabled = enabled;
    notifyListeners();
  }
}
