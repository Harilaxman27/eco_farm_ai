import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class FinancialRecord {
  final int? id;
  final double seedCost;
  final double pestCost;
  final double laborCost;
  final double sellingPrice;
  final double fertilizerCost;
  final double irrigationCost;
  final double equipmentCost;
  final double transportCost;
  final double miscellaneousCost;
  final double totalExpenses;
  final double profitOrLoss;
  final double profitPercentage;
  final String date; // ISO 8601 format: YYYY-MM-DD
  final String season; // To categorize by season

  FinancialRecord({
    this.id,
    required this.seedCost,
    required this.pestCost,
    required this.laborCost,
    required this.sellingPrice,
    required this.fertilizerCost,
    required this.irrigationCost,
    required this.equipmentCost,
    required this.transportCost,
    required this.miscellaneousCost,
    required this.totalExpenses,
    required this.profitOrLoss,
    required this.profitPercentage,
    required this.date,
    required this.season,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seedCost': seedCost,
      'pestCost': pestCost,
      'laborCost': laborCost,
      'sellingPrice': sellingPrice,
      'fertilizerCost': fertilizerCost,
      'irrigationCost': irrigationCost,
      'equipmentCost': equipmentCost,
      'transportCost': transportCost,
      'miscellaneousCost': miscellaneousCost,
      'totalExpenses': totalExpenses,
      'profitOrLoss': profitOrLoss,
      'profitPercentage': profitPercentage,
      'date': date,
      'season': season,
    };
  }

  factory FinancialRecord.fromMap(Map<String, dynamic> map) {
    return FinancialRecord(
      id: map['id'],
      seedCost: map['seedCost'],
      pestCost: map['pestCost'],
      laborCost: map['laborCost'],
      sellingPrice: map['sellingPrice'],
      fertilizerCost: map['fertilizerCost'],
      irrigationCost: map['irrigationCost'],
      equipmentCost: map['equipmentCost'],
      transportCost: map['transportCost'],
      miscellaneousCost: map['miscellaneousCost'],
      totalExpenses: map['totalExpenses'],
      profitOrLoss: map['profitOrLoss'],
      profitPercentage: map['profitPercentage'],
      date: map['date'],
      season: map['season'],
    );
  }
}

class FarmerFinancialDbHelper {
  static final FarmerFinancialDbHelper instance = FarmerFinancialDbHelper._init();
  static Database? _database;

  FarmerFinancialDbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('farmer_financials.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE financial_records(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      seedCost REAL,
      pestCost REAL,
      laborCost REAL,
      sellingPrice REAL,
      fertilizerCost REAL,
      irrigationCost REAL,
      equipmentCost REAL,
      transportCost REAL,
      miscellaneousCost REAL,
      totalExpenses REAL,
      profitOrLoss REAL,
      profitPercentage REAL,
      date TEXT,
      season TEXT
    )
    ''');
  }

  Future<int> insert(FinancialRecord record) async {
    final db = await instance.database;
    return await db.insert('financial_records', record.toMap());
  }

  Future<List<FinancialRecord>> getAllRecords() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('financial_records');
    return List.generate(maps.length, (i) => FinancialRecord.fromMap(maps[i]));
  }

  Future<List<FinancialRecord>> getRecordsByDateRange(String startDate, String endDate) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'financial_records',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
    );
    return List.generate(maps.length, (i) => FinancialRecord.fromMap(maps[i]));
  }

  Future<List<FinancialRecord>> getRecordsBySeason(String season) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'financial_records',
      where: 'season = ?',
      whereArgs: [season],
    );
    return List.generate(maps.length, (i) => FinancialRecord.fromMap(maps[i]));
  }

  Future<Map<String, double>> getMonthlyAverages() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        substr(date, 1, 7) as month, 
        AVG(profitOrLoss) as avgProfit, 
        COUNT(*) as count
      FROM financial_records
      GROUP BY month
      ORDER BY month
    ''');

    Map<String, double> result = {};
    for (var map in maps) {
      result[map['month'] as String] = map['avgProfit'] as double;
    }
    return result;
  }

  Future<Map<String, double>> getSeasonalAverages() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        season, 
        AVG(profitOrLoss) as avgProfit, 
        COUNT(*) as count
      FROM financial_records
      GROUP BY season
    ''');

    Map<String, double> result = {};
    for (var map in maps) {
      result[map['season'] as String] = map['avgProfit'] as double;
    }
    return result;
  }

  Future<Map<String, double>> getYearlyAverages() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        substr(date, 1, 4) as year, 
        AVG(profitOrLoss) as avgProfit, 
        COUNT(*) as count
      FROM financial_records
      GROUP BY year
      ORDER BY year
    ''');

    Map<String, double> result = {};
    for (var map in maps) {
      result[map['year'] as String] = map['avgProfit'] as double;
    }
    return result;
  }

  String getSeason() {
    final now = DateTime.now();
    final month = now.month;

    // Simple seasonal determination - can be customized based on region
    if (month >= 3 && month <= 5) return 'Spring';
    if (month >= 6 && month <= 8) return 'Summer';
    if (month >= 9 && month <= 11) return 'Fall';
    return 'Winter';
  }
}