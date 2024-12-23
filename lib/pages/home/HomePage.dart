import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../../widgets/externalImage/external_image.dart';
import '../info/InfoPage.dart';
import '../../common/launch_url.dart';

class PapImaHomePage extends StatefulWidget {
  @override
  _PapImaHomePageState createState() => _PapImaHomePageState();
}

class _PapImaHomePageState extends State<PapImaHomePage> {
  List<Map<String, dynamic>> priests = [];
  int currentIndex = 0;
  String sourceUrl =
      'https://szentjozsefhackathon.github.io/sematizmus/papima.json';
  late Database db;
  bool showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _initDatabase().then((_) {
      _loadPriestsFromDatabase();
      _loadIndexFromDatabase();
    });
  }

  Future<void> _initDatabase() async {
    if (kIsWeb) {
      final path = 'PapIma.db';
      db = await databaseFactoryFfiWeb.openDatabase(path);
        await db.execute('CREATE TABLE IF NOT EXISTS priests (id INTEGER PRIMARY KEY, name TEXT, img TEXT, src TEXT, diocese TEXT)');
        await db.execute('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)');
      return;
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'papima.db');

    db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        db.execute(
            'CREATE TABLE IF NOT EXISTS priests (id INTEGER PRIMARY KEY, name TEXT, img TEXT, src TEXT, diocese TEXT)');
        return db.execute(
            'CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)');
      },
    );
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

  Future<void> _saveSetting(String key, String value) async {
    await db.execute(
        'INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?);',
        [key, value]);
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

  void _nextPriest() {
    setState(() {
      currentIndex = (currentIndex + 1) % priests.length;
      _saveSetting("index", currentIndex.toString());
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
      _saveSetting("index", currentIndex.toString());
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
          ],
        ),
        body: SingleChildScrollView(
          child: Center(
            child: priests.isEmpty
                ? CircularProgressIndicator()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (currentPriest != null) ...[
                        if (currentPriest['img'] != null) ...[
                          DynamicImage(
                            src: currentPriest['img'],
                            maxWidth: 300,
                            maxHeight: 300,
                          ),
                          SizedBox(height: 16),
                        ]
                        else ...[
                          SizedBox(height: 316)
                        ],
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
                              ),
                              SizedBox(height: 16),
                              TextField(
                                decoration: InputDecoration(
                                  labelText: 'Forrás URL',
                                ),
                                onSubmitted: _updateSource,
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
