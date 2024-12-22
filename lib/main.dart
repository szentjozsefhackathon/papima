import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
//import 'package:web/web.dart' as web;
//import 'dart:ui_web' as ui_web;

void main() {
  runApp(PapImaApp());
}

class DynamicHtmlImage extends StatefulWidget {
  final String src; // Képforrás
  final double maxWidth; // Maximális szélesség
  final double maxHeight; // Maximális magasság

  const DynamicHtmlImage({
    Key? key,
    required this.src,
    required this.maxWidth,
    required this.maxHeight,
  }) : super(key: key);

  @override
  _DynamicHtmlImageState createState() => _DynamicHtmlImageState();
}

class _DynamicHtmlImageState extends State<DynamicHtmlImage> {
  //late web.HTMLImageElement _imageElement; // HTML ImageElement a kép megjelenítéséhez
  late String _viewType; // Egyedi nézettípus az azonosításhoz

  @override
  void initState() {
    super.initState();
    _viewType = 'html-image-view-${UniqueKey()}'; // Egyedi azonosító generálása

    // Regisztráljuk a platformnézet gyárat
    if (kIsWeb) {
      // ignore: undefined_prefixed_name
      /*ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) => _imageElement, // A HTML elem visszaadása
      );*/
    }

    // HTML ImageElement inicializálása
   /* _imageElement = web.HTMLImageElement()
      ..src = widget.src // Beállítjuk a képforrást
      ..style.objectFit = 'scale-down'
      ..style.maxWidth = '${widget.maxWidth}px' // Maximális szélesség stílus
      ..style.maxHeight = '${widget.maxHeight}px'; // Maximális magasság stílus */
  }

  @override
  void didUpdateWidget(DynamicHtmlImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Ellenőrizzük, hogy változott-e a képforrás vagy a méretek
    if (widget.src != oldWidget.src ||
        widget.maxWidth != oldWidget.maxWidth ||
        widget.maxHeight != oldWidget.maxHeight) {
      setState(() {
       /* _imageElement.src = widget.src; // Új képforrás beállítása
        _imageElement.style.maxWidth = '${widget.maxWidth}px'; // Új max szélesség
        _imageElement.style.maxHeight = '${widget.maxHeight}px'; // Új max magasság */
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.maxWidth, // A nézet szélessége
          height: widget.maxHeight, // A nézet magassága
          child: HtmlElementView(viewType: _viewType), // HTML nézet
        ),
      ],
    );
  }
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
                          kIsWeb ? 
                          DynamicHtmlImage(
                            src: currentPriest['img'],
                            maxWidth: 300,
                            maxHeight: 300,
                          )
                          : Image.network(
                            currentPriest['img'],
                            width: 300,
                            height: 300,
                            fit: BoxFit.scaleDown,
                          ),
                          SizedBox(height: 16),
                        ]
                        else ...[
                          SizedBox(height: 316)
                        ],
                        InkWell(
                          onTap: () => _launchUrl(currentPriest['src']),
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

  void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class InfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Információk'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'PapIma Alkalmazás',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Ez az alkalmazás segíti a Magyar Katolikus Egyház papjaiért való imádkozást. A papokat a nyilvános sematizmusból nyerjük. Jelenleg azt az imaformát támogatja az alkalmazás, hogy elkezdi a papokat "végigimádkozni" az elejéről és a haladást nyomonköveti az alkalmazás. Az alkalmazás nem oszt meg adatokat.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Divider(),
            Text(
              'Hasznos hivatkozások',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.link, color: Colors.blue),
              title: Text(
                'GitHub projekt',
                style: TextStyle(
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
              onTap: () {
                _launchUrl('https://github.com/szentjozsefhackathon/papima');
              },
            ),
            ListTile(
              leading: Icon(Icons.link, color: Colors.green),
              title: Text(
                'Sematizmus (Forrás)',
                style: TextStyle(
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
              onTap: () {
                _launchUrl('https://szentjozsefhackathon.github.io/sematizmus');
              },
            ),
            ListTile(
              leading: Icon(Icons.link, color: Colors.red),
              title: Text(
                'Szent József Hackathon',
                style: TextStyle(
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
              onTap: () {
                _launchUrl('https://szentjozsef.jezsuita.hu/szent-jozsef-hackathon/');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

