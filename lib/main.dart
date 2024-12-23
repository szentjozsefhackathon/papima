import 'package:flutter/material.dart';
import 'pages/home/HomePage.dart';

void main() {
  runApp(PapImaApp());
}


class PapImaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PapIma',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: PapImaHomePage(),
    );
  }
}
