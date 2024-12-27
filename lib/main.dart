import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/BackButtonProvider.dart';
import 'models/DailyGoalProvider.dart';
import 'models/SystemBarProvider.dart';
import 'models/ThemeProvider.dart';
import 'pages/home/HomePage.dart';

void main() {
    runApp(
    MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => SystemBarProvider()),
      ChangeNotifierProvider(create: (_) => DailyGoalProvider()),
      ChangeNotifierProvider(create: (_) => BackButtonProvider())
    ],
    child: PapImaApp())
  );
}


class PapImaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final systemBarProvider = Provider.of<SystemBarProvider>(context);

    SystemChrome.setEnabledSystemUIMode(systemBarProvider.fullScreen ? SystemUiMode.immersive : SystemUiMode.edgeToEdge);
    return MaterialApp(
      title: 'PapIma',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.themeMode,
      home: PapImaHomePage(),
    );
  }
}
