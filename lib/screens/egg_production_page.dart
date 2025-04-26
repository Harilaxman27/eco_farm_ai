import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eco_farm_ai/screens/db_helper.dart';
import 'package:eco_farm_ai/screens/egg_production.dart';
import 'package:fl_chart/fl_chart.dart';

class EggProductionPage extends StatefulWidget {
  const EggProductionPage({super.key});

  @override
  State<EggProductionPage> createState() => _EggProductionPageState();
}

class _EggProductionPageState extends State<EggProductionPage> {
  List<EggProduction> _history = [];
  int _selectedIndex = 0;
  String _selectedBatch = 'All';
  DateTimeRange? _selectedDateRange;
  String _selectedView = 'Daily';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // Load the history from the local database
  Future<void> _loadHistory() async {
    final data = await DBHelper.getEggProductions(); // Ensure this method is defined
    setState(() {
      _history = data.reversed.toList();
    });
  }

  // Method to add egg entry
  void _addEggEntry() {
    final _batchController = TextEditingController();
    final _quantityController = TextEditingController();
    String _selectedQuality = 'Large';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Add Egg Production", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _batchController,
                decoration: const InputDecoration(labelText: "Batch", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Quantity", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedQuality,
                decoration: const InputDecoration(labelText: "Egg Quality", border: OutlineInputBorder()),
                items: ['Large', 'Small', 'Cracked']
                    .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                    .toList(),
                onChanged: (val) => _selectedQuality = val!,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                child: const Text("Add Entry"),
                onPressed: () async {
                  if (_batchController.text.isEmpty || _quantityController.text.isEmpty) return;

                  final egg = EggProduction(
                    batch: _batchController.text,
                    quality: _selectedQuality,
                    quantity: int.tryParse(_quantityController.text) ?? 0,
                    date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  );
                  await DBHelper.insertEggProduction(egg); // Ensure this method exists
                  Navigator.pop(context);
                  _loadHistory();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Filter data based on batch and date range
  List<EggProduction> _filteredData() {
    return _history.where((e) {
      final matchesBatch = _selectedBatch == 'All' || e.batch == _selectedBatch;
      final matchesDate = _selectedDateRange == null ||
          (DateTime.parse(e.date).isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
              DateTime.parse(e.date).isBefore(_selectedDateRange!.end.add(const Duration(days: 1))));
      return matchesBatch && matchesDate;
    }).toList();
  }

  // Get egg quality counts for summary
  Map<String, int> _getQualityCounts(List<EggProduction> data) {
    final Map<String, int> counts = {'Large': 0, 'Small': 0, 'Cracked': 0};
    for (var entry in data) {
      counts[entry.quality] = counts[entry.quality]! + entry.quantity;
    }
    return counts;
  }

  // Build chart data
  List<BarChartGroupData> _buildChartData(List<EggProduction> data) {
    final Map<String, int> groupedData = {};

    for (var entry in data) {
      DateTime date = DateTime.parse(entry.date);
      String key;

      switch (_selectedView) {
        case 'Monthly':
          key = DateFormat('yyyy-MM').format(date);
          break;
        case 'Yearly':
          key = DateFormat('yyyy').format(date);
          break;
        default:
          key = entry.date;
      }

      groupedData.update(key, (value) => value + entry.quantity, ifAbsent: () => entry.quantity);
    }

    final keys = groupedData.keys.toList();
    return keys.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key.hashCode, // Ensure unique key representation for BarChartGroupData
        barRods: [BarChartRodData(toY: groupedData[keys[e.key]]!.toDouble(), color: Colors.orange)],
      );
    }).toList();
  }

  // Build the graph with table summary
  Widget _buildGraphWithTable() {
    final filtered = _filteredData();
    final chartData = _buildChartData(filtered);
    final qualityCounts = _getQualityCounts(filtered);

    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              DropdownButton<String>(
                value: _selectedView,
                items: ['Daily', 'Monthly', 'Yearly']
                    .map((view) => DropdownMenuItem(value: view, child: Text(view)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedView = value!),
              ),
              ElevatedButton(
                onPressed: () async {
                  DateTimeRange? picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2022),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _selectedDateRange = picked);
                },
                child: const Text("Select Date Range"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: BarChart(BarChartData(barGroups: chartData)),
          ),
          const SizedBox(height: 20),
          const Text("Egg Quality Summary", style: TextStyle(fontWeight: FontWeight.bold)),
          DataTable(columns: const [
            DataColumn(label: Text("Quality")),
            DataColumn(label: Text("Count")),
          ], rows: qualityCounts.entries
              .map((e) => DataRow(cells: [DataCell(Text(e.key)), DataCell(Text(e.value.toString()))]))
              .toList()),
        ],
      ),
    );
  }

  // Build history view
  Widget _buildHistory() {
    return ListView.builder(
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final entry = _history[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: ListTile(
            title: Text("Batch: ${entry.batch}"),
            subtitle: Text("Qty: ${entry.quantity} | ${entry.quality}\n${entry.date}"),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await DBHelper.deleteEggProduction(entry.id!); // Ensure this method exists
                _loadHistory();
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      Center(child: ElevatedButton(onPressed: _addEggEntry, child: const Text("Add Egg Production"))),
      _buildHistory(),
      _buildGraphWithTable(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Egg Production"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
        ],
        onTap: (index) => setState(() {
          _selectedIndex = index;
        }),
      ),
    );
  }
}
