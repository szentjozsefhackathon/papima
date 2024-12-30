import 'package:PapIma/database/DatabaseHelper.dart';
import 'package:PapIma/models/DailyGoalProvider.dart';
import 'package:PapIma/pages/separatelyPrayer/DailyStreakDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/BackButtonProvider.dart';
import '../../models/SystemBarProvider.dart';
import '../../widgets/externalImage/external_image.dart';
import '../info/InfoPage.dart';
import '../../common/launch_url.dart';
import '../settings/SettingsPage.dart';
import '../loadPriests/LoadPriests.dart';

import '../../common/tts.dart';

class SeparatelyPrayer extends StatefulWidget {
  @override
  _SeparatelyPrayerState createState() => _SeparatelyPrayerState();
}

class _SeparatelyPrayerState extends State<SeparatelyPrayer> {
  List<Map<String, dynamic>> priests = [];
  int currentIndex = 0;
  int dailyCounter = 0;
  int dailyStreak = 0;

  late Database db;
  bool showAdvanced = false;
  bool checked = false;

  @override
  void initState() {
    super.initState();
    DatabaseHelper().database.then((database) {
      db = database;
      _loadPriestsFromDatabase();
      _loadIndexFromDatabase();
      _getDailyCounter().then((value) => setState(() => dailyCounter = value));
      _getDailyStreak().then((value) => setState(() => dailyStreak = value));
    });
  }

  Future<void> _loadPriestsFromDatabase() async {
    final result = await db.query('priests');
    if (result.isNotEmpty) {
      setState(() {
        priests = result;
        currentIndex = 0;
      });
    }
    setState(() {
      checked = true;
    });
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
    dailyCounter += amount;
  }

  Future<int> _getDailyCounter() async {
    final now = DateTime.now();
    final date = '${now.year}-${now.month}-${now.day}';
    final res = await db.query('days', where: 'date = ?', whereArgs: [date]);
    return res.isNotEmpty ? int.parse(res.first['count'].toString()) : 0;
  }

  Future<int> _getDailyStreak() async {
    final now = DateTime.now();
    final date = '${now.year}-${now.month}-${now.day}';
    final res =
        await db.query('dailyStreak', where: 'date = ?', whereArgs: [date]);
    return res.isNotEmpty ? int.parse(res.first['count'].toString()) : 0;
  }

  Future<void> _updateDailyStreak() async {
    int ds = await _getDailyStreak();
    setState(() {
      dailyStreak = ds;
    });
    if (dailyStreak != 0) {
      return;
    }
    final yesterday = DateTime.now().add(Duration(days: -1));
    final yesterdayDate =
        '${yesterday.year}-${yesterday.month}-${yesterday.day}';
    final today = DateTime.now();
    final date = '${today.year}-${today.month}-${today.day}';
    final res = await db
        .query('dailyStreak', where: 'date = ?', whereArgs: [yesterdayDate]);
    final count = res.isNotEmpty ? int.parse(res.first['count'].toString()) : 0;
    await db.rawInsert('INSERT INTO dailyStreak (date, count) VALUES (?, ?)',
        [date, count + 1]);
    setState(() {
      dailyStreak = count + 1;
    });
  }

  void _nextPriest() {
    setState(() {
      if (currentIndex == priests.length - 1) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Gratulálok!'),
              content: const Text('Végigimádkoztad a papokat!'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    _deletePriestList();
                    Navigator.of(context).pop(); // Művelet és bezárás
                  },
                  child: const Text('Újrakezdés'),
                ),
              ],
            );
          },
        );
        return;
      }
      currentIndex = (currentIndex + 1) % priests.length;
      DatabaseHelper().saveSetting("index", currentIndex.toString());
      _increaseDailyCounter();
      _updateDailyStreak();
    });
  }

  void _deletePriestList() {
    setState(() {
      priests = [];
      DatabaseHelper().savePriests(priests);
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
    if (index != null && index >= 0 && index <= priests.length) {
      setState(() {
        currentIndex = index - 1;
      });
      DatabaseHelper().saveSetting("index", currentIndex.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPriest = priests.isNotEmpty ? priests[currentIndex] : null;
    final backButtonProvider = Provider.of<BackButtonProvider>(context);
    final dailyGoalProvider = Provider.of<DailyGoalProvider>(context);
    final systemBarProvider = Provider.of<SystemBarProvider>(context);

    SystemChrome.setEnabledSystemUIMode(systemBarProvider.fullScreen
        ? SystemUiMode.immersive
        : SystemUiMode.edgeToEdge);
    return Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            onDoubleTap: _toggleAdvanced,
            child: Text('PapIma'),
          ),
          actions: [
            ElevatedButton.icon(
                label: Text(dailyStreak > 0 ? dailyStreak.toString() : ''),
                icon: Icon(Icons.local_fire_department),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) => DailyStreakDialog());
                }),
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
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: checked
                        ? [
                            LoadPriests(
                                page: false,
                                prefix: "separatelyPrayer_loadPriests",
                                onLoad: (value) {
                                  setState(() {
                                    DatabaseHelper()
                                        .savePriests(value)
                                        .then((v) {
                                      priests = value;
                                      _updateIndex("1");
                                    });
                                  });
                                })
                          ]
                        : [
                            SizedBox(height: 316),
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text("Papok betöltése...")
                          ])
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (currentPriest != null) ...[
                        DynamicImage(
                          src: currentPriest['img'] ??
                              "https://szentjozsefhackathon.github.io/sematizmus/ftPlaceholder.png",
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
                        Text(currentPriest['diocese']
                            .toString()
                            .replaceAll("Rendtarománya", "Rendtartománya")),
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
                            onPressed: _previousPriest, child: Text('Előző')),
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
                              ElevatedButton.icon(
                                onPressed: _deletePriestList,
                                label: Text('Paplista törlése (és frissítése)'),
                                icon: Icon(Icons.delete),
                              ),
                              ElevatedButton.icon(icon: Icon(Icons.speaker), label: Text('Olvasd fel'), onPressed: () async {
                                final tts = await TTS().get;
                                await tts.speak(currentPriest!['name']);
                                await tts.speak(currentPriest['diocese']);
                              }),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ));
  }
}
