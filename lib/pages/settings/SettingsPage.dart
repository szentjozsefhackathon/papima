import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ThemeProvider.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Beállítások'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Téma',
            ),
            RadioListTile<ThemeMode>(
              title: Text('Rendszer alapú'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text('Világos'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text('Sötét'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
              },
            ),
          ],
        ),
      ),
    );
  }
}
