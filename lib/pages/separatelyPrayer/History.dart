import 'dart:math';

import 'package:PapIma/database/DatabaseHelper.dart';
import 'package:flutter/material.dart';

class History extends StatefulWidget {
  @override
  _HistoryState createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  List<Map> history = [];

  @override
  void initState() {
    super.initState();
    _getHistory().then((value) {
      setState(() {
        history = value;
      });
    });
  }

  Future<List<Map>> _getHistory() async {
    var db = await DatabaseHelper().database;
    List<Map> history = await db.query('days', columns: ['date', 'count']);
    return history.map((e) => {
      'text': e['date'],
      'value': e['count']
    }).toList();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Előzmények'),
      ),
      body: ListView.builder(
        shrinkWrap: false, 
        itemBuilder: (builder, index) {
          Map data = history[index];
          return ListTile(
              title: Text("${data['text']}"),
              leading: CircleAvatar(
                child: Text('${data['value']}'),
              ));
        },
        itemCount: history.length,
      ),
    );
  }

}
