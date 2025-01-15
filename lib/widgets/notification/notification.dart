import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import '../../database/DatabaseHelper.dart';

class NotificationDialog extends StatelessWidget {
  static bool showed = false;
  Future<void> setIsShowed() async {
    Database db = await DatabaseHelper().database;
    await db.update('notifications', {'isShowed': 1});
  }

  Future<void> saveDifferences(List<Map> online, List<Map> dbNot) async {
    Database db = await DatabaseHelper().database;
    List<Map> newNotifications = online
        .where((e) => !dbNot.any((element) =>
            element['title'] == e['title'] &&
            element['text'] == e['text'] &&
            element['startDate'] == e['startDate'] &&
            element['endDate'] == e['endDate'] &&
            element['showEveryStart'] == e['showEveryStart']))
        .toList();
    List<Map> oldNotifications = dbNot
        .where((e) => !online.any((element) =>
            element['title'] == e['title'] &&
            element['text'] == e['text'] &&
            element['startDate'] == e['startDate'] &&
            element['endDate'] == e['endDate'] &&
            element['showEveryStart'] == e['showEveryStart']))
        .toList();

    for (final notification in newNotifications) {
      await db.insert('notifications', {
        'title': notification['title'],
        'text': notification['text'],
        'startDate': notification['startDate'].toString(),
        'endDate': notification['endDate'].toString(),
        'showEveryStart': (notification['showEveryStart']??false)?1:0,
        'isShowed': 0,
      });
    }

    for (final notification in oldNotifications) {
      await db.delete('notifications',
          where:
              'title = ? and text = ? and startDate = ? and endDate = ? and showEveryStart = ?',
          whereArgs: [
            notification['title'],
            notification['text'],
            notification['startDate'].toString(),
            notification['endDate'].toString(),
            (notification['showEveryStart']??false)?1:0
          ]);
    }
  }

  Future<List<Map>> getNotificationsFromDB() async {
    Database db = await DatabaseHelper().database;
    List<Map> _notifications = await db.query('notifications');
    _notifications = _notifications
        .map((e) => {
              'title': e['title'],
              'text': e['text'],
              'startDate': DateTime.parse(e['startDate']),
              'endDate': DateTime.parse(e['endDate']),
              'showEveryStart': ((e['showEveryStart']??0)==1) ? true : false,
              'isShowed': (e['isShowed']??0)==1,
            })
        .where((e) =>
            e['startDate'].isBefore(DateTime.now()) &&
            e['endDate'].isAfter(DateTime.now()))
        .toList();
    return _notifications;
  }

  Future<List<Map>> downloadNotifications() async {
    // https://papima.hu/notifications.json

    List<Map> notifications = [];
    try {
      final response =
          await http.get(Uri.parse("https://papima.hu/notifications.json"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        notifications = data
            .map((e) => {
                  'title': e['title'],
                  'text': e['text'],
                  'startDate': DateTime.parse(e['startDate']),
                  'endDate': DateTime.parse(e['endDate']),
                  'showEveryStart': e['showEveryStart']??false,
                })
            .where((e) => (e['startDate'].isBefore(DateTime.now()) ?? true) &&
                (e['endDate'].isAfter(DateTime.now()) ?? true))
            .toList();
      }
    } catch (_) {}
    return notifications;
  }

  Widget dialog(BuildContext context, List<Map> notifications) {
    return AlertDialog(
        title: Text('Értesítések'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: notifications
              .map((e) => Column(
                    children: [
                      Text(e['title']),
                      Text(e['text']),
                    ],
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setIsShowed();
              Navigator.of(context).pop();
            },
            child: Text('Bezárás'),
          ),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getNotificationsFromDB().then((_db) {
        downloadNotifications().then((_online) {
          saveDifferences(_online, _db).then((_) {
            getNotificationsFromDB().then((value) {
              value = value
                  .where((element) =>
                      !element["isShowed"] ||
                      element["showEveryStart"])
                  .toList();
              if (value.isNotEmpty && !showed) {
                showDialog(
                    context: context,
                    builder: (context) => dialog(context, value));
                showed = true;
              }
            });
          });
        });
      });
    });
    return Container();
  }
}
