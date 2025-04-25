import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Add this dependency to pubspec.yaml
import 'package:intl/intl.dart'; // Add this dependency for date formatting
import 'farmer_financial_db_helper.dart'; // The file we just created

class FinancialsPage extends StatefulWidget {
  @override
  _FinancialsPageState createState() => _FinancialsPageState();
}

class _FinancialsPageState extends State<FinancialsPage> with SingleTickerProviderStateMixin {
  // Controllers for the input fields
  final TextEditingController _seedController = TextEditingController();
  final TextEditingController _pestController = TextEditingController();
  final TextEditingController _laborController = TextEditingController();
  final TextEditingController _sellingController = TextEditingController();
  final TextEditingController _fertilizerController = TextEditingController();
  final TextEditingController _irrigationController = TextEditingController();
  final TextEditingController _equipmentController = TextEditingController();
  final TextEditingController _transportController = TextEditingController();
  final TextEditingController _miscellaneousController = TextEditingController();

  // Tab controller for analytics views
  late TabController _tabController;

  // Variables for the result
  String _result = '';
  double _profitOrLoss = 0;
  double _profitPercentage = 0;
  Color _resultColor = Colors.green;

  // Data for charts
  Map<String, double> _monthlyData = {};
  Map<String, double> _seasonalData = {};
  Map<String, double> _yearlyData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _seedController.dispose();
    _pestController.dispose();
    _laborController.dispose();
    _sellingController.dispose();
    _fertilizerController.dispose();
    _irrigationController.dispose();
    _equipmentController.dispose();
    _transportController.dispose();
    _miscellaneousController.dispose();
    super.dispose();
  }

  // Function to load analytics data from database
  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });

    // Load data for each time period
    _monthlyData = await FarmerFinancialDbHelper.instance.getMonthlyAverages();
    _seasonalData = await FarmerFinancialDbHelper.instance.getSeasonalAverages();
    _yearlyData = await FarmerFinancialDbHelper.instance.getYearlyAverages();

    setState(() {
      _isLoading = false;
    });
  }

  // Function to calculate profit/loss
  void _calculateFinancials() async {
    final double seedCost = double.tryParse(_seedController.text) ?? 0;
    final double pestCost = double.tryParse(_pestController.text) ?? 0;
    final double laborCost = double.tryParse(_laborController.text) ?? 0;
    final double sellingCost = double.tryParse(_sellingController.text) ?? 0;
    final double fertilizerCost = double.tryParse(_fertilizerController.text) ?? 0;
    final double irrigationCost = double.tryParse(_irrigationController.text) ?? 0;
    final double equipmentCost = double.tryParse(_equipmentController.text) ?? 0;
    final double transportCost = double.tryParse(_transportController.text) ?? 0;
    final double miscellaneousCost = double.tryParse(_miscellaneousController.text) ?? 0;

    // Calculate total expenses
    double totalExpenses = seedCost + pestCost + laborCost + fertilizerCost +
        irrigationCost + equipmentCost + transportCost + miscellaneousCost;

    // Calculate profit or loss
    double profitOrLoss = sellingCost - totalExpenses;

    // Calculate profit percentage
    double profitPercentage = 0;
    if (totalExpenses != 0) {
      profitPercentage = (profitOrLoss / totalExpenses) * 100;
    }

    // Set result and colors
    setState(() {
      _profitOrLoss = profitOrLoss;
      _profitPercentage = profitPercentage;
      if (profitOrLoss >= 0) {
        _result = 'Profit: ₹${profitOrLoss.toStringAsFixed(2)} (${profitPercentage.toStringAsFixed(2)}%)';
        _resultColor = Colors.green;
      } else {
        _result = 'Loss: ₹${profitOrLoss.toStringAsFixed(2)} (${profitPercentage.toStringAsFixed(2)}%)';
        _resultColor = Colors.red;
      }
    });

    // Save to database
    final today = DateTime.now();
    final dateString = DateFormat('yyyy-MM-dd').format(today);
    final currentSeason = FarmerFinancialDbHelper.instance.getSeason();

    final financialRecord = FinancialRecord(
      seedCost: seedCost,
      pestCost: pestCost,
      laborCost: laborCost,
      sellingPrice: sellingCost,
      fertilizerCost: fertilizerCost,
      irrigationCost: irrigationCost,
      equipmentCost: equipmentCost,
      transportCost: transportCost,
      miscellaneousCost: miscellaneousCost,
      totalExpenses: totalExpenses,
      profitOrLoss: profitOrLoss,
      profitPercentage: profitPercentage,
      date: dateString,
      season: currentSeason,
    );

    await FarmerFinancialDbHelper.instance.insert(financialRecord);

    // Reload analytics data after saving
    _loadAnalyticsData();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Financial record saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Financials"),
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Calculator'),
            Tab(text: 'Monthly'),
            Tab(text: 'Seasonal'),
            Tab(text: 'Yearly'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Financial Calculator
          _buildCalculatorTab(),

          // Tab 2: Monthly Analysis
          _buildChartTab(_monthlyData, 'Monthly Profit/Loss Analysis'),

          // Tab 3: Seasonal Analysis
          _buildChartTab(_seasonalData, 'Seasonal Profit/Loss Analysis'),

          // Tab 4: Yearly Analysis
          _buildChartTab(_yearlyData, 'Yearly Profit/Loss Analysis'),
        ],
      ),
    );
  }

  // Calculator tab
  Widget _buildCalculatorTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input fields for expenses and income
            _buildInputField('Seed Cost', _seedController),
            _buildInputField('Pesticide Cost', _pestController),
            _buildInputField('Labor Cost', _laborController),
            _buildInputField('Selling Price (Income)', _sellingController),
            _buildInputField('Fertilizer Cost', _fertilizerController),
            _buildInputField('Irrigation Cost', _irrigationController),
            _buildInputField('Equipment Rental/Maintenance', _equipmentController),
            _buildInputField('Transport Cost', _transportController),
            _buildInputField('Miscellaneous', _miscellaneousController),

            // Calculate button
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _calculateFinancials,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Calculate & Save Profit/Loss'),
              ),
            ),

            // Display result
            SizedBox(height: 20),
            Center(
              child: Text(
                _result,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _resultColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Chart tab
  Widget _buildChartTab(Map<String, double> data, String title) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No data available yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Calculate and save financial records first',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxValue(data) * 1.2, // Add 20% margin at top
                minY: _getMinValue(data) * 1.2, // Add 20% margin at bottom (for negative values)
                barGroups: _getBarGroups(data),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < data.keys.length) {
                          String label = data.keys.elementAt(value.toInt());
                          // Shorten the label if needed
                          if (title.contains('Monthly')) {
                            // Convert "2023-05" to "May"
                            try {
                              final parts = label.split('-');
                              final month = int.parse(parts[1]);
                              label = DateFormat('MMM').format(DateTime(2023, month));
                            } catch (e) {}
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              label,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          );
                        }
                        return SizedBox();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            '₹${value.toInt()}',
                            style: TextStyle(fontSize: 10),
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.grey),
                    bottom: BorderSide(color: Colors.grey),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: _getGridInterval(data),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          _buildAnalyticsSummary(data, title),
        ],
      ),
    );
  }

  // Helper for the chart: get grid interval
  double _getGridInterval(Map<String, double> data) {
    double max = _getMaxValue(data);
    double min = _getMinValue(data);
    double range = max - min;
    if (range <= 1000) return 100;
    if (range <= 10000) return 1000;
    return 5000;
  }

  // Helper for the chart: get max value
  double _getMaxValue(Map<String, double> data) {
    if (data.isEmpty) return 100;
    double max = data.values.reduce((a, b) => a > b ? a : b);
    return max > 0 ? max : 100;
  }

  // Helper for the chart: get min value
  double _getMinValue(Map<String, double> data) {
    if (data.isEmpty) return -100;
    double min = data.values.reduce((a, b) => a < b ? a : b);
    return min < 0 ? min : -100;
  }

  // Helper for the chart: generate bar groups
  List<BarChartGroupData> _getBarGroups(Map<String, double> data) {
    return List.generate(data.length, (index) {
      final key = data.keys.elementAt(index);
      final value = data[key] ?? 0;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: value >= 0 ? Colors.green : Colors.red,
            width: 22,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(6),
              bottom: value < 0 ? Radius.circular(6) : Radius.zero,
            ),
          ),
        ],
      );
    });
  }

  // Analytics summary widget
  Widget _buildAnalyticsSummary(Map<String, double> data, String title) {
    if (data.isEmpty) return SizedBox();

    // Calculate average profit/loss
    double total = data.values.reduce((a, b) => a + b);
    double average = total / data.length;

    // Calculate best and worst periods
    MapEntry<String, double> bestPeriod = data.entries.reduce((a, b) => a.value > b.value ? a : b);
    MapEntry<String, double> worstPeriod = data.entries.reduce((a, b) => a.value < b.value ? a : b);

    String periodLabel = 'Period';
    if (title.contains('Monthly')) periodLabel = 'Month';
    if (title.contains('Seasonal')) periodLabel = 'Season';
    if (title.contains('Yearly')) periodLabel = 'Year';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text('Average: ₹${average.toStringAsFixed(2)}',
                style: TextStyle(color: average >= 0 ? Colors.green : Colors.red)),
            SizedBox(height: 4),
            Text('Best $periodLabel: ${bestPeriod.key} (₹${bestPeriod.value.toStringAsFixed(2)})',
                style: TextStyle(color: Colors.green)),
            SizedBox(height: 4),
            Text('Worst $periodLabel: ${worstPeriod.key} (₹${worstPeriod.value.toStringAsFixed(2)})',
                style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  // Helper widget to build each input field
  Widget _buildInputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.green.shade300),
          ),
          prefixText: '₹',
        ),
      ),
    );
  }
}