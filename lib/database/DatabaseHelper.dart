import 'dart:async';
import 'package:PapIma/models/SeparatelyPrayerSettingsProvider.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  static Future<Database>? _database;

  DatabaseHelper._internal();
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    late Database _db;
    if (kIsWeb) {
      final path = 'PapIma.db';
      _db = await databaseFactoryFfiWeb.openDatabase(path);
    } else {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'papima.db');
      _db = await openDatabase(path, version: 1);
    }
    await _db.execute(
        'CREATE TABLE IF NOT EXISTS priests (id INTEGER PRIMARY KEY, name TEXT, img TEXT, src TEXT, diocese TEXT)');
    await _db.execute(
        'CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)');
    await _db.execute(
        'CREATE TABLE IF NOT EXISTS days (date TEXT PRIMARY KEY, count INTEGER)');
    await _db.execute(
        'CREATE TABLE IF NOT EXISTS dailyStreak (date TEXT PRIMARY KEY, count INTEGER)');
    await _db.execute('CREATE TABLE IF NOT EXISTS prayers (id INTEGER PRIMARY KEY, name TEXT, text TEXT, isdefault INTEGER)');

    //todo: remove hardcode
    var result = await _db.query('prayers', where: 'isdefault = ?', whereArgs: [1]);
    if (result.length != 1) {
      print("result length: ${result.length}");
      await _db.delete('prayers', where: 'isdefault = ?', whereArgs: [1]);
      await _db.insert('prayers', {
        "name": "Úr imádsága",
        "text": "Mi Atyánk, aki a mennyekben vagy, szenteltessék meg a te neved; jöjjön el a te országod; legyen meg a te akaratod, amint a mennyben, úgy a földön is. Mindennapi kenyerünket add meg nekünk ma; és bocsásd meg vétkeinket, miképpen mi is megbocsátunk az ellenünk vétkezőknek; és ne vígy minket kísértésbe, de szabadíts meg a gonosztól. Ámen.",
        "isdefault": 1
      });
    }

     
    return _db;
  }

  Future<void> saveSetting(String key, String value) async {
    await database.then((db) async {
      await db.execute(
          'INSERT OR REPLACE INTO SETTINGS (key, value) VALUES (?, ?);',
          [key, value]);
    });
  }

  Future<void> savePriests(List<Map<String, dynamic>> newPriests) async {
    var db = await database;
    await db.delete('priests');
    for (final priest in newPriests) {
      await db.insert('priests', priest);
    }
  }

  Future<void> savePrayer(Map<String, dynamic> prayer) async {
    if (prayer['id'] != null) {
      throw Exception('Cannot insert prayer with id');
    }

    List<String> fields = ['name', 'text'];
    for (final field in fields) {
      if (!prayer.containsKey(field)) {
        throw Exception('Prayer $field is required');
      }
      if(prayer[field] is! String) {
        throw Exception('Prayer $field must be a string');
      }
    }
    if (prayer.containsKey('isdefault') && prayer['isdefault'] is! bool) {
      throw Exception('Prayer isdefault must be a boolean');
    } else if (!prayer.containsKey('isdefault')) {
      prayer['isdefault'] = false;
    }
    var db = await database;
    await db.insert('prayers', prayer);
  }

  Future<List<Map>> get prayers async {
    var db = await database;
    
    final p = await db.query('prayers');
    return p;
  }
}
