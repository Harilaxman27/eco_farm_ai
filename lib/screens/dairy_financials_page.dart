import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dairy_financial_db_helper.dart';

class DairyFinancialsPage extends StatefulWidget {
  const DairyFinancialsPage({Key? key}) : super(key: key);

  @override
  _DairyFinancialsPageState createState() => _DairyFinancialsPageState();
}

class _DairyFinancialsPageState extends State<DairyFinancialsPage> {
  final TextEditingController _feedingController = TextEditingController();
  final TextEditingController _veterinaryController = TextEditingController();
  final TextEditingController _laborController = TextEditingController();
  final TextEditingController _equipmentController = TextEditingController();
  final TextEditingController _transportController = TextEditingController();
  final TextEditingController _miscellaneousController = TextEditingController();
  final TextEditingController _housingMaintenanceController = TextEditingController();
  final TextEditingController _milkRevenueController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final DairyFinancialDBHelper dbHelper = DairyFinancialDBHelper();
  List<DairyFinancialRecord> records = [];

  // Financial summary values
  double _totalExpenses = 0.0;
  double _totalRevenue = 0.0;
  double _profitOrLoss = 0.0;
  double _profitPercentage = 0.0;

  // Time period
  String _selectedPeriod = 'Monthly';
  final List<String> _periods = ['Daily', 'Weekly', 'Monthly', 'Yearly'];

  @override
  void initState() {
    super.initState();
    _loadRecords();

    // Add listeners to controllers for real-time calculations
    _feedingController.addListener(_updateCalculations);
    _veterinaryController.addListener(_updateCalculations);
    _laborController.addListener(_updateCalculations);
    _equipmentController.addListener(_updateCalculations);
    _transportController.addListener(_updateCalculations);
    _miscellaneousController.addListener(_updateCalculations);
    _housingMaintenanceController.addListener(_updateCalculations);
    _milkRevenueController.addListener(_updateCalculations);
  }

  @override
  void dispose() {
    // Dispose controllers
    _feedingController.dispose();
    _veterinaryController.dispose();
    _laborController.dispose();
    _equipmentController.dispose();
    _transportController.dispose();
    _miscellaneousController.dispose();
    _housingMaintenanceController.dispose();
    _milkRevenueController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    final data = await dbHelper.getRecords();
    setState(() {
      records = data;
    });
  }

  void _updateCalculations() {
    final double feedingCost = double.tryParse(_feedingController.text) ?? 0;
    final double veterinaryCost = double.tryParse(_veterinaryController.text) ?? 0;
    final double laborCost = double.tryParse(_laborController.text) ?? 0;
    final double equipmentCost = double.tryParse(_equipmentController.text) ?? 0;
    final double transportCost = double.tryParse(_transportController.text) ?? 0;
    final double miscellaneousCost = double.tryParse(_miscellaneousController.text) ?? 0;
    final double housingMaintenanceCost = double.tryParse(_housingMaintenanceController.text) ?? 0;
    final double milkRevenue = double.tryParse(_milkRevenueController.text) ?? 0;

    double totalExpenses = feedingCost + veterinaryCost + laborCost + equipmentCost + transportCost + miscellaneousCost + housingMaintenanceCost;
    double profitOrLoss = milkRevenue - totalExpenses;
    double profitPercentage = totalExpenses == 0 ? 0 : (profitOrLoss / totalExpenses) * 100;

    setState(() {
      _totalExpenses = totalExpenses;
      _totalRevenue = milkRevenue;
      _profitOrLoss = profitOrLoss;
      _profitPercentage = profitPercentage;
    });
  }

  void _calculateFinancials() async {
    if (_formKey.currentState!.validate()) {
      final double feedingCost = double.tryParse(_feedingController.text) ?? 0;
      final double veterinaryCost = double.tryParse(_veterinaryController.text) ?? 0;
      final double laborCost = double.tryParse(_laborController.text) ?? 0;
      final double equipmentCost = double.tryParse(_equipmentController.text) ?? 0;
      final double transportCost = double.tryParse(_transportController.text) ?? 0;
      final double miscellaneousCost = double.tryParse(_miscellaneousController.text) ?? 0;
      final double housingMaintenanceCost = double.tryParse(_housingMaintenanceController.text) ?? 0;
      final double milkRevenue = double.tryParse(_milkRevenueController.text) ?? 0;

      double totalExpenses = feedingCost + veterinaryCost + laborCost + equipmentCost + transportCost + miscellaneousCost + housingMaintenanceCost;
      double profitOrLoss = milkRevenue - totalExpenses;
      double profitPercentage = totalExpenses == 0 ? 0 : (profitOrLoss / totalExpenses) * 100;

      final now = DateTime.now();
      final dateString = DateFormat('yyyy-MM-dd').format(now);
      final month = now.month;
      final season = (month >= 3 && month <= 5)
          ? 'Spring'
          : (month >= 6 && month <= 8)
          ? 'Summer'
          : (month >= 9 && month <= 11)
          ? 'Autumn'
          : 'Winter';

      final financialRecord = DairyFinancialRecord(
        feedingCost: feedingCost,
        veterinaryCost: veterinaryCost,
        laborCost: laborCost,
        equipmentCost: equipmentCost,
        transportCost: transportCost,
        miscellaneousCost: miscellaneousCost,
        housingMaintenanceCost: housingMaintenanceCost,
        milkRevenue: milkRevenue,
        totalExpenses: totalExpenses,
        profitOrLoss: profitOrLoss,
        profitPercentage: profitPercentage,
        date: dateString,
        season: season,
      );

      await dbHelper.insertRecord(financialRecord);
      _clearFields();
      _loadRecords();

      // Hide keyboard
      FocusScope.of(context).unfocus();
    }
  }

  void _clearFields() {
    _feedingController.clear();
    _veterinaryController.clear();
    _laborController.clear();
    _equipmentController.clear();
    _transportController.clear();
    _miscellaneousController.clear();
    _housingMaintenanceController.clear();
    _milkRevenueController.clear();

    setState(() {
      _totalExpenses = 0.0;
      _totalRevenue = 0.0;
      _profitOrLoss = 0.0;
      _profitPercentage = 0.0;
    });
  }

  Future<void> _deleteRecord(int id) async {
    await dbHelper.deleteRecord(id);
    _loadRecords();
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Dairy Farm Financial Tracker',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _clearFields,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFinancialSummary(),
            _buildPeriodSelector(),
            _buildInputForm(),
            _buildRecordsList(),
          ],
        ),
      ),
      bottomNavigationBar: _buildCalculateButton(),
    );
  }

  Widget _buildFinancialSummary() {
    Color profitLossColor = _profitOrLoss >= 0 ? Colors.green.shade700 : Colors.red.shade700;
    IconData profitLossIcon = _profitOrLoss >= 0 ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade700,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Financial Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _summaryCard(
                      title: 'Total Income',
                      value: _formatCurrency(_totalRevenue),
                      icon: Icons.account_balance_wallet,
                      color: Colors.blue.shade700,
                    ),
                    _summaryCard(
                      title: 'Total Expenses',
                      value: _formatCurrency(_totalExpenses),
                      icon: Icons.receipt_long,
                      color: Colors.orange.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _profitOrLoss >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(profitLossIcon, color: profitLossColor),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _profitOrLoss >= 0 ? 'Profit' : 'Loss',
                                style: TextStyle(
                                  color: profitLossColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    _formatCurrency(_profitOrLoss.abs()),
                                    style: TextStyle(
                                      color: profitLossColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _profitOrLoss >= 0 ? Colors.green.shade200 : Colors.red.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_profitPercentage.abs().toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 80,
                  child: CustomPaint(
                    painter: _ProfitLossChart(
                      profitLoss: _profitOrLoss,
                      totalIncome: _totalRevenue,
                      totalExpenses: _totalExpenses,
                    ),
                    size: const Size(double.infinity, 80),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Time Period:',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
          DropdownButton<String>(
            value: _selectedPeriod,
            icon: const Icon(Icons.keyboard_arrow_down),
            underline: Container(),
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedPeriod = newValue;
                });
              }
            },
            items: _periods.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputForm() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Income Sources', Icons.account_balance_wallet, Colors.green.shade700),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _milkRevenueController,
              labelText: 'Milk Revenue (₹)',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.water_drop,
              isRequired: true,
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Expenses', Icons.money_off, Colors.red.shade700),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _feedingController,
              labelText: 'Feeding Cost (₹)',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.grass,
              isRequired: true,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _veterinaryController,
              labelText: 'Veterinary Cost (₹)',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.medical_services,
              isRequired: true,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _laborController,
              labelText: 'Labor Cost (₹)',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.people,
              isRequired: true,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _equipmentController,
              labelText: 'Equipment Cost (₹)',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.build,
              isRequired: true,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _transportController,
              labelText: 'Transport Cost (₹)',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.local_shipping,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _housingMaintenanceController,
              labelText: 'Housing Maintenance Cost (₹)',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.home,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _miscellaneousController,
              labelText: 'Miscellaneous Cost (₹)',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.description,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade700),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: isRequired ? (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a value';
        }
        return null;
      } : null,
    );
  }

  Widget _buildRecordsList() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Saved Records',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          records.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'No records found. Add your first financial record.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: record.profitOrLoss >= 0 ? Colors.green.shade100 : Colors.red.shade100,
                      child: Icon(
                        record.profitOrLoss >= 0 ? Icons.trending_up : Icons.trending_down,
                        color: record.profitOrLoss >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                    title: Text(
                      'Date: ${record.date} | Season: ${record.season}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Income: ${_formatCurrency(record.milkRevenue)}'),
                        Text('Expenses: ${_formatCurrency(record.totalExpenses)}'),
                        Text(
                          record.profitOrLoss >= 0
                              ? 'Profit: ${_formatCurrency(record.profitOrLoss)}'
                              : 'Loss: ${_formatCurrency(record.profitOrLoss.abs())}',
                          style: TextStyle(
                            color: record.profitOrLoss >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteRecord(record.id!),
                    ),
                    isThreeLine: true,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalculateButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _calculateFinancials,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Save Financial Record',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// Custom painter for financial chart
class _ProfitLossChart extends CustomPainter {
  final double profitLoss;
  final double totalIncome;
  final double totalExpenses;

  _ProfitLossChart({
    required this.profitLoss,
    required this.totalIncome,
    required this.totalExpenses,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Skip painting if no data
    if (totalIncome == 0 && totalExpenses == 0) return;

    final double barHeight = size.height * 0.6;
    final double barWidth = size.width * 0.8;
    final double startX = size.width * 0.1;
    final double centerY = size.height / 2;

    // Paint for income bar
    final incomePaint = Paint()
      ..color = Colors.blue.shade200
      ..style = PaintingStyle.fill;

    // Paint for expense bar
    final expensePaint = Paint()
      ..color = Colors.orange.shade200
      ..style = PaintingStyle.fill;

    // Paint for profit/loss indicator
    final profitLossPaint = Paint()
      ..color = profitLoss >= 0 ? Colors.green.shade700 : Colors.red.shade700
      ..style = PaintingStyle.fill;

    // Find the max value for scaling
    final maxValue = math.max(totalIncome, totalExpenses);

    if (maxValue > 0) {
      // Draw income bar
      final incomeWidth = (totalIncome / maxValue) * barWidth;
      final incomeRect = Rect.fromLTWH(
        startX,
        centerY - barHeight - 5,
        incomeWidth,
        barHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(incomeRect, const Radius.circular(6)),
        incomePaint,
      );

      // Draw expense bar
      final expenseWidth = (totalExpenses / maxValue) * barWidth;
      final expenseRect = Rect.fromLTWH(
        startX,
        centerY + 5,
        expenseWidth,
        barHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(expenseRect, const Radius.circular(6)),
        expensePaint,
      );

      // Draw profit/loss indicator
      if (profitLoss != 0) {
        final indicatorWidth = (profitLoss.abs() / maxValue) * barWidth;
        final indicatorRect = Rect.fromLTWH(
          profitLoss > 0 ? startX + expenseWidth : startX + incomeWidth - indicatorWidth,
          centerY - 3,
          indicatorWidth,
          6,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(indicatorRect, const Radius.circular(3)),
          profitLossPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}