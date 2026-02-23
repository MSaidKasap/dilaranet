import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'prayer_times.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE prayer_times(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            fajr TEXT,
            sunrise TEXT,
            dhuhr TEXT,
            asr TEXT,
            maghrib TEXT,
            isha TEXT
          )
        ''');
      },
    );
  }
}
