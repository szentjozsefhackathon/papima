import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    /*
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_database.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );*/

    if (kIsWeb) {
      final path = 'PapIma.db';
      Database db = await databaseFactoryFfiWeb.openDatabase(path);
        await db.execute('CREATE TABLE IF NOT EXISTS priests (id INTEGER PRIMARY KEY, name TEXT, img TEXT, src TEXT, diocese TEXT)');
        await db.execute('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)');
      return db;

    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'papima.db');

    Database _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        db.execute(
            'CREATE TABLE IF NOT EXISTS priests (id INTEGER PRIMARY KEY, name TEXT, img TEXT, src TEXT, diocese TEXT)');
        return db.execute(
            'CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)');
      },
    );
    return _db;
  }
  Future<void> saveSetting(String key, String value) async {
    await database.then((db) async {
      await db.execute('INSERT OR REPLACE INTO SETTINGS (key, value) VALUES (?, ?);', [key, value]);
    });
  }
}
