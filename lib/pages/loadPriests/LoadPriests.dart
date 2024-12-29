import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../database/DatabaseHelper.dart';
import '../../widgets/selectList/SelectList.dart';
import 'package:http/http.dart' as http;

class LoadPriests extends StatefulWidget {
  final List<Map> sources = [
    {"text": "Esztergom-Budapesti főegyházmegye"},
    {"text": "Győri egyházmegye"},
    {"text": "Székesfehérvári egyházmegye"},
    {"text": "Kalocsa-Kecskeméti főegyházmegye"},
    {"text": "Pécsi egyházmegye"},
    {"text": "Szeged-Csanádi egyházmegye"},
    {"text": "Egri főegyházmegye"},
    {"text": "Váci egyházmegye"},
    {"text": "Debrecen-Nyíregyházi egyházmegye"},
    {"text": "Veszprémi főegyházmegye"},
    {"text": "Kaposvári egyházmegye"},
    {"text": "Szombathelyi egyházmegye"},
    {"text": "Hajdúdorogi főegyházmegye"},
    {"text": "Miskolci egyházmegye"},
    {"text": "Nyíregyházi egyházmegye"},
    {"text": "Katonai Ordinariátus"},
    {"text": "Jézus Társasága Magyarországi Rendtartománya"},
    {"text": "Szent Istvánról elnevezett Magyar Szalézi Tartomány"},
    {"text": "Piarista Rend Magyar Tartománya"},
    {"text": "Esztergomi Szeminárium"},
    {"text": "Központi Szeminárium"},
    {"text": "Görögkatolikus Papnevelő Intézet"},
    {"text": "Győri Szeminárium"}
  ];

  @override
  _LoadPriestsState createState() => _LoadPriestsState();

  final String prefix;
  final bool page;

  LoadPriests(
      {super.key,
      required this.prefix,
      required this.onLoad,
      required this.page});
  final Function(List<Map<String, dynamic>>) onLoad;
}

class _LoadPriestsState extends State<LoadPriests> {
  bool deacons = true,
      seminarians = true,
      randomStart = true,
      randomOrder = false;
  String sourceUrl =
      'https://szentjozsefhackathon.github.io/sematizmus/data.json';
  late Database db;
  List<Map> selectedSources = [];

  Future<bool> _getDeacons() async {
    final res = await db.query('settings',
        where: 'key = ?', whereArgs: ['${widget.prefix}_deacons']);

    return res.isNotEmpty ? res.first['value'] == '1' : true;
  }

  Future<bool> _getSeminarians() async {
    final res = await db.query('settings',
        where: 'key = ?', whereArgs: ['${widget.prefix}_seminarians']);

    return res.isNotEmpty ? res.first['value'] == '1' : true;
  }

  Future<bool> _getRandomStart() async {
    final res = await db.query('settings',
        where: 'key = ?', whereArgs: ['${widget.prefix}_randomStart']);

    return res.isNotEmpty ? res.first['value'] == '1' : true;
  }

  Future<bool> _getRandomOrder() async {
    final res = await db.query('settings',
        where: 'key = ?', whereArgs: ['${widget.prefix}_randomOrder']);

    return res.isNotEmpty ? res.first['value'] == '1' : false;
  }

  Future<List<Map>> _getSelectedSources() async {
    List<Map> _selectedSources = [];
    var _si = await db.query('settings',
        where: 'key = ?', whereArgs: ['${widget.prefix}_selectedSources']);
    if (_si.isEmpty) return _selectedSources;
    var si = jsonDecode(_si.first['value'].toString()) as List;
    for (int i = 0; i < si.length; i++) {
      _selectedSources.add({"text": si[i]});
    }
    return _selectedSources;
  }

  Future<String> _getSourceUrl() async {
    final res = await db.query('settings',
        where: 'key = ?', whereArgs: ['${widget.prefix}_sourceUrl']);

    return res.isNotEmpty ? res.first['value'].toString() : sourceUrl;
  }

  void setDeacons(bool value) {
    DatabaseHelper().saveSetting('${widget.prefix}_deacons', value ? '1' : '0');

    setState(() {
      deacons = value;
    });
  }

  void setSeminarians(bool value) {
    DatabaseHelper()
        .saveSetting('${widget.prefix}_seminarians', value ? '1' : '0');

    setState(() {
      seminarians = value;
    });
  }

  void setRandomStart(bool value) {
    DatabaseHelper()
        .saveSetting('${widget.prefix}_randomStart', value ? '1' : '0');

    setState(() {
      randomStart = value;
    });
  }

  void setRandomOrder(bool value) {
    DatabaseHelper()
        .saveSetting('${widget.prefix}_randomOrder', value ? '1' : '0');

    setState(() {
      randomOrder = value;
    });
  }

  void setSelectedSources(List<Map> sources) {
    List<String> _selectedSources = [];
    for (int i = 0; i < sources.length; i++) {
      _selectedSources.add(sources[i]['text']);
    }
    DatabaseHelper().saveSetting(
        '${widget.prefix}_selectedSources', jsonEncode(_selectedSources));
    setState(() {
      selectedSources = sources;
    });
  }

  void setSourceUrl(String url) {
    DatabaseHelper().saveSetting('${widget.prefix}_sourceUrl', url);

    setState(() {
      sourceUrl = url;
    });
  }

  bool isLoading = false;
  void load() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(Uri.parse(sourceUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        var newPriests = data
            .where((e) => deacons ? true : !(e["deacon"] ?? false))
            .where((e) => seminarians ? true : !(e["seminarian"] ?? false))
            .where((e) => selectedSources.isEmpty
                ? true
                : selectedSources.map((e) => e['text']).contains(e['diocese']))
            .map((e) => {
                  'name': e['name'],
                  'img': e['img'],
                  'src': e['src'],
                  'diocese': e['diocese'],
                })
            .toList();

        newPriests.sort(
            (a, b) => a['name'].toString().compareTo(b['name'].toString()));

        if (randomStart) {
          final r = Random().nextInt(newPriests.length);
          newPriests = newPriests.sublist(r)..addAll(newPriests.sublist(0, r));
        }

        if (randomOrder) {
          newPriests.shuffle();
        }
        widget.onLoad(newPriests);
      }
    } catch (e) {
      print('Failed to fetch priests: $e');
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    DatabaseHelper().database.then((database) async {
      db = database;
      setState(() {
        _getDeacons().then((value) => deacons = value);
        _getSeminarians().then((value) => seminarians = value);
        _getRandomStart().then((value) => randomStart = value);
        _getRandomOrder().then((value) => randomOrder = value);
        _getSelectedSources().then((value) => selectedSources = value);
        _getSourceUrl().then((value) => sourceUrl = value);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = SingleChildScrollView(
      child: isLoading
          ? Column(
              children: [
                SizedBox(height: 316),
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Betöltés...')
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.page) Text('Papok betöltése', style: TextStyle(fontSize: 24)),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Forrás URL',
                    ),
                    onChanged: setSourceUrl,
                    initialValue: sourceUrl,
                  ),
                  Text('Diakónusok'),
                  Switch(value: deacons, onChanged: setDeacons),
                  Text('Szeminaristák'),
                  Switch(value: seminarians, onChanged: setSeminarians),
                  Text('Véletlenszerű kezdési hely'),
                  Switch(value: randomStart, onChanged: setRandomStart),
                  Text('Véletlenszerű sorrend'),
                  Switch(value: randomOrder, onChanged: setRandomOrder),
                  Text(
                      'Források (amennyiben nincs egy sem kijelölve, a szűrő inaktív, az első kijelöléséhez nyomjon hosszan)'),
                  SelectList(
                      list: widget.sources,
                      initialValue: selectedSources,
                      onSelectionChanged: setSelectedSources),
                  Text(
                      "Figyelem! A betöltés hosszabb időt vehet igénybe. Az alkalmazás magától tovább fog lépni."),
                  ElevatedButton(
                    onPressed: load,
                    child: Text('Betöltés'),
                  )
                ],
              ),
            ),
    );
    return widget.page
        ? Scaffold(
            appBar: AppBar(
              title: Text('Papok betöltése'),
            ),
            body: body,
          )
        : body;
  }
}
