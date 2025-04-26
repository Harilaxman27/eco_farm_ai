import 'package:flutter/material.dart';
import 'package:eco_farm_ai/screens/broiler_models.dart';
import 'package:eco_farm_ai/screens/db_helper2.dart';

class HealthAndDiseasePage extends StatefulWidget {
  @override
  _HealthAndDiseasePageState createState() => _HealthAndDiseasePageState();
}

class _HealthAndDiseasePageState extends State<HealthAndDiseasePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Broiler> _broilers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBroilers();
  }

  void _loadBroilers() async {
    final data = await DBHelper2().getAllBroilers();
    setState(() {
      _broilers = data;
    });
  }

  void _markAsVaccinated(Broiler hen) async {
    hen.isVaccinated = true;
    await DBHelper2().updateBroiler(hen);
    _loadBroilers();
  }

  void _showHealthDialog(Broiler hen) {
    TextEditingController healthController = TextEditingController(text: hen.healthStatus);
    TextEditingController medicationController = TextEditingController(text: hen.medication);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Health Update: ${hen.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: healthController,
              decoration: InputDecoration(labelText: 'Health Status'),
            ),
            TextField(
              controller: medicationController,
              decoration: InputDecoration(labelText: 'Medication'),
            ),
          ],
        ),
        actions: [
          if (!hen.isVaccinated)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _markAsVaccinated(hen);
              },
              child: Text('Mark as Vaccinated'),
            ),
          ElevatedButton(
            onPressed: () async {
              hen.healthStatus = healthController.text;
              hen.medication = medicationController.text;
              await DBHelper2().updateBroiler(hen);
              Navigator.pop(ctx);
              _loadBroilers();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Broiler> list, {bool showTag = false}) {
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final hen = list[index];
        return Card(
          child: ListTile(
            title: Text(hen.name),
            subtitle: Text("Breed: ${hen.breed}"),
            trailing: showTag && hen.isVaccinated
                ? Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text("Vaccinated", style: TextStyle(color: Colors.white)),
            )
                : null,
            onTap: () => _showHealthDialog(hen),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vaccinated = _broilers.where((b) => b.isVaccinated).toList();
    final notVaccinated = _broilers.where((b) => !b.isVaccinated).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Health & Disease Tracking'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Vaccinated"),
            Tab(text: "Not Vaccinated"),
            Tab(text: "All Broilers"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(vaccinated, showTag: false),
          _buildList(notVaccinated, showTag: false),
          _buildList(_broilers, showTag: true),
        ],
      ),
    );
  }
}
