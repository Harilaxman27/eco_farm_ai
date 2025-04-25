import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DairyFinancialRecord {
  int? id;
  double feedingCost;
  double veterinaryCost;
  double laborCost;
  double equipmentCost;
  double transportCost;
  double miscellaneousCost;
  double housingMaintenanceCost;
  double milkRevenue;
  double totalExpenses;
  double profitOrLoss;
  double profitPercentage;
  String date;
  String season;

  DairyFinancialRecord({
    this.id,
    required this.feedingCost,
    required this.veterinaryCost,
    required this.laborCost,
    required this.equipmentCost,
    required this.transportCost,
    required this.miscellaneousCost,
    required this.housingMaintenanceCost,
    required this.milkRevenue,
    required this.totalExpenses,
    required this.profitOrLoss,
    required this.profitPercentage,
    required this.date,
    required this.season,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'feedingCost': feedingCost,
      'veterinaryCost': veterinaryCost,
      'laborCost': laborCost,
      'equipmentCost': equipmentCost,
      'transportCost': transportCost,
      'miscellaneousCost': miscellaneousCost,
      'housingMaintenanceCost': housingMaintenanceCost,
      'milkRevenue': milkRevenue,
      'totalExpenses': totalExpenses,
      'profitOrLoss': profitOrLoss,
      'profitPercentage': profitPercentage,
      'date': date,
      'season': season,
    };
  }
}

class DairyFinancialDBHelper {
  static final DairyFinancialDBHelper _instance = DairyFinancialDBHelper._internal();
  factory DairyFinancialDBHelper() => _instance;
  DairyFinancialDBHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('dairy_financials.db');
    return _db!;
  }

  Future<Database> _initDB(String filePath) async {
    final path = join(await getDatabasesPath(), filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE dairy_financials(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            feedingCost REAL,
            veterinaryCost REAL,
            laborCost REAL,
            equipmentCost REAL,
            transportCost REAL,
            miscellaneousCost REAL,
            housingMaintenanceCost REAL,
            milkRevenue REAL,
            totalExpenses REAL,
            profitOrLoss REAL,
            profitPercentage REAL,
            date TEXT,
            season TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertRecord(DairyFinancialRecord record) async {
    final db = await database;
    return await db.insert('dairy_financials', record.toMap());
  }

  Future<List<DairyFinancialRecord>> getRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('dairy_financials');
    return List.generate(maps.length, (i) {
      return DairyFinancialRecord(
        id: maps[i]['id'],
        feedingCost: maps[i]['feedingCost'],
        veterinaryCost: maps[i]['veterinaryCost'],
        laborCost: maps[i]['laborCost'],
        equipmentCost: maps[i]['equipmentCost'],
        transportCost: maps[i]['transportCost'],
        miscellaneousCost: maps[i]['miscellaneousCost'],
        housingMaintenanceCost: maps[i]['housingMaintenanceCost'],
        milkRevenue: maps[i]['milkRevenue'],
        totalExpenses: maps[i]['totalExpenses'],
        profitOrLoss: maps[i]['profitOrLoss'],
        profitPercentage: maps[i]['profitPercentage'],
        date: maps[i]['date'],
        season: maps[i]['season'],
      );
    });
  }

  Future<void> deleteRecord(int id) async {
    final db = await database;
    await db.delete('dairy_financials', where: 'id = ?', whereArgs: [id]);
  }
}
