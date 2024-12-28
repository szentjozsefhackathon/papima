import 'package:PapIma/database/DatabaseHelper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BackButtonProvider extends ChangeNotifier {
  bool _backButton = false;
  @override
  BackButtonProvider() {
    DatabaseHelper().database.then((db) async {
      final result = await db.query('settings', where: 'key = ?', whereArgs: ['backButton']);
      _backButton = result.isNotEmpty ? result.first['value'] == '1' : false;
      SystemChrome.setEnabledSystemUIMode(_backButton ? SystemUiMode.immersive : SystemUiMode.edgeToEdge);

      notifyListeners();

    });
  }

  bool get backButton => _backButton;

  void setBackButton(bool backButton) {
    DatabaseHelper().saveSetting('backButton', backButton ? '1' : '0');

    _backButton = backButton;
    notifyListeners();
  }
}
