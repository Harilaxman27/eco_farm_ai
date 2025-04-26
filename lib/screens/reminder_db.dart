import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'remainder_page.dart';

class ReminderDB {
  static final ReminderDB instance = ReminderDB._init();
  static Database? _database;

  ReminderDB._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('reminders.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL
      )
    ''');
  }

  Future<void> insertReminder(Reminder reminder) async {
    final db = await instance.database;
    await db.insert('reminders', reminder.toMap());
  }

  Future<List<Reminder>> getAllReminders() async {
    final db = await instance.database;
    final result = await db.query('reminders');
    return result.map((map) => Reminder.fromMap(map)).toList();
  }

  Future<void> deleteReminder(int id) async {
    final db = await instance.database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }
}
