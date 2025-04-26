import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class FinancialsPoultryPage extends StatefulWidget {
  const FinancialsPoultryPage({Key? key}) : super(key: key);

  @override
  State<FinancialsPoultryPage> createState() => _FinancialsPoultryPageState();
}

class _FinancialsPoultryPageState extends State<FinancialsPoultryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  // Income fields
  final TextEditingController _eggQuantityController = TextEditingController();
  final TextEditingController _eggPriceController = TextEditingController();
  final TextEditingController _broilerWeightController = TextEditingController();
  final TextEditingController _broilerPriceController = TextEditingController();
  final TextEditingController _culledBirdsIncomeController = TextEditingController();
  final TextEditingController _otherIncomeController = TextEditingController();

  // Expense fields
  final TextEditingController _feedCostController = TextEditingController();
  final TextEditingController _chickPurchaseController = TextEditingController();
  final TextEditingController _medicineController = TextEditingController();
  final TextEditingController _laborCostController = TextEditingController();
  final TextEditingController _utilitiesController = TextEditingController();
  final TextEditingController _equipmentController = TextEditingController();
  final TextEditingController _miscExpensesController = TextEditingController();

  // Financial summary
  double totalIncome = 0;
  double totalExpenses = 0;
  double profitLoss = 0;
  double profitMargin = 0;
  bool isProfit = true;
  bool hasCalculated = false;
  List<FinancialItem> incomeBreakdown = [];
  List<FinancialItem> expenseBreakdown = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Dispose all controllers
    _eggQuantityController.dispose();
    _eggPriceController.dispose();
    _broilerWeightController.dispose();
    _broilerPriceController.dispose();
    _culledBirdsIncomeController.dispose();
    _otherIncomeController.dispose();
    _feedCostController.dispose();
    _chickPurchaseController.dispose();
    _medicineController.dispose();
    _laborCostController.dispose();
    _utilitiesController.dispose();
    _equipmentController.dispose();
    _miscExpensesController.dispose();
    super.dispose();
  }

  void _calculateFinancials() {
    if (!_formKey.currentState!.validate()) return;

    // Parse Income
    double eggIncome = _parseDouble(_eggQuantityController.text) * _parseDouble(_eggPriceController.text);
    double broilerIncome = _parseDouble(_broilerWeightController.text) * _parseDouble(_broilerPriceController.text);
    double culledIncome = _parseDouble(_culledBirdsIncomeController.text);
    double otherIncome = _parseDouble(_otherIncomeController.text);

    // Parse Expenses
    double feedCost = _parseDouble(_feedCostController.text);
    double chickCost = _parseDouble(_chickPurchaseController.text);
    double medicineCost = _parseDouble(_medicineController.text);
    double laborCost = _parseDouble(_laborCostController.text);
    double utilitiesCost = _parseDouble(_utilitiesController.text);
    double equipmentCost = _parseDouble(_equipmentController.text);
    double miscCost = _parseDouble(_miscExpensesController.text);

    // Calculate totals
    setState(() {
      totalIncome = eggIncome + broilerIncome + culledIncome + otherIncome;
      totalExpenses = feedCost + chickCost + medicineCost + laborCost + utilitiesCost + equipmentCost + miscCost;
      profitLoss = totalIncome - totalExpenses;
      isProfit = profitLoss >= 0;
      profitMargin = totalIncome > 0 ? (profitLoss / totalIncome) * 100 : 0;
      hasCalculated = true;

      // Create breakdown for pie charts
      incomeBreakdown = [
        FinancialItem("Egg Sales", eggIncome, Colors.amber),
        FinancialItem("Broiler Sales", broilerIncome, Colors.orange),
        FinancialItem("Culled Birds", culledIncome, Colors.deepOrange),
        FinancialItem("Other Income", otherIncome, Colors.red),
      ];

      expenseBreakdown = [
        FinancialItem("Feed", feedCost, Colors.blue),
        FinancialItem("Chicks", chickCost, Colors.indigo),
        FinancialItem("Medicine", medicineCost, Colors.purple),
        FinancialItem("Labor", laborCost, Colors.pink),
        FinancialItem("Utilities", utilitiesCost, Colors.teal),
        FinancialItem("Equipment", equipmentCost, Colors.cyan),
        FinancialItem("Misc.", miscCost, Colors.lightBlue),
      ];

      // Move to results tab
      _tabController.animateTo(1);
    });
  }

  double _parseDouble(String? value) {
    if (value == null || value.isEmpty) return 0;
    return double.tryParse(value) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Analytics'),
        backgroundColor: Colors.green[700],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'INPUT DATA', icon: Icon(Icons.edit)),
            Tab(text: 'SUMMARY', icon: Icon(Icons.bar_chart)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInputForm(),
          _buildFinancialSummary(),
        ],
      ),
    );
  }

  Widget _buildInputForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Income Sources', Icons.arrow_upward, Colors.green),
          const SizedBox(height: 16),

          _buildIncomeSources(),

          const SizedBox(height: 24),
          _buildSectionTitle('Expenses', Icons.arrow_downward, Colors.red),
          const SizedBox(height: 16),

          _buildExpenses(),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _calculateFinancials,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'CALCULATE PROFIT/LOSS',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              // Reset all form fields
              _formKey.currentState!.reset();
            },
            child: const Text('Clear All Fields'),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeSources() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Egg Sales
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _eggQuantityController,
                    'Egg Quantity',
                    'Number of eggs',
                    Icons.egg_outlined,
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    _eggPriceController,
                    'Price per Egg',
                    '\$ per egg',
                    Icons.attach_money,
                    isNumber: true,
                    isCurrency: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Broiler Sales
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _broilerWeightController,
                    'Broiler Weight (kg)',
                    'Total kg sold',
                    Icons.monitor_weight_outlined,
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    _broilerPriceController,
                    'Price per kg',
                    '\$ per kg',
                    Icons.attach_money,
                    isNumber: true,
                    isCurrency: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Other Income
            _buildTextField(
              _culledBirdsIncomeController,
              'Culled Birds Income',
              'Total income from culled birds',
              Icons.money,
              isNumber: true,
              isCurrency: true,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              _otherIncomeController,
              'Other Income',
              'Manure sales, etc.',
              Icons.monetization_on_outlined,
              isNumber: true,
              isCurrency: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenses() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField(
              _feedCostController,
              'Feed Cost',
              'Total cost of feed',
              Icons.fastfood_outlined,
              isNumber: true,
              isCurrency: true,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              _chickPurchaseController,
              'Chick Purchase',
              'Cost of buying chicks/pullets',
              Icons.pets_outlined,
              isNumber: true,
              isCurrency: true,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              _medicineController,
              'Vaccines & Medicine',
              'Total health care costs',
              Icons.medical_services_outlined,
              isNumber: true,
              isCurrency: true,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _laborCostController,
                    'Labor Cost',
                    'Wages paid',
                    Icons.people_outline,
                    isNumber: true,
                    isCurrency: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    _utilitiesController,
                    'Utilities',
                    'Electricity, water, etc.',
                    Icons.lightbulb_outline,
                    isNumber: true,
                    isCurrency: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _equipmentController,
                    'Equipment',
                    'Maintenance, repairs',
                    Icons.build_outlined,
                    isNumber: true,
                    isCurrency: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    _miscExpensesController,
                    'Miscellaneous',
                    'Other expenses',
                    Icons.category_outlined,
                    isNumber: true,
                    isCurrency: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      String hint,
      IconData icon, {
        bool isNumber = false,
        bool isCurrency = false,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.green[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      validator: isNumber
          ? (value) {
        if (value != null && value.isNotEmpty) {
          if (double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
        }
        return null;
      }
          : null,
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialSummary() {
    if (!hasCalculated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calculate_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Enter financial data and calculate to see results',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () {
                _tabController.animateTo(0);
              },
              icon: const Icon(Icons.edit),
              label: const Text('Go to Input Form'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Main financial summary card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Financial Summary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 20),

                // Profit/Loss indicator
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isProfit ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isProfit ? 'PROFIT' : 'LOSS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isProfit ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                      Text(
                        currencyFormat.format(profitLoss.abs()),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isProfit ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Profit margin
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Profit Margin:',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${profitMargin.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isProfit ? Colors.green[800] : Colors.red[800],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Income & Expenses
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Income:',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      currencyFormat.format(totalIncome),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Expenses:',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      currencyFormat.format(totalExpenses),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Charts section
        _buildSectionTitle('Breakdown Analysis', Icons.pie_chart, Colors.blue),
        const SizedBox(height: 16),

        // Income breakdown pie chart
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Income Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                totalIncome > 0 ?
                SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: PieChart(
                          PieChartData(
                            sections: _getIncomePieSections(),
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildChartLegend(incomeBreakdown),
                      ),
                    ],
                  ),
                ) :
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No income data to display'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Expense breakdown pie chart
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Expense Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                totalExpenses > 0 ?
                SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: PieChart(
                          PieChartData(
                            sections: _getExpensePieSections(),
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildChartLegend(expenseBreakdown),
                      ),
                    ],
                  ),
                ) :
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No expense data to display'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Action buttons
        ElevatedButton.icon(
          onPressed: () => _tabController.animateTo(0),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: const Icon(Icons.edit),
          label: const Text(
            'EDIT DATA',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            // Here you would implement saving or exporting functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Financial report saved!')),
            );
          },
          icon: const Icon(Icons.save),
          label: const Text('SAVE REPORT'),
        ),
      ],
    );
  }

  List<PieChartSectionData> _getIncomePieSections() {
    return incomeBreakdown
        .where((item) => item.value > 0)
        .map((item) {
      final double percentage = (item.value / totalIncome) * 100;
      return PieChartSectionData(
        color: item.color,
        value: item.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    })
        .toList();
  }

  List<PieChartSectionData> _getExpensePieSections() {
    return expenseBreakdown
        .where((item) => item.value > 0)
        .map((item) {
      final double percentage = (item.value / totalExpenses) * 100;
      return PieChartSectionData(
        color: item.color,
        value: item.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    })
        .toList();
  }

  Widget _buildChartLegend(List<FinancialItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: items
          .where((item) => item.value > 0)
          .map(
            (item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      )
          .toList(),
    );
  }
}

// Class to represent financial items for the charts
class FinancialItem {
  final String name;
  final double value;
  final Color color;

  FinancialItem(this.name, this.value, this.color);
}