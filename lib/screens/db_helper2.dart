import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'broiler_models.dart';

class DBHelper2 {
  static final DBHelper2 _instance = DBHelper2._internal();
  factory DBHelper2() => _instance;
  DBHelper2._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'broiler.db');
    return await openDatabase(
      path,
      version: 2, // Bumped version to 2 to allow for column addition
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE broilers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            numberOfHens INTEGER,
            breed TEXT,
            initialWeight REAL,
            currentWeight REAL,
            feedConsumed REAL,
            healthStatus TEXT,
            medication TEXT,
            status TEXT,
            date TEXT,
            isVaccinated INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            ALTER TABLE broilers ADD COLUMN isVaccinated INTEGER DEFAULT 0
          ''');
        }
      },
    );
  }

  // Insert Broiler record into database
  Future<int> insertBroiler(Broiler broiler) async {
    final db = await database;
    return await db.insert('broilers', broiler.toMap());
  }

  // Get Broilers by status (alive or dead)
  Future<List<Broiler>> getBroilers({String status = 'alive'}) async {
    final db = await database;
    final maps = await db.query(
      'broilers',
      where: 'status = ?',
      whereArgs: [status],
    );
    return maps.map((map) => Broiler.fromMap(map)).toList();
  }

  // Update a Broiler in the database
  Future<void> updateBroiler(Broiler broiler) async {
    final db = await database;
    await db.update(
      'broilers',
      broiler.toMap(),
      where: 'id = ?',
      whereArgs: [broiler.id],
    );
  }

  // Delete a Broiler from the database
  Future<void> deleteBroiler(int id) async {
    final db = await database;
    await db.delete('broilers', where: 'id = ?', whereArgs: [id]);
  }

  // Get all Broilers from the database
  Future<List<Broiler>> getAllBroilers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('broilers');
    return List.generate(maps.length, (i) {
      return Broiler.fromMap(maps[i]);
    });
  }
}
