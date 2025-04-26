import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'egg_production.dart'; // Adjust path if needed

class DBHelper {
  static Database? _db;

  static const String eggTable = 'egg_production';

  static Future<Database> _getDb() async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'poultry_farm.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute(''' 
          CREATE TABLE $eggTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            batch TEXT,
            quality TEXT,
            quantity INTEGER,
            date TEXT
          );
        ''');
      },
    );
  }

  // ===== 🥚 Egg Production =====
  static Future<int> insertEggProduction(EggProduction egg) async {
    final db = await _getDb();
    return await db.insert(eggTable, egg.toMap());
  }

  static Future<List<EggProduction>> getEggProductions() async {
    final db = await _getDb();
    final List<Map<String, dynamic>> maps = await db.query(eggTable, orderBy: 'date DESC');
    return List.generate(maps.length, (i) => EggProduction.fromMap(maps[i]));
  }

  static Future<int> updateEggProduction(EggProduction egg) async {
    final db = await _getDb();
    return await db.update(
      eggTable,
      egg.toMap(),
      where: 'id = ?',
      whereArgs: [egg.id],
    );
  }
  static Future<int> getTotalEggCount() async {
    final db = await _getDb();
    final result = await db.rawQuery('SELECT SUM(quantity) as total FROM $eggTable');
    return result.first['total'] != null ? result.first['total'] as int : 0;
  }


  static Future<int> deleteEggProduction(int id) async {
    final db = await _getDb();
    return await db.delete(
      eggTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
