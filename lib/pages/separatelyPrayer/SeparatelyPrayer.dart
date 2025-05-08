import 'package:PapIma/database/DatabaseHelper.dart';
import 'package:PapIma/models/DailyGoalProvider.dart';
import 'package:PapIma/pages/separatelyPrayer/DailyStreakDialog.dart';
import 'package:PapIma/widgets/notification/notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/AutoProvider.dart';
import '../../models/BackButtonProvider.dart';
import '../../models/SeparatelyPrayerSettingsProvider.dart';
import '../../models/SystemBarProvider.dart';
import '../../widgets/externalImage/external_image.dart';
import '../info/InfoPage.dart';
import '../../common/launch_url.dart';
import '../settings/SettingsPage.dart';
import '../loadPriests/LoadPriests.dart';
import '../../common/first_where_or_first.dart';
//import '../../widgets/mobileapp/mobileapp.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../common/tts.dart';

class SeparatelyPrayer extends StatefulWidget {
  @override
  _SeparatelyPrayerState createState() => _SeparatelyPrayerState();
}

class _SeparatelyPrayerState extends State<SeparatelyPrayer> {
  List<Map<String, dynamic>> priests = [];
  int currentIndex = 0;
  int dailyCounter = 0;
  String dailyCounterDate = '';
  int dailyStreak = 0;

  late Database db;
  bool showAdvanced = false;
  bool checked = false;
  bool auto = false;
  List<Map> prayers = [];
  @override
  void initState() {
    super.initState();
    DatabaseHelper().database.then((database) {
      db = database;
      _loadPriestsFromDatabase().then((_) {
        _loadIndexFromDatabase().then((_) {
            if(checkCardinalsInList(priests)) {
              List<Map<String, dynamic>> newPriests = [];
              int decrease = 0;
              for (var i = 0; i < priests.length; i++) {
                if (priests[i]['diocese'] == "Bíborosi Kar") {
                  if (i < currentIndex) {
                    decrease++;
                  }
                } else {
                  newPriests.add(priests[i]);
                }
              }
              setState(() {
                priests = newPriests;
                currentIndex = currentIndex - decrease;
              });

              DatabaseHelper().savePriests(newPriests);
              DatabaseHelper().saveSetting("index", currentIndex.toString());
            }
        });
      });
      _loadIndexFromDatabase();
      _getDailyCounter().then((value) => setState(() => dailyCounter = value));
      _getDailyStreak().then((value) => setState(() => dailyStreak = value));
    });

    DatabaseHelper().prayers.then((value) {
      setState(() {
        prayers = value;
      });
    });
  }
  bool checkCardinalsInList(p) {
    for (var priest in p) {
      if (priest['diocese'] == "Bíborosi Kar") {
        return true;
      }
    }
    return false;
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

  void _increaseDailyCounter({int amount = 1}) async {
    final now = DateTime.now();
    final date = '${now.year}-${now.month}-${now.day}';
    if (dailyCounterDate != date) {
      final dc = await _getDailyCounter();
      setState(() {
        dailyCounter = dc;
        dailyCounterDate = date;
      });
    }
    if (dailyCounter + amount < 0) {
      amount = dailyCounter;
    }
    db.rawInsert(
        'INSERT OR REPLACE INTO days (date, count) VALUES (?, COALESCE((SELECT count FROM days WHERE date = ?), 0) + ?)',
        [date, date, amount]);
    dailyCounter += amount;
  }

  Future<int> _getDailyCounter() async {
    final now = DateTime.now();
    setState(() {
      dailyCounterDate = '${now.year}-${now.month}-${now.day}';
    });
    final res = await db
        .query('days', where: 'date = ?', whereArgs: [dailyCounterDate]);
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

  Future<void> readPriest() async {
    final tts = await TTS().get;
    await tts.speak(
        "${priests[currentIndex]['name']}, ${priests[currentIndex]['diocese']}");
  }

  void _auto(int seconds) async {
    if (auto) {
      await readPriest();
      Future.delayed(Duration(seconds: seconds), () {
        if (auto) {
          _nextPriest();
          _auto(seconds);
        }
      });
    }
  }

  String order(int? orderNum) {
    switch (orderNum) {
      case 0:
        return 'Papnövendék';
      case 1:
        return 'Diakónus';
      case 2:
        return 'Pap';
      case 3:
        return 'Püspök';
    }
    return "";
  }

  String orderName(int? orderNum) {
    switch (orderNum) {
      case 0:
        return 'seminarist';
      case 1:
        return 'deacon';
      case 3:
        return 'bishop';
      case 2:
      default:
        return 'priest';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPriest = priests.isNotEmpty ? priests[currentIndex] : null;
    final backButtonProvider = Provider.of<BackButtonProvider>(context);
    final dailyGoalProvider = Provider.of<DailyGoalProvider>(context);
    final systemBarProvider = Provider.of<SystemBarProvider>(context);
    final autoProvider = Provider.of<AutoProvider>(context);
    final settingsProvider =
        Provider.of<SeparatelyPrayerSettingsProvider>(context);
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
            if (priests.isNotEmpty)
              ElevatedButton.icon(
                  label: Text(dailyStreak > 0 ? dailyStreak.toString() : ''),
                  icon: Icon(Icons.local_fire_department),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) => DailyStreakDialog());
                  }),
            if (autoProvider.enabled)
              IconButton(
                icon: Icon(auto ? Icons.stop : Icons.directions_car),
                onPressed: () {
                  setState(() {
                    auto = !auto;
                    _auto(autoProvider.seconds);
                  });
                },
              ),
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
                                      /* cardinalsInList =
                                          checkCardinalsInList(priests); */ 
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
                        Text(
                            currentPriest['diocese']
                                .toString()
                                .replaceAll("Rendtarománya", "Rendtartománya"),
                            textAlign: TextAlign.center),
                        if (currentPriest['order'] != null) ...[
                          SizedBox(height: 8),
                          Text(order(currentPriest['order'])),
                        ],
                      ],
                      SizedBox(height: 16),
                      if (settingsProvider.prayer['enabled'] &&
                          settingsProvider
                                  .prayer[orderName(currentPriest?['order'])] !=
                              null)
                        SizedBox(
                            width: 300 +
                                settingsProvider.prayer['id']
                                        .toString()
                                        .length *
                                    0.0,
                            child: Text(
                                firstWhereOrFirst(
                                        prayers,
                                        (element) =>
                                            element['id'].toString() ==
                                            settingsProvider.prayer[orderName(
                                                    currentPriest?['order'])]
                                                .toString())?['text'] ??
                                    "",
                                textAlign: TextAlign.justify)),
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
                      /* if (!cardinalsInList)
                        ElevatedButton.icon(
                            onPressed: () {
                              String sourceUrl =
                                  'https://szentjozsefhackathon.github.io/sematizmus/data.json';
                              http.get(Uri.parse(sourceUrl)).then((response) {
                                if (response.statusCode == 200) {
                                  final data =
                                      jsonDecode(response.body) as List;
                                  var cardinals = data
                                      .where(
                                          (e) => e['diocese'] == "Bíborosi Kar")
                                      .map((e) => {
                                            'name': e['name'],
                                            'img': e['img'],
                                            'src': e['src'],
                                            'diocese': e['diocese'],
                                            'order': 2,
                                          })
                                      .toList();

                                  cardinals.sort((a, b) => a['name']
                                      .toString()
                                      .compareTo(b['name'].toString()));
                                  setState(() {
                                    List<Map<String, dynamic>> _priests = [];
                                    for (var i = 0; i <= currentIndex; i++) {
                                      _priests.add(priests[i]);
                                    }
                                    _priests.addAll(cardinals);
                                    for (var i = currentIndex + 1;
                                        i < priests.length;
                                        i++) {
                                      _priests.add(priests[i]);
                                    }
                                    priests = _priests;
                                    cardinalsInList = true;
                                    DatabaseHelper().savePriests(priests);
                                  });
                                }
                              });
                            },
                            label: Text("Ima a bíborosokért"),
                            icon: Icon(Icons.church),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            )),*/

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
                              SizedBox(height: 8),
                              Text(currentPriest.toString()),
                            ],
                          ),
                        ),
                      //MobileApp(),
                      NotificationDialog()
                    ],
                  ),
          ),
        ));
  }
}
