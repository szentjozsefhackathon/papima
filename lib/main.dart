import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/AutoProvider.dart';
import 'models/BackButtonProvider.dart';
import 'models/DailyGoalProvider.dart';
import 'models/SeparatelyPrayerSettingsProvider.dart';
import 'models/SystemBarProvider.dart';
import 'models/ThemeProvider.dart';
import 'pages/separatelyPrayer/SeparatelyPrayer.dart';

void main() {
    runApp(
    MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => SystemBarProvider()),
      ChangeNotifierProvider(create: (_) => DailyGoalProvider()),
      ChangeNotifierProvider(create: (_) => BackButtonProvider()),
      ChangeNotifierProvider(create: (_) => AutoProvider()),
      ChangeNotifierProvider(create: (_) => SeparatelyPrayerSettingsProvider()),
    ],
    child: PapImaApp())
  );
}


class PapImaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'PapIma',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF2962FF), brightness: Brightness.light)),
      darkTheme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF2962FF), brightness: Brightness.dark)),
      themeMode: themeProvider.themeMode,
      home: SeparatelyPrayer(),
    );
  }
}
