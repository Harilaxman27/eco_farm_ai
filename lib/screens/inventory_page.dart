import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'db_helper2.dart';
import 'egg_production.dart';
import 'broiler_models.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({Key? key}) : super(key: key);

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  late Future<List<EggProduction>> _eggs;
  late Future<List<Broiler>> _broilers;
  bool showEggs = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _eggs = DBHelper.getEggProductions();
    _broilers = DBHelper2().getAllBroilers();
  }

  void _refreshData() {
    setState(() => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Inventory'),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header with switch
          Container(
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                Text(
                  showEggs ? 'Egg Inventory' : 'Broiler Inventory',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Eggs',
                        style: TextStyle(
                          fontWeight: showEggs ? FontWeight.bold : FontWeight.normal,
                          color: showEggs ? Colors.green.shade700 : Colors.grey,
                        ),
                      ),
                      Switch(
                        value: !showEggs,
                        onChanged: (val) {
                          setState(() => showEggs = !val);
                        },
                        activeColor: Colors.green.shade700,
                      ),
                      Text(
                        'Broilers',
                        style: TextStyle(
                          fontWeight: !showEggs ? FontWeight.bold : FontWeight.normal,
                          color: !showEggs ? Colors.green.shade700 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Summary widgets
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: showEggs ? _buildEggSummary() : _buildBroilerSummary(),
          ),

          // List header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.format_list_bulleted, size: 20),
                const SizedBox(width: 8),
                Text(
                  showEggs ? 'Egg Batches' : 'Broiler Batches',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Main list content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _refreshData(),
              child: showEggs ? _buildEggInventory() : _buildBroilerInventory(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.refresh),
        onPressed: _refreshData,
      ),
    );
  }

  Widget _buildEggSummary() {
    return FutureBuilder<List<EggProduction>>(
      future: _eggs,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        int totalEggs = 0;
        int totalBatches = snapshot.data!.length;
        for (var egg in snapshot.data!) {
          totalEggs += egg.quantity;
        }

        return Row(
          children: [
            _buildSummaryCard(
              'Total Eggs',
              totalEggs.toString(),
              Icons.egg_outlined,
              Colors.amber,
            ),
            const SizedBox(width: 16),
            _buildSummaryCard(
              'Batches',
              totalBatches.toString(),
              Icons.inventory_2_outlined,
              Colors.blue,
            ),
          ],
        );
      },
    );
  }

  Widget _buildBroilerSummary() {
    return FutureBuilder<List<Broiler>>(
      future: _broilers,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        int totalBroilers = 0;
        int healthyBroilers = 0;
        for (var broiler in snapshot.data!) {
          totalBroilers += broiler.numberOfHens;
          if (broiler.healthStatus.toLowerCase() == 'healthy' &&
              broiler.status.toLowerCase() == 'alive') {
            healthyBroilers += broiler.numberOfHens;
          }
        }

        return Row(
          children: [
            _buildSummaryCard(
              'Total Birds',
              totalBroilers.toString(),
              Icons.pets,
              Colors.brown,
            ),
            const SizedBox(width: 16),
            _buildSummaryCard(
              'Healthy',
              healthyBroilers.toString(),
              Icons.favorite,
              Colors.green,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEggInventory() {
    return FutureBuilder<List<EggProduction>>(
      future: _eggs,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.egg_outlined, size: 60, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  "No egg batches found",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final egg = snapshot.data![index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: _getEggQualityColor(egg.quality),
                  child: const Icon(Icons.egg_outlined, color: Colors.white),
                ),
                title: Text(
                  'Batch: ${egg.batch}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quality: ${egg.quality}'),
                    Text('Quantity: ${egg.quantity} | Date: ${egg.date}'),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showEggDetails(egg),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBroilerInventory() {
    return FutureBuilder<List<Broiler>>(
      future: _broilers,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pets, size: 60, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  "No broiler batches found",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final broiler = snapshot.data![index];
            bool isAlive = broiler.status.toLowerCase() == 'alive';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: isAlive ? Colors.green.shade600 : Colors.red.shade600,
                  child: const Icon(Icons.pets, color: Colors.white),
                ),
                title: Text(
                  broiler.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Breed: ${broiler.breed}'),
                    Text('Birds: ${broiler.numberOfHens} | Weight: ${broiler.currentWeight} kg'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAlive ? Colors.green.shade100 : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        broiler.status,
                        style: TextStyle(
                          color: isAlive ? Colors.green.shade800 : Colors.red.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.medical_services,
                      color: broiler.isVaccinated ? Colors.green : Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
                onTap: () => _showBroilerDetails(broiler),
              ),
            );
          },
        );
      },
    );
  }

  Color _getEggQualityColor(String quality) {
    quality = quality.toLowerCase();
    if (quality.contains('a') || quality.contains('premium')) {
      return Colors.green.shade600;
    } else if (quality.contains('b') || quality.contains('standard')) {
      return Colors.blue.shade600;
    } else if (quality.contains('c') || quality.contains('economy')) {
      return Colors.orange.shade600;
    }
    return Colors.grey.shade600;
  }

  void _showEggDetails(EggProduction egg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Batch: ${egg.batch}'),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.black,
        ),
        contentPadding: const EdgeInsets.all(20),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Quality', egg.quality),
              _detailRow('Quantity', '${egg.quantity} eggs'),
              _detailRow('Date', egg.date),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.green.shade700)),
          ),
        ],
      ),
    );
  }

  void _showBroilerDetails(Broiler broiler) {
    bool isAlive = broiler.status.toLowerCase() == 'alive';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isAlive ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.pets,
                color: isAlive ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(broiler.name)),
          ],
        ),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.black,
        ),
        contentPadding: const EdgeInsets.all(20),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Breed', broiler.breed),
              _detailRow('Number of Birds', '${broiler.numberOfHens}'),
              const Divider(),
              _detailRow('Initial Weight', '${broiler.initialWeight} kg'),
              _detailRow('Current Weight', '${broiler.currentWeight} kg'),
              _detailRow('Feed Consumed', '${broiler.feedConsumed} kg'),
              const Divider(),
              _detailRow('Health Status', broiler.healthStatus,
                  isAlive ? Colors.green : Colors.red),
              _detailRow('Medication', broiler.medication),
              _detailRow('Vaccinated', broiler.isVaccinated ? 'Yes' : 'No',
                  broiler.isVaccinated ? Colors.green : Colors.orange),
              const Divider(),
              _detailRow('Status', broiler.status,
                  isAlive ? Colors.green : Colors.red),
              _detailRow('Date', broiler.date),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.green.shade700)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}