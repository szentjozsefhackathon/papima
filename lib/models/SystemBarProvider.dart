import 'package:PapIma/database/DatabaseHelper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemBarProvider extends ChangeNotifier {
  bool _fullScreen = true;
  @override
  SystemBarProvider() {
    DatabaseHelper().database.then((db) async {
      final result = await db.query('settings', where: 'key = ?', whereArgs: ['fullScreen']);
      if (result.isNotEmpty) _fullScreen = result.first['value'] == '1';
      print('fullScreen: $_fullScreen');
      SystemChrome.setEnabledSystemUIMode(_fullScreen ? SystemUiMode.immersive : SystemUiMode.edgeToEdge);

      notifyListeners();

    });
  }

  bool get fullScreen => _fullScreen;

  void setFullScreen(bool fullScreen) {
    DatabaseHelper().saveSetting('fullScreen', fullScreen ? '1' : '0');
    SystemChrome.setEnabledSystemUIMode(fullScreen ? SystemUiMode.immersive : SystemUiMode.edgeToEdge);

    _fullScreen = fullScreen;
    notifyListeners();
  }
}
