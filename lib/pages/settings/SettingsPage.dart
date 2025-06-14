import 'package:PapIma/database/DatabaseHelper.dart';
import 'package:PapIma/pages/settings/PrayerList.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/AutoProvider.dart';
import '../../models/BackButtonProvider.dart';
import '../../models/DailyGoalProvider.dart';
import '../../models/SystemBarProvider.dart';
import '../../models/ThemeProvider.dart';
import '../../models/SeparatelyPrayerSettingsProvider.dart';
import '../../common/first_where_or_first.dart';
import 'package:color_scheme_display/color_scheme_display.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettinsPageState createState() => _SettinsPageState();
}

class _SettinsPageState extends State<SettingsPage> {
  List<Map> prayers = [];

  @override
  void initState() {
    super.initState();
    DatabaseHelper().prayers.then((value) {
      setState(() {
        prayers = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final systemBarProvider = Provider.of<SystemBarProvider>(context);
    final dailyGoalProvider = Provider.of<DailyGoalProvider>(context);
    final backButtonProvider = Provider.of<BackButtonProvider>(context);
    final autoProvider = Provider.of<AutoProvider>(context);
    final settingsProvider =
        Provider.of<SeparatelyPrayerSettingsProvider>(context);
    final List<Map<String, dynamic>> orders = [
      {'name': 'priest', 'text': 'Pap'},
      {'name': 'seminarist', 'text': 'Szeminarista'},
      {'name': 'deacon', 'text': 'Diakónus'},
      {'name': 'bishop', 'text': 'Püspök'},
    ];
    return Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            
            onDoubleTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ColorSchemeDisplay()),
            ),
            child: Text('Beállítások'),
          )
        ),
        body: SingleChildScrollView(
          child: Padding(
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
                if (!kIsWeb) ...[
                  Text('Teljes képernyő'),
                  Switch(
                    value: systemBarProvider.fullScreen,
                    onChanged: (bool value) {
                      systemBarProvider.setFullScreen(value);
                    },
                  )
                ],
                Text('Vissza gomb'),
                Switch(
                  value: backButtonProvider.backButton,
                  onChanged: (bool value) {
                    backButtonProvider.setBackButton(value);
                  },
                ),
                Text('Napi cél'),
                Switch(
                  value: dailyGoalProvider.enabled,
                  onChanged: (bool value) {
                    dailyGoalProvider.setEnabled(value);
                  },
                ),
                if (dailyGoalProvider.enabled)
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Napi cél',
                    ),
                    onChanged: (value) {
                      dailyGoalProvider.setDailyGoal(int.parse(value));
                    },
                    initialValue: dailyGoalProvider.dailyGoal.toString(),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                  ),
                Text('Automatikus lejátszás'),
                Switch(
                  value: autoProvider.enabled,
                  onChanged: (bool value) {
                    autoProvider.setEnabled(value);
                  },
                ),
                if (autoProvider.enabled)
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Másodperc',
                    ),
                    onChanged: (value) {
                      autoProvider.setSeconds(int.tryParse(value) ?? 30);
                    },
                    initialValue: autoProvider.seconds.toString(),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                  ),
                if (prayers.isNotEmpty) ...[
                  Text('Imádság megjelenítése'),
                  Switch(
                    value: settingsProvider.prayer['enabled'],
                    onChanged: (bool value) {
                      var _prayer = settingsProvider.prayer;
                      for (var order in orders) {
                        if (_prayer[order['name']] == null && prayers.isNotEmpty) {
                          _prayer[order['name']] = prayers[0]['id'];
                        }
                      }
                      _prayer['enabled'] = value;
                      settingsProvider.setPrayer(_prayer);
                    },
                  ),
                  if (settingsProvider.prayer['enabled']) ...[
                    ...orders.map((e) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Imádság ${e['text']}ért'),
                            DropdownButton<String>(
                              value: (firstWhereOrFirst(prayers, (prayer) {
                                        return prayer['id'].toString() ==
                                            settingsProvider.prayer[e['name']]
                                                .toString();
                                      })?['id'] ??
                                      prayers[0]['id'])
                                  .toString(),
                              onChanged: (String? value) {
                                var _prayer = settingsProvider.prayer;
                                _prayer[e['name']] = int.parse(value!);
                                settingsProvider.setPrayer(_prayer);
                              },
                              items: prayers.map((prayer) {
                                return DropdownMenuItem<String>(
                                  value: prayer['id'].toString(),
                                  child: Text(prayer['name']),
                                );
                              }).toList(),
                            ),
                          ],
                        )),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PrayerListPage(
                                    onChange: () async {
                                      var p = await DatabaseHelper().prayers;
                                      setState(() {
                                        prayers = p;
                                      });
                                    },
                                  )),
                        );
                      },
                      child: Text('Imádságok kezelése'),
                    ),
                  ]
                ]
              ],
            ),
          ),
        ));
  }
}
