import 'package:PapIma/database/DatabaseHelper.dart';
import 'package:PapIma/models/DailyGoalProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/BackButtonProvider.dart';
import '../../models/SystemBarProvider.dart';
import '../../widgets/externalImage/external_image.dart';
import '../info/InfoPage.dart';
import '../../common/launch_url.dart';
import '../settings/SettingsPage.dart';

class PapImaHomePage extends StatefulWidget {
  @override
  _PapImaHomePageState createState() => _PapImaHomePageState();
}

class _PapImaHomePageState extends State<PapImaHomePage> {
  List<Map<String, dynamic>> priests = [];
  int currentIndex = 0;
  int dailyCounter = 0;
  String sourceUrl =
      'https://szentjozsefhackathon.github.io/sematizmus/papima.json';
  late Database db;
  bool showAdvanced = false;

  @override
  void initState() {
    super.initState();
    DatabaseHelper().database.then((database) {
        db = database;
        _loadPriestsFromDatabase();
        _loadIndexFromDatabase();
        _getDailyCounter().then((value) => setState(() => dailyCounter=value));
    });
  }


  Future<void> _loadPriestsFromDatabase() async {
    final result = await db.query('priests');
    if (result.isNotEmpty) {
      setState(() {
        priests = result;
        currentIndex = 0;
      });
    } else {
      _updatePriestList();
    }
  }

  Future<void> _loadIndexFromDatabase() async {
    final result =
        await db.query('settings', where: 'key = ?', whereArgs: ['index']);
    if (result.isNotEmpty) {
      setState(() {
        currentIndex = int.parse(result.first['value'].toString());
      });
    } else {
      setState(() {
        currentIndex = 0;
      });
      ;
    }
  }

  Future<void> _savePriestsToDatabase(
      List<Map<String, dynamic>> newPriests) async {
    await db.delete('priests');
    for (final priest in newPriests) {
      await db.insert('priests', priest);
    }
  }

  Future<void> _updatePriestList() async {
    try {
      final response = await http.get(Uri.parse(sourceUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        final newPriests = data
            .map((e) => {
                  'name': e['name'],
                  'img': e['img'],
                  'src': e['src'],
                  'diocese': e['diocese'],
                })
            .toList();

        setState(() {
          priests = newPriests;
          currentIndex = 0;
        });

        await _savePriestsToDatabase(newPriests);
      }
    } catch (e) {
      print('Failed to fetch priests: $e');
    }
  }

  void _increaseDailyCounter({int amount = 1}) {
    if (dailyCounter + amount < 0) {
      amount = dailyCounter;
    }
    final now = DateTime.now();
    final date = '${now.year}-${now.month}-${now.day}';
    db.rawInsert(
        'INSERT OR REPLACE INTO days (date, count) VALUES (?, COALESCE((SELECT count FROM days WHERE date = ?), 0) + ?)',
        [date, date, amount]);
    dailyCounter+=amount;
  }

  Future<int> _getDailyCounter() async {
    final now = DateTime.now();
    final date = '${now.year}-${now.month}-${now.day}';
    final res = await db.query('days', where: 'date = ?', whereArgs: [date]);
    return res.isNotEmpty ? int.parse(res.first['count'].toString()) : 0;
  }
  void _nextPriest() {
    setState(() {
      if (currentIndex == priests.length - 1) {
        _updatePriestList();
      }
      currentIndex = (currentIndex + 1) % priests.length;
      DatabaseHelper().saveSetting("index", currentIndex.toString());
      _increaseDailyCounter();
    });
  }

  void _previousPriest() {
    setState(() {
      currentIndex = (currentIndex - 1) % priests.length;
      DatabaseHelper().saveSetting("index", currentIndex.toString());
      _increaseDailyCounter(amount: -1);
    });
  }

  void _toggleAdvanced() {
    setState(() {
      showAdvanced = !showAdvanced;
    });
  }

  void _updateIndex(String value) {
    final index = int.tryParse(value);
    if (index != null && index >= 0 && index < priests.length) {
      setState(() {
        currentIndex = index-1;
      });
      DatabaseHelper().saveSetting("index", currentIndex.toString());
    }
  }

  void _updateSource(String value) {
    setState(() {
      sourceUrl = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentPriest = priests.isNotEmpty ? priests[currentIndex] : null;
    final backButtonProvider = Provider.of<BackButtonProvider>(context);
    final dailyGoalProvider = Provider.of<DailyGoalProvider>(context);
    final systemBarProvider = Provider.of<SystemBarProvider>(context);

    SystemChrome.setEnabledSystemUIMode(
        systemBarProvider.fullScreen
            ? SystemUiMode.immersive
            : SystemUiMode.edgeToEdge);
    return Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            onDoubleTap: _toggleAdvanced,
            child: Text('PapIma'),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InfoPage(),
                  ),
                );
              },
            ),
            IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
          ],
        ),
        body: SingleChildScrollView(
          child: Center(
            child: priests.isEmpty
                ? Column(children: [
                  SizedBox(height: 316),
                  CircularProgressIndicator()
                ])
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (currentPriest != null) ...[
                        DynamicImage(
                          src: currentPriest['img'] ?? "https://szentjozsefhackathon.github.io/sematizmus/ftPlaceholder.png",
                          maxWidth: 300,
                          maxHeight: 300,
                        ),
                        SizedBox(height: 16),

                        InkWell(
                          onTap: () => launch_url(currentPriest['src']),
                          child: Text(
                            currentPriest['name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(currentPriest['diocese']),
                      ],
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _nextPriest,
                        child: Text('Következő'),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '${currentIndex + 1}/${priests.length}',
                      ),
                      SizedBox(height: 16),
                      if (dailyGoalProvider.enabled)
                        Text(
                          'Napi cél: ${dailyCounter}/${dailyGoalProvider.dailyGoal}',
                        ),
                      SizedBox(height: 16),
                      if (backButtonProvider.backButton)
                        ElevatedButton(
                          onPressed: _previousPriest,
                          child: Text('Előző')
                        ),
                      if (showAdvanced)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                decoration: InputDecoration(
                                  labelText: 'Aktuális index',
                                ),
                                onSubmitted: _updateIndex,
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Forrás URL',
                                ),
                                onChanged: _updateSource,
                                initialValue: sourceUrl,
                              ),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _updatePriestList,
                                child: Text('Paplista frissítése'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ));
  }
}
