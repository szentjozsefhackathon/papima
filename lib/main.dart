import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/ThemeProvider.dart';
import 'pages/home/HomePage.dart';

void main() {
  runApp(ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: PapImaApp(),
    ),);
}


class PapImaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'PapIma',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.themeMode,
      home: PapImaHomePage(),
    );
  }
}
