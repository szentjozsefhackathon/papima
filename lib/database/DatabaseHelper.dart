import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:http/http.dart' as http;

enum ColumnType {
  integer('INTEGER'),
  real('REAL'),
  text('TEXT'),
  blob('BLOB');

  final String sqlType;
  const ColumnType(this.sqlType);
}

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
    await _db.execute('CREATE TABLE IF NOT EXISTS notifications (title TEXT, text TEXT, startDate TEXT, endDate TEXT, showEveryStart INTEGER, isShowed INTEGER)');
    await addColumnIfNotExists(database: _db, tableName: "priests", columnName: "order", columnType: ColumnType.integer, defaultValue: null, isNullable: true);
    //todo: remove hardcode
    var result = await _db.query('prayers', where: 'isdefault = ?', whereArgs: [1]);
    var prayers = await _downloadPrayers();
    if (result.length != prayers.length) {
      await _db.delete('prayers', where: 'isdefault = ?', whereArgs: [1]);
      for (final prayer in prayers) {
        await _db.insert('prayers', {
          'name': prayer['name'],
          'text': prayer['text'],
          'isdefault': 1
        });
      }
    }

     
    return _db;
  }

  Future<List<Map>> _downloadPrayers() async {
  List<Map> prayers = [];
    try {
      final response = await http.get(Uri.parse("https://papima.hu/prayers.json"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        prayers = data
            .map((e) => {
                  'name': e['name'],
                  'text': e['text'],
                })
            .toList();
      }
    } catch (e) {
      print('Failed to fetch prayers: $e');
    }
    return prayers;

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


/// Formázza az alapértelmezett értéket az SQL kifejezésben való használathoz.
String _formatDefaultValue(dynamic value) {
  if (value is String) {
    return '\'$value\''; // Szöveges értékek idézőjelek közé kerülnek.
  } else if (value is num || value is bool) {
    return value.toString();
  } else {
    throw ArgumentError('Nem támogatott alapértelmezett érték: $value');
  }
}
Future<void> addColumnIfNotExists({
  required Database database,
  required String tableName,
  required String columnName,
  required ColumnType columnType,
  required bool isNullable,
  dynamic defaultValue,
}) async {
  final List<Map<String, dynamic>> tableInfo = await database.rawQuery('PRAGMA table_info($tableName);');

  final bool columnExists = tableInfo.any((column) => column['name'] == columnName);

  if (!columnExists) {
    final String defaultClause = defaultValue != null ? ' DEFAULT ${_formatDefaultValue(defaultValue)}' : '';
    final String nullableClause = isNullable ? '' : ' NOT NULL';
    final String sql = 'ALTER TABLE $tableName ADD COLUMN \'$columnName\' ${columnType.sqlType}$nullableClause$defaultClause;';

    await database.execute(sql);
  }
}
}
