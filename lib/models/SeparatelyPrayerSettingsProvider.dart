import 'package:PapIma/database/DatabaseHelper.dart';
import 'package:flutter/material.dart';

class SeparatelyPrayerSettingsProvider extends ChangeNotifier {

  Map<String, dynamic> _prayer = {
    'enabled': false,
    'priest': null,
    'seminarist': null,
    'deacon': null,
    'bishop': null
  };
  @override
  SeparatelyPrayerSettingsProvider() {
    DatabaseHelper().database.then((db) async {
      var result = await db.query('settings', where: 'key = ?', whereArgs: ['separatelyPrayerPrayerEnabled']);
      if (result.isNotEmpty) {
        _prayer['enabled'] = result.first['value'] == '1';
      }
      List<String> orders = ['priest', 'seminarist', 'deacon', 'bishop'];
      for (var order in orders) {
        result = await db.query('settings', where: 'key = ?', whereArgs: ['separatelyPrayerPrayer${order[0].toUpperCase()}${order.substring(1)}']);
        if (result.isNotEmpty) {
          _prayer[order] = result.first['value'];
        }
      }
      notifyListeners();
    });
  }

  Map<String, dynamic> get prayer => _prayer;

  void setPrayer(Map<String, dynamic> prayer) async {
    List<String> orders = ['priest', 'seminarist', 'deacon', 'bishop'];
    if (!prayer.containsKey('enabled') || prayer.length != orders.length + 1 || !orders.every((element) => prayer.containsKey(element) && (prayer[element] == null || prayer[element] is int))) {
      throw Exception('Invalid prayer object');
    }


    DatabaseHelper().saveSetting('separatelyPrayerPrayerEnabled', prayer['enabled'] ? '1' : '0');
    for (var order in orders) {
      if (prayer[order] == null) {
        prayer[order] = (await DatabaseHelper().prayers)[0]['id'];
      }

      DatabaseHelper().saveSetting('separatelyPrayerPrayer${order[0].toUpperCase()}${order.substring(1)}', prayer[order]?.toString() ?? '');
    }
    _prayer = prayer;
    notifyListeners();
  }

}
