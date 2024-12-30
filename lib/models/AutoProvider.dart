import 'package:PapIma/database/DatabaseHelper.dart';
import 'package:flutter/material.dart';

class AutoProvider extends ChangeNotifier {
  late bool _enabled = false;
  late int _seconds = 30;

  @override
  AutoProvider() {
    DatabaseHelper().database.then((db) async {
      var result = await db.query('settings', where: 'key = ?', whereArgs: ['autoPlaySeconds']);
      if (result.isNotEmpty) {
        _seconds = int.parse(result.first['value'].toString());
      }
      result = await db.query('settings', where: 'key = ?', whereArgs: ['autoPlayEnabled']);
      if (result.isNotEmpty) _enabled = result.first['value'] == '1';
      notifyListeners();
    });
  }

  int get seconds => _seconds;
  bool get enabled => _enabled;

  void setSeconds(int seconds) {
    DatabaseHelper().saveSetting('autoPlaySeconds', seconds.toString());
    _seconds = seconds;
    notifyListeners();
  }

  void setEnabled(bool enabled) {
    DatabaseHelper().saveSetting('autoPlayEnabled', enabled ? '1' : '0');
    _enabled = enabled;
    notifyListeners();
  }
}
