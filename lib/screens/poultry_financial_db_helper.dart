import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';

class PoultryFinancialRecord {
  final int? id;
  final String date;
  final double totalIncome;
  final double totalExpenses;
  final double profitLoss;
  final double profitMargin;
  final Map<String, double> incomeBreakdown;
  final Map<String, double> expenseBreakdown;
  final String notes;

  PoultryFinancialRecord({
    this.id,
    required this.date,
    required this.totalIncome,
    required this.totalExpenses,
    required this.profitLoss,
    required this.profitMargin,
    required this.incomeBreakdown,
    required this.expenseBreakdown,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'total_income': totalIncome,
      'total_expenses': totalExpenses,
      'profit_loss': profitLoss,
      'profit_margin': profitMargin,
      'income_breakdown': _mapToString(incomeBreakdown),
      'expense_breakdown': _mapToString(expenseBreakdown),
      'notes': notes,
    };
  }

  static PoultryFinancialRecord fromMap(Map<String, dynamic> map) {
    return PoultryFinancialRecord(
      id: map['id'],
      date: map['date'],
      totalIncome: map['total_income'],
      totalExpenses: map['total_expenses'],
      profitLoss: map['profit_loss'],
      profitMargin: map['profit_margin'],
      incomeBreakdown: _stringToMap(map['income_breakdown']),
      expenseBreakdown: _stringToMap(map['expense_breakdown']),
      notes: map['notes'],
    );
  }

  static String _mapToString(Map<String, double> map) {
    return map.entries.map((e) => '${e.key}:${e.value}').join(',');
  }

  static Map<String, double> _stringToMap(String str) {
    if (str.isEmpty) return {};

    final map = <String, double>{};
    final pairs = str.split(',');

    for (var pair in pairs) {
      final keyValue = pair.split(':');
      if (keyValue.length == 2) {
        map[keyValue[0]] = double.tryParse(keyValue[1]) ?? 0.0;
      }
    }

    return map;
  }
}

class PoultryFinancialDbHelper {
  static final PoultryFinancialDbHelper instance = PoultryFinancialDbHelper._init();
  static Database? _database;

  PoultryFinancialDbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('poultry_financial.db');
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
      CREATE TABLE poultry_financials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        total_income REAL NOT NULL,
        total_expenses REAL NOT NULL,
        profit_loss REAL NOT NULL,
        profit_margin REAL NOT NULL,
        income_breakdown TEXT NOT NULL,
        expense_breakdown TEXT NOT NULL,
        notes TEXT
      )
    ''');
  }

  Future<int> insertRecord(PoultryFinancialRecord record) async {
    final db = await instance.database;
    return await db.insert('poultry_financials', record.toMap());
  }

  Future<List<PoultryFinancialRecord>> getAllRecords() async {
    final db = await instance.database;
    final records = await db.query('poultry_financials', orderBy: 'date DESC');
    return records.map((e) => PoultryFinancialRecord.fromMap(e)).toList();
  }

  Future<List<PoultryFinancialRecord>> getRecordsByDateRange(String startDate, String endDate) async {
    final db = await instance.database;
    final records = await db.query(
      'poultry_financials',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
    return records.map((e) => PoultryFinancialRecord.fromMap(e)).toList();
  }

  Future<Map<String, double>> getMonthlyProfitLoss(int year) async {
    final db = await instance.database;
    final result = <String, double>{};

    for (int month = 1; month <= 12; month++) {
      final String monthStr = month < 10 ? '0$month' : '$month';
      final String startDate = '$year-$monthStr-01';
      final String endDate = month < 12
          ? '$year-${month < 9 ? '0${month+1}' : '${month+1}'}-01'
          : '${year+1}-01-01';

      final List<Map<String, dynamic>> records = await db.query(
        'poultry_financials',
        where: 'date >= ? AND date < ?',
        whereArgs: [startDate, endDate],
      );

      double totalProfitLoss = 0;
      for (var record in records) {
        totalProfitLoss += record['profit_loss'] as double;
      }

      result['$year-$monthStr'] = totalProfitLoss;
    }

    return result;
  }

  Future<Map<String, double>> getQuarterlyProfitLoss(int year) async {
    final Map<String, double> result = {};
    final quarters = [
      {'name': 'Q1', 'start': '$year-01-01', 'end': '$year-03-31'},
      {'name': 'Q2', 'start': '$year-04-01', 'end': '$year-06-30'},
      {'name': 'Q3', 'start': '$year-07-01', 'end': '$year-09-30'},
      {'name': 'Q4', 'start': '$year-10-01', 'end': '$year-12-31'},
    ];

    for (var quarter in quarters) {
      final records = await getRecordsByDateRange(
        quarter['start']!,
        quarter['end']!,
      );

      double totalProfitLoss = 0;
      for (var record in records) {
        totalProfitLoss += record.profitLoss;
      }

      result['${quarter['name']}'] = totalProfitLoss;
    }

    return result;
  }

  Future<double> getAverageProfitLoss(String period) async {
    // period can be 'monthly', 'quarterly', or 'yearly'
    final db = await instance.database;
    final records = await db.query('poultry_financials');

    if (records.isEmpty) return 0;

    final totalProfitLoss = records.fold<double>(
        0, (sum, record) => sum + (record['profit_loss'] as double));

    switch (period) {
      case 'monthly':
      // Group by month and calculate average
        final Map<String, List<double>> monthlyData = {};
        for (var record in records) {
          final date = record['date'] as String;
          final month = date.substring(0, 7); // YYYY-MM format
          monthlyData[month] = monthlyData[month] ?? [];
          monthlyData[month]!.add(record['profit_loss'] as double);
        }

        double sum = 0;
        for (var profits in monthlyData.values) {
          sum += profits.reduce((a, b) => a + b) / profits.length;
        }

        return monthlyData.isEmpty ? 0 : sum / monthlyData.length;

      case 'quarterly':
      // Simplify by returning average profit/loss per record
        return totalProfitLoss / records.length;

      case 'yearly':
        final Map<String, List<double>> yearlyData = {};
        for (var record in records) {
          final date = record['date'] as String;
          final year = date.substring(0, 4); // YYYY format
          yearlyData[year] = yearlyData[year] ?? [];
          yearlyData[year]!.add(record['profit_loss'] as double);
        }

        double sum = 0;
        for (var profits in yearlyData.values) {
          sum += profits.reduce((a, b) => a + b);
        }

        return yearlyData.isEmpty ? 0 : sum / yearlyData.length;

      default:
        return totalProfitLoss / records.length;
    }
  }

  Future<void> deleteRecord(int id) async {
    final db = await instance.database;
    await db.delete(
      'poultry_financials',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateRecord(PoultryFinancialRecord record) async {
    final db = await instance.database;
    await db.update(
      'poultry_financials',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}