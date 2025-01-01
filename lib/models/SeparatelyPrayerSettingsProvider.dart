import 'package:PapIma/database/DatabaseHelper.dart';
import 'package:flutter/material.dart';

class SeparatelyPrayerSettingsProvider extends ChangeNotifier {

  Map<String, dynamic> _prayer = {
    'enabled': false,
    'id': null
  };
  @override
  SeparatelyPrayerSettingsProvider() {
    DatabaseHelper().database.then((db) async {
      var result = await db.query('settings', where: 'key = ?', whereArgs: ['separatelyPrayerPrayerEnabled']);
      if (result.isNotEmpty) {
        _prayer['enabled'] = result.first['value'] == '1';
      }
      result = await db.query('settings', where: 'key = ?', whereArgs: ['separatelyPrayerPrayerId']);
      if (result.isNotEmpty) {
        _prayer['id'] = result.first['value'];
      }
      notifyListeners();
    });
  }

  Map<String, dynamic> get prayer => _prayer;

  void setPrayer(Map<String, dynamic> prayer) async {
    if (!prayer.containsKey('enabled') || !prayer.containsKey('id') || prayer.length != 2) {
      throw Exception('Invalid prayer object');
    }


    DatabaseHelper().saveSetting('separatelyPrayerPrayerEnabled', prayer['enabled'] ? '1' : '0');
    if (prayer['id'] == null) {
      prayer['id'] = (await DatabaseHelper().prayers)[0]['id'];
    }
    DatabaseHelper().saveSetting('separatelyPrayerPrayerId', prayer['id'].toString());
    _prayer = prayer;
    notifyListeners();
  }

}
