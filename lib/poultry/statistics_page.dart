import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:eco_farm_ai/screens/broiler_models.dart';
import 'package:eco_farm_ai/screens/db_helper2.dart';
import 'package:intl/intl.dart';

class StatsPage extends StatefulWidget {
  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late Future<List<Broiler>> _hensFuture;
  String selectedRange = 'Daily';

  @override
  void initState() {
    super.initState();
    _loadHens();
  }

  void _loadHens() {
    _hensFuture = DBHelper2().getAllBroilers();
  }

  List<Broiler> _filterHensByDateRange(List<Broiler> hens) {
    final now = DateTime.now();
    final startDate = selectedRange == 'Daily'
        ? DateTime(now.year, now.month, now.day)
        : selectedRange == 'Monthly'
        ? DateTime(now.year, now.month)
        : DateTime(now.year);

    List<Broiler> filtered = [];

    for (var hen in hens) {
      try {
        final parsedDate = DateFormat('yyyy-MM-dd').parse(hen.date);
        if (parsedDate.isAfter(startDate) || parsedDate.isAtSameMomentAs(startDate)) {
          filtered.add(hen);
        }
      } catch (e) {
        print('❌ Date parse failed for ${hen.date}');
      }
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hen Statistics')),
      body: FutureBuilder<List<Broiler>>(
        future: _hensFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return Center(child: Text('No data available'));

          final filteredHens = _filterHensByDateRange(snapshot.data!);

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedRange = 'Daily';
                        });
                      },
                      child: Text('Daily'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedRange = 'Monthly';
                        });
                      },
                      child: Text('Monthly'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedRange = 'Yearly';
                        });
                      },
                      child: Text('Yearly'),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Expanded(
                  child: filteredHens.isEmpty
                      ? Center(child: Text('No data for selected $selectedRange'))
                      : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 200,
                          child: PieChart(PieChartData(
                            sections: _generatePieChartSections(filteredHens),
                          )),
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              titlesData: FlTitlesData(show: true),
                              borderData: FlBorderData(show: true),
                              barGroups: _generateBarChartData(filteredHens),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Text("Broiler Details", style: TextStyle(fontWeight: FontWeight.bold)),
                        _buildDataTable(filteredHens),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<PieChartSectionData> _generatePieChartSections(List<Broiler> hens) {
    final alive = hens.where((h) => h.status == 'alive').length;
    final dead = hens.where((h) => h.status == 'dead').length;

    return [
      PieChartSectionData(
        value: alive.toDouble(),
        color: Colors.green,
        title: 'Alive: $alive',
        radius: 50,
      ),
      PieChartSectionData(
        value: dead.toDouble(),
        color: Colors.red,
        title: 'Dead: $dead',
        radius: 50,
      ),
    ];
  }

  List<BarChartGroupData> _generateBarChartData(List<Broiler> hens) {
    final now = DateTime.now();

    int countByDay(DateTime date) =>
        hens.where((h) => DateFormat('yyyy-MM-dd').parse(h.date) == date).length;
    int countByMonth(int year, int month) =>
        hens.where((h) {
          final d = DateFormat('yyyy-MM-dd').parse(h.date);
          return d.year == year && d.month == month;
        }).length;
    int countByYear(int year) =>
        hens.where((h) => DateFormat('yyyy-MM-dd').parse(h.date).year == year).length;

    final today = countByDay(DateTime(now.year, now.month, now.day));
    final thisMonth = countByMonth(now.year, now.month);
    final thisYear = countByYear(now.year);

    return [
      BarChartGroupData(x: 0, barRods: [
        BarChartRodData(toY: today.toDouble(), color: Colors.blue)
      ]),
      BarChartGroupData(x: 1, barRods: [
        BarChartRodData(toY: thisMonth.toDouble(), color: Colors.orange)
      ]),
      BarChartGroupData(x: 2, barRods: [
        BarChartRodData(toY: thisYear.toDouble(), color: Colors.purple)
      ]),
    ];
  }

  Widget _buildDataTable(List<Broiler> hens) {
    return DataTable(
      columnSpacing: 10,
      columns: const [
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Breed')),
        DataColumn(label: Text('Weight')),
        DataColumn(label: Text('Health')),
      ],
      rows: hens.map((hen) {
        return DataRow(
          cells: [
            DataCell(Text(hen.name)),
            DataCell(Text(hen.breed)),
            DataCell(Text('${hen.currentWeight} kg')),
            DataCell(Text(hen.healthStatus)),
          ],
        );
      }).toList(),
    );
  }
}
