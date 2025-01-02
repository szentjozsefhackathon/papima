import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../database/DatabaseHelper.dart';

class PrayerListPage extends StatefulWidget {
  @override
  _PrayerListPageState createState() => _PrayerListPageState();

  Function? onChange;

  PrayerListPage({super.key, this.onChange});
}

class _PrayerListPageState extends State<PrayerListPage> {
  List<Map> _prayers = [];

  @override
  void initState() {
    super.initState();
    _loadPrayers();
  }

  Future<void> _loadPrayers() async {
    final List<Map> prayers = (await DatabaseHelper().prayers).where((p) => p["isdefault"].toString()!='1').toList();
    setState(() {
      _prayers = prayers;
    });
    widget.onChange?.call();
  }

  Future<void> _addOrUpdatePrayer(int? id, String name, String text) async {
    if (id == null) {
      await (await DatabaseHelper().database).insert(
        'prayers',
        {'name': name, 'text': text, 'isdefault': '0'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await (await DatabaseHelper().database).update(
        'prayers',
        {'name': name, 'text': text},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    _loadPrayers();
  }

  Future<void> _deletePrayer(int id) async {
    await (await DatabaseHelper().database).delete(
      'prayers',
      where: 'id = ?',
      whereArgs: [id],
    );
    _loadPrayers();
  }

  void _showEditDialog(BuildContext context, {int? id, String? name, String? text}) {
    final TextEditingController nameController = TextEditingController(text: name);
    final TextEditingController textController = TextEditingController(text: text);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(id == null ? 'Imádság hozzáadása' : 'Imádság szerkesztése'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Név'),
              ),
              TextField(
                controller: textController,
                decoration: InputDecoration(labelText: 'Szöveg'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Mégsem'),
            ),
            TextButton(
              onPressed: () {
                _addOrUpdatePrayer(id, nameController.text, textController.text);
                Navigator.of(context).pop();
              },
              child: Text('Mentés'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Imádságok'),
      ),
      body: ListView.builder(
        itemCount: _prayers.length,
        itemBuilder: (context, index) {
          final prayer = _prayers[index];
          return ListTile(
            title: Text(prayer['name']),
            subtitle: Text(prayer['text']),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _showEditDialog(
                      context,
                      id: prayer['id'],
                      name: prayer['name'],
                      text: prayer['text'],
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    _deletePrayer(prayer['id']);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showEditDialog(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }
}